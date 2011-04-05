#!/usr/bin/perl
use DBI;
use List::Util qw[min max];

#definition of variables
$db="gknome_development";
$host="localhost";
$user="root";
$password="";  # the root password
#$password="gKnome";  # the root password

#connect to MySQL database
my $dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host;port=3306",
                           $user,
                           $password) 
                           or die "Can't connect to database: $DBI::errstr\n";

#### MySQL tables ###
#[UCSC_refGene_hg18_2011_03_07]
#[transl_table_1]
#[UCSC_refGene_hg18_2011_03_07_mRNA_seq]

###TODO
##indel
#need to check if indels spans across exon/intron boundary
#check nt and aa position
#treat each base separately?



open input, "<$ARGV[0]"; #input GVF file
open output, ">$ARGV[1]"; #output GVF file

$pragmas = 0;
#$row_count = 0;


#read human codon table into a hash (transl_table_1)
%human_codon_table = ();

my $sth_codon = $dbh->prepare("select amino_acid, codon from transl_table_1");
$sth_codon->execute( );
while ( ($human_amino_acid, $human_codon) = $sth_codon->fetchrow_array( ) )
{
	$human_codon_table{$human_codon} = $human_amino_acid;
}

#note
#coord is 1-based in the output
#write a script to get all mRNA sequences

#read each variant from var file
while ($line = readline input)
{
	
	if ($line =~ m/^(##.+)/)
	{
		print output "$1\n";
	}
	elsif ($line =~ m/^([^\t]+)\t([^\t]+)\t([^\t]+)\t(\d+)\t(\d+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t(.+)/)
	{
		#print out additional pragmas
		if ($pragmas == 0)
		{
			print output "##gene_annotation Variant_effect= gene model based on UCSC_refGene_hg18_2011_03_07, the annotation fields are: impact variant_seq_index gene_component transcript_ID gene_symbol transcript_position CDS_position protein_position reference_codon variant_codon reference_amino_acid variant_amino_acid. If a single variant has multiple effects, each effect is separated by a comma.\n";
			$pragmas = 1;
		}
				
		$chromosome = $1;
		$source = $2;
		$varType = $3;
		$var_begin = $4;
		$var_end = $5;
		$score =$6;
		$strand = $7;
		$phase = $8;
		$original_attribute = $9;
		@attribute = split(';',$9);
		%attribute_detail = ();
				
		foreach (@attribute)
		{
			if ($_ =~ m/^(.+)\=(.+)/)
			{
				$attribute_detail{$1} = $2;
			}
		}
				
		$reference = $attribute_detail{Reference_seq};
		$alleleSeq = $attribute_detail{Variant_seq};
	
	
	
		
		$variant_type = '';
		
		#initiate annotation 
		$ref_genome = 'hs_ref_NCBI36_'.$chromosome;
		
		#determine the variant type and size
		if ($reference eq '-')
		{
			$size_reference = 0;
		}
		else
		{
			$size_reference = length $reference;
		}
		
		if ($alleleSeq eq '-')
		{
			$size_alleleSeq = 0;
		}
		else
		{
			$size_alleleSeq = length $alleleSeq;
		}
		
			
		
		
		if ($reference ne $alleleSeq && $size_reference == $size_alleleSeq && $size_reference == 1)
		{
			$variant_type = 'snp';
		}
		elsif ($reference ne $alleleSeq && $size_reference > $size_alleleSeq)
		{
			$variant_type = 'del';
		}
		elsif ($reference ne $alleleSeq && $size_reference < $size_alleleSeq)
		{
			$variant_type = 'ins';
		}
		
		
		#check start and end comparison for different varType	
		$start = $var_begin;
		$end = $var_end;
		
		$mid = int(($start + $end)/2);
		$shortest_TSS_distance = 10000000000;
		%gene_hash = ();
		
		$n_variant_effect = 0;
		$variant_seq_index = 0;
		
		@gene_component = ();
		@gene_symbol = ();
		@transcript_ID = ();
		@tx_position_summary = ();
		@cds_position_summary = ();
		@amino_acid_position_summary = ();
		@ref_codon_summary = ();
		@alt_codon_summary = ();
		@ref_aa_summary = ();
		@alt_aa_summary = ();
		@impact = ();
		
		
		$variant_effect_attribute = '';
		
		
		
		@exon_start = ();
		@exon_end = ();
		@intron_start = ();
		@intron_end = ();
		$has_exon = 0;
		$has_5UTR = 0;
		$has_3UTR = 0;
		$region_length = $end - $start + 1;
		
		
		#check if this variant fall within any gene region
		my $sth_gene = $dbh->prepare("select name, chrom, strand, txStart, txEnd, cdsStart, cdsEnd, exonCount, exonStarts, exonEnds, name2 from UCSC_refGene_hg18_2011_03_07 where chrom = '$chromosome' AND ((txStart >= $start AND txStart <= $end) OR (txEnd >= $start AND txEnd <= $end) OR (txStart <= $start AND txEnd >= $end))");
		$sth_gene->execute( );
		while ( ($name, $chrom, $strand, $txStart, $txEnd, $cdsStart, $cdsEnd, $exonCount, $exonStarts, $exonEnds, $name2) = $sth_gene->fetchrow_array( ) )
		{
			#$gene_symbol = $gene_symbol.$name2.',';
			#$transcript_ID = $transcript_ID.$name.',';
			
			@mRNA_base = ();
			
			$temp_alleleSeq = $alleleSeq;
			$final_alleleSeq = '';
			
			$temp_reference = $reference;
			$final_reference = '';
			
			#reverse allele seq if strand = '-';
			if ($strand eq '-')
			{
				#convert A,T,G,C to 1,2,3,4
				$temp_reference =~ s/A/1/g;
				$temp_reference =~ s/T/2/g;
				$temp_reference =~ s/G/3/g;
				$temp_reference =~ s/C/4/g;
				#convert 1,2,3,4 to T,A,C,G
				$temp_reference =~ s/1/T/g;
				$temp_reference =~ s/2/A/g;
				$temp_reference =~ s/3/C/g;
				$temp_reference =~ s/4/G/g;
				#reverse allele
				$final_reference = reverse $temp_reference;
				
				#convert A,T,G,C to 1,2,3,4
				$temp_alleleSeq =~ s/A/1/g;
				$temp_alleleSeq =~ s/T/2/g;
				$temp_alleleSeq =~ s/G/3/g;
				$temp_alleleSeq =~ s/C/4/g;
				#convert 1,2,3,4 to T,A,C,G
				$temp_alleleSeq =~ s/1/T/g;
				$temp_alleleSeq =~ s/2/A/g;
				$temp_alleleSeq =~ s/3/C/g;
				$temp_alleleSeq =~ s/4/G/g;
				#reverse allele
				$final_alleleSeq = reverse $temp_alleleSeq;
			}
			elsif ($strand eq '+')
			{
				$final_reference = $temp_reference;
				$final_alleleSeq = $temp_alleleSeq;
			}
			
			#parse exon
			@exon_start = split(/,/, $exonStarts);
			@exon_end = split(/,/, $exonEnds);
		
			#get exon and intron position
			$i = 0;
			while ($i < $exonCount)
			{
				$exon_start[$i] = $exon_start[$i] + 1; #convert to 1-based start
				
				if ($i < $exonCount - 1)
				{
					$intron_start[$i] = $exon_end[$i] + 1;
					$intron_end[$i] = $exon_start[$i+1] + 1 - 1;
				}
				
				
				$i = $i + 1;
			}
			
			#get 5_UTR
			if ($strand eq '+' && $cdsStart > $txStart)
			{
				$has_5UTR = 1;
				$UTR5_start = $txStart + 1; 
				$UTR5_end = $cdsStart + 1 - 1;
			}
			elsif ($strand eq '-' && $cdsEnd < $txEnd)
			{
				$has_5UTR = 1;
				$UTR5_start = $cdsEnd + 1;
				$UTR5_end = $txEnd;
			}
			
			#get 3_UTR
			if ($strand eq '+' && $cdsEnd < $txEnd)
			{
				$has_3UTR = 1;
				$UTR3_start = $cdsEnd + 1; 
				$UTR3_end = $txEnd;
			}
			elsif ($strand eq '-' && $cdsStart > $txStart)
			{
				$has_3UTR = 1;
				$UTR3_start = $txStart + 1; 
				$UTR3_end = $cdsStart + 1 - 1;
			}
			
			### determine the overlapping gene component
			#exonic
			$i = 0;
			while ($i < $exonCount)
			{
				if ( ($end >= $exon_start[$i] && $end <= $exon_end[$i]) || ($start >= $exon_start[$i] && $start <= $exon_end[$i]) || ($start <= $exon_start[$i] && $end >= $exon_end[$i]) )
				{
					$n_variant_effect = $n_variant_effect + 1;
					
					$gene_symbol[$n_variant_effect] = $name2;
					$transcript_ID[$n_variant_effect] = $name;
					$gene_component[$n_variant_effect] = 'exon';
					
					#$gene_annotation = $gene_annotation.'exonic,';
					
					$has_exon = 1;
					$exon_index = $i;
					$n_exonic = $n_exonic + 1;
					
					
					if ($variant_type eq 'snp')
					{
						##############
						#check for amino acid change
						#1. calculate the codon/amino acid number, and the before and codon codes
						
						#find the start position of traslated region -> cdsStart
						
						$tx_position = 0;
						$cds_position = 0;
						$codon_position = 0;
						$amino_acid_position = 0;
						@ref_codon_array = ();
						$ref_codon = '';
						$alt_codon = '';
						$ref_aa = '';
						$alt_aa = '';
						@mRNA_base = ();
						
						#obtain relative tx_position, cds_position, codon_position, amino_acid_position 
						if ($strand eq '+')
						{
							$j = 0;
							while ($j < $i)
							{
								if ( ($cdsStart + 1) >= $exon_start[$j] && ($cdsStart + 1) <= $exon_end[$j])
								{ 
									$cds_position = $cds_position + ($exon_end[$j] - ($cdsStart + 1) + 1)
								}
								elsif ( ($cdsStart + 1) < $exon_start[$j] )
								{
									$cds_position = $cds_position + ($exon_end[$j] - $exon_start[$j] + 1)
								}
								
								$tx_position = $tx_position + ($exon_end[$j] - $exon_start[$j] + 1);
								
								$j = $j + 1;
							}
							
							$tx_position = $tx_position + ($start - $exon_start[$i] + 1);
							
							#check if the variant is in the same exon with cds
							if ( ($cdsStart + 1) >= $exon_start[$i] && ($cdsStart + 1) <= $exon_end[$i])
							{
								$cds_position = $cds_position + ($start - ($cdsStart + 1) + 1);
							}
							else
							{
								$cds_position = $cds_position + ($start - $exon_start[$i] + 1);
							}
							
							$codon_position = $cds_position % 3; #get Modulus
							
							if ($codon_position == 0)
							{
								$amino_acid_position = int($cds_position / 3);
							}
							else
							{
								$amino_acid_position = int($cds_position / 3) + 1;
							}
							
						}
						elsif ($strand eq '-')
						{
							$j = $exonCount - 1;
							while ($j > $i)
							{
								if ( $cdsEnd >= $exon_start[$j] && $cdsEnd <= $exon_end[$j])
								{ 
									$cds_position = $cds_position + ($cdsEnd - $exon_start[$j] + 1)
								}
								elsif ( $cdsEnd > $exon_end[$j] )
								{
									$cds_position = $cds_position + ($exon_end[$j] - $exon_start[$j] + 1)
									
								}
								
								$tx_position = $tx_position + ($exon_end[$j] - $exon_start[$j] + 1);
								
								$j = $j - 1;
							}
							
							$tx_position = $tx_position + ($exon_end[$i] - $start + 1);
							
							#check if the variant is in the same exon with cds
							if ( $cdsEnd >= $exon_start[$i] && $cdsEnd <= $exon_end[$i])
							{
								$cds_position = $cds_position + ($cdsEnd - $start + 1);
							}
							else
							{
								$cds_position = $cds_position + ($exon_end[$i] - $start + 1);
							}
							
							$codon_position = $cds_position % 3; #get Modulus
							
							if ($codon_position == 0)
							{
								$amino_acid_position = int($cds_position / 3);
							}
							else
							{
								$amino_acid_position = int($cds_position / 3) + 1;
							}
							
						}
						
						
						#get the mRNA sequence
						my $sth_mRNA_seq = $dbh->prepare("select seq from UCSC_refGene_hg18_2011_03_07_mRNA_seq where refseq_ID = '$name'");
						$sth_mRNA_seq->execute( );
						while ( ($mRNA_seq) = $sth_mRNA_seq->fetchrow_array( ) )
						{
							@mRNA_base = split('', $mRNA_seq);
						}
						
						#get codon position based on tx_position
						#get codon position 
						if ($codon_position == 0)
						{
							$ref_codon_array[0] = $mRNA_base[$tx_position - 3];
							$ref_codon_array[1] = $mRNA_base[$tx_position - 2];
							$ref_codon_array[2] = $mRNA_base[$tx_position - 1];
						}
						elsif ($codon_position == 1)
						{
							$ref_codon_array[0] = $mRNA_base[$tx_position - 1];
							$ref_codon_array[1] = $mRNA_base[$tx_position];
							$ref_codon_array[2] = $mRNA_base[$tx_position + 1];
						}
						elsif ($codon_position == 2)
						{
							$ref_codon_array[0] = $mRNA_base[$tx_position - 2];
							$ref_codon_array[1] = $mRNA_base[$tx_position - 1];
							$ref_codon_array[2] = $mRNA_base[$tx_position];
						}
						
						
						#report position summary 
						$tx_position_summary[$n_variant_effect] = $tx_position;
						$cds_position_summary[$n_variant_effect] = $cds_position;
						$amino_acid_position_summary[$n_variant_effect] = $amino_acid_position;
						
												
						#get REF codon
						$i = 0;
						while ($i <= 2)
						{
							$ref_codon = $ref_codon.$ref_codon_array[$i];
							$i = $i + 1;
						}
						
						
						#get ALT codon
						if ($codon_position == 0)
						{
							$alt_codon = $ref_codon_array[0].$ref_codon_array[1].$final_alleleSeq;
						}
						elsif ($codon_position == 1)
						{
							$alt_codon = $final_alleleSeq.$ref_codon_array[1].$ref_codon_array[2];
						}
						elsif ($codon_position == 2)
						{
							$alt_codon = $ref_codon_array[0].$final_alleleSeq.$ref_codon_array[2];
						}
						
						#get amino acid
						$ref_aa = $human_codon_table{$ref_codon};
						$alt_aa = $human_codon_table{$alt_codon};
						
						# amino acid summary
						$ref_codon_summary[$n_variant_effect] = $ref_codon;
						$alt_codon_summary[$n_variant_effect] = $alt_codon;
						
						$ref_aa_summary[$n_variant_effect] = $ref_aa;
						$alt_aa_summary[$n_variant_effect] = $alt_aa;
						
						
						#estimate impact
						
						if ($ref_aa ne $alt_aa && $alt_aa eq '*')
						{
							$impact[$n_variant_effect] = 'nonsense';
						}
						elsif ($ref_aa ne $alt_aa && $ref_aa eq '*')
						{
							$impact[$n_variant_effect] = 'nonstop';
						}
						elsif ($ref_aa ne $alt_aa && $ref_codon eq 'ATG' && $amino_acid_position == 1)
						{
							$impact[$n_variant_effect] = 'misstart';
						}
						elsif ($ref_aa ne $alt_aa && $ref_aa ne '*' && $alt_aa ne '*')
						{
							$impact[$n_variant_effect] = 'missense';
						}						
						elsif ($ref_aa eq $alt_aa)
						{
							$impact[$n_variant_effect] = 'synonymous';
						}
						
						
						##############
					}
					
					if ($variant_type eq 'ins')
					{
						#treat each base separately?
						
						#check if the ins span across an exon boundary
						##############
						#check for amino acid change
						#1. calculate the codon/amino acid number, and the before and codon codes
						
						#find the start position of traslated region -> cdsStart
						
						$tx_position = 0;
						$cds_position = 0;
						$codon_position = 0;
						$amino_acid_position = 0;
						@ref_codon_array = ();
						$ref_codon = '';
						$alt_codon = '';
						$ref_aa = '';
						$alt_aa = '';
						
						
						#obtain relative tx_position, cds_position, codon_position, amino_acid_position 
						if ($strand eq '+')
						{
							$j = 0;
							while ($j < $i)
							{
								if ( ($cdsStart + 1) >= $exon_start[$j] && ($cdsStart + 1) <= $exon_end[$j])
								{ 
									$cds_position = $cds_position + ($exon_end[$j] - ($cdsStart + 1) + 1)
								}
								elsif ( ($cdsStart + 1) < $exon_start[$j] )
								{
									$cds_position = $cds_position + ($exon_end[$j] - $exon_start[$j] + 1)
								}
								
								$tx_position = $tx_position + ($exon_end[$j] - $exon_start[$j] + 1);
								
								$j = $j + 1;
							}
							
							$tx_position = $tx_position + ($start - $exon_start[$i] + 1);
							
							#check if the variant is in the same exon with cds
							if ( ($cdsStart + 1) >= $exon_start[$i] && ($cdsStart + 1) <= $exon_end[$i])
							{
								$cds_position = $cds_position + ($start - ($cdsStart + 1) + 1);
							}
							else
							{
								$cds_position = $cds_position + ($start - $exon_start[$i] + 1);
							}
							
							$codon_position = $cds_position % 3; #get Modulus
							
							if ($codon_position == 0)
							{
								$amino_acid_position = int($cds_position / 3);
							}
							else
							{
								$amino_acid_position = int($cds_position / 3) + 1;
							}
							
						}
						elsif ($strand eq '-')
						{
							$j = $exonCount - 1;
							while ($j > $i)
							{
								if ( $cdsEnd >= $exon_start[$j] && $cdsEnd <= $exon_end[$j])
								{ 
									$cds_position = $cds_position + ($cdsEnd - $exon_start[$j] + 1)
								}
								elsif ( $cdsEnd > $exon_end[$j] )
								{
									$cds_position = $cds_position + ($exon_end[$j] - $exon_start[$j] + 1)
									
								}
								
								$tx_position = $tx_position + ($exon_end[$j] - $exon_start[$j] + 1);
								
								$j = $j - 1;
							}
							
							$tx_position = $tx_position + ($exon_end[$i] - $start + 1);
							
							#check if the variant is in the same exon with cds
							if ( $cdsEnd >= $exon_start[$i] && $cdsEnd <= $exon_end[$i])
							{
								$cds_position = $cds_position + ($cdsEnd - $start + 1);
							}
							else
							{
								$cds_position = $cds_position + ($exon_end[$i] - $start + 1);
							}
							
							$codon_position = $cds_position % 3; #get Modulus
							
							if ($codon_position == 0)
							{
								$amino_acid_position = int($cds_position / 3);
							}
							else
							{
								$amino_acid_position = int($cds_position / 3) + 1;
							}
							
						}
						
						#report position summary 
						$tx_position_summary[$n_variant_effect] = $tx_position;
						$cds_position_summary[$n_variant_effect] = $cds_position;
						$amino_acid_position_summary[$n_variant_effect] = $amino_acid_position;
						
						
						
						#amino acid summary
						$ref_codon_summary[$n_variant_effect] = '.';
						$alt_codon_summary[$n_variant_effect] = '.';
						$ref_aa_summary[$n_variant_effect] = '.';
						
						
						
						#get impact
						$indel_frame = ($size_alleleSeq - $size_reference) % 3; #get Modulus
						if ($indel_frame == 0)
						{
							$impact[$n_variant_effect] = 'in-frame-insertion';
							
							@indel_seq = split('', $final_alleleSeq);
							
							
							$i = 0;
							while ($i*3 < $size_alleleSeq)
							{
								
								#get amino acid
								$alt_aa = $alt_aa.$human_codon_table{$indel_seq[$i*3].$indel_seq[$i*3+1].$indel_seq[$i*3+2]};
								
								$i = $i + 1;
							}
							
							#$alt_codon_summary = $alt_codon_summary.$alt_codon.',';
							$alt_aa_summary[$n_variant_effect] = $alt_aa;
						}
						else
						{
							$impact[$n_variant_effect] = 'frameshift';
							$alt_aa_summary[$n_variant_effect] = '.';
						}
											
					}
					
					if ($variant_type eq 'del')
					{
						
						
						#check if the ins span across an exon boundary
						##############
						#check for amino acid change
						#1. calculate the codon/amino acid number, and the before and codon codes
						
						#find the start position of traslated region -> cdsStart
						
						$tx_position = 0;
						$cds_position = 0;
						$codon_position = 0;
						$amino_acid_position = 0;
						@ref_codon_array = ();
						$ref_codon = '';
						$alt_codon = '';
						$ref_aa = '';
						$alt_aa = '';
						
						
						#obtain relative tx_position, cds_position, codon_position, amino_acid_position 
						if ($strand eq '+')
						{
							$j = 0;
							while ($j < $i)
							{
								if ( ($cdsStart + 1) >= $exon_start[$j] && ($cdsStart + 1) <= $exon_end[$j])
								{ 
									$cds_position = $cds_position + ($exon_end[$j] - ($cdsStart + 1) + 1)
								}
								elsif ( ($cdsStart + 1) < $exon_start[$j] )
								{
									$cds_position = $cds_position + ($exon_end[$j] - $exon_start[$j] + 1)
								}
								
								$tx_position = $tx_position + ($exon_end[$j] - $exon_start[$j] + 1);
								
								$j = $j + 1;
							}
							
							$tx_position = $tx_position + ($start - $exon_start[$i] + 1);
							
							#check if the variant is in the same exon with cds
							if ( ($cdsStart + 1) >= $exon_start[$i] && ($cdsStart + 1) <= $exon_end[$i])
							{
								$cds_position = $cds_position + ($start - ($cdsStart + 1) + 1);
							}
							else
							{
								$cds_position = $cds_position + ($start - $exon_start[$i] + 1);
							}
							
							$codon_position = $cds_position % 3; #get Modulus
							
							if ($codon_position == 0)
							{
								$amino_acid_position = int($cds_position / 3);
							}
							else
							{
								$amino_acid_position = int($cds_position / 3) + 1;
							}
							
						}
						elsif ($strand eq '-')
						{
							$j = $exonCount - 1;
							while ($j > $i)
							{
								if ( $cdsEnd >= $exon_start[$j] && $cdsEnd <= $exon_end[$j])
								{ 
									$cds_position = $cds_position + ($cdsEnd - $exon_start[$j] + 1)
								}
								elsif ( $cdsEnd > $exon_end[$j] )
								{
									$cds_position = $cds_position + ($exon_end[$j] - $exon_start[$j] + 1)
									
								}
								
								$tx_position = $tx_position + ($exon_end[$j] - $exon_start[$j] + 1);
								
								$j = $j - 1;
							}
							
							$tx_position = $tx_position + ($exon_end[$i] - $start + 1);
							
							#check if the variant is in the same exon with cds
							if ( $cdsEnd >= $exon_start[$i] && $cdsEnd <= $exon_end[$i])
							{
								$cds_position = $cds_position + ($cdsEnd - $start + 1);
							}
							else
							{
								$cds_position = $cds_position + ($exon_end[$i] - $start + 1);
							}
							
							$codon_position = $cds_position % 3; #get Modulus
							
							if ($codon_position == 0)
							{
								$amino_acid_position = int($cds_position / 3);
							}
							else
							{
								$amino_acid_position = int($cds_position / 3) + 1;
							}
							
						}
						
						#report position summary 
						$tx_position_summary[$n_variant_effect] = $tx_position;
						$cds_position_summary[$n_variant_effect] = $cds_position;
						$amino_acid_position_summary[$n_variant_effect] = $amino_acid_position;
						
						#amino acid summary
						$ref_codon_summary[$n_variant_effect] = '.';
						$alt_codon_summary[$n_variant_effect] = '.';
						
						$alt_aa_summary[$n_variant_effect] = '.';
						
						
						#get impact
						$indel_frame = ($size_reference - $size_alleleSeq) % 3; #get Modulus
						if ($indel_frame == 0)
						{
							$impact[$n_variant_effect] = 'in-frame-deletion';
							
							@indel_seq = split('', $final_reference);
							
							
							$i = 0;
							while ($i*3 < $size_reference)
							{
								
								#get amino acid
								$ref_aa = $ref_aa.$human_codon_table{$indel_seq[$i*3].$indel_seq[$i*3+1].$indel_seq[$i*3+2]};
								
								$i = $i + 1;
							}
							
							#$ref_codon_summary = $ref_codon_summary.$ref_codon.',';
							$ref_aa_summary[$n_variant_effect] = $ref_aa;
						}
						else
						{
							$impact[$n_variant_effect] = 'frameshift';
							$ref_aa_summary[$n_variant_effect] = '.';
						}
											
					}
					
					last;
				}
				$i = $i + 1;
			}
			
			
		
			#intronic
			$i = 0;
			while ($i < ($exonCount - 1))
			{
				if ( ($end >= $intron_start[$i] && $end <= $intron_end[$i]) || ($start >= $intron_start[$i] && $start <= $intron_end[$i]) || ($start <= $intron_start[$i] && $end >= $intron_end[$i]) )
				{
					$n_variant_effect = $n_variant_effect + 1;
					$gene_symbol[$n_variant_effect] = $name2;
					$transcript_ID[$n_variant_effect] = $name;
					$gene_component[$n_variant_effect] = 'intron';
					$tx_position_summary[$n_variant_effect] = '.';
					$cds_position_summary[$n_variant_effect] = '.';
					$amino_acid_position_summary[$n_variant_effect] = '.';
					$ref_codon_summary[$n_variant_effect] = '.';
					$alt_codon_summary[$n_variant_effect] = '.';
					$ref_aa_summary[$n_variant_effect] = '.';
					$alt_aa_summary[$n_variant_effect] = '.';
					$impact[$n_variant_effect] = 'unknown';
					
					
					$n_intronic = $n_intronic + 1;
					last;
				}
				$i = $i + 1;
			}
			
			#5UTR (has to overlap with an exon)
			if ($has_5UTR == 1 && $has_exon == 1)
			{
				if( ($end >= $UTR5_start && $end <= $UTR5_end) || ($start >= $UTR5_start && $start <= $UTR5_end) || ($start <= $UTR5_start && $end >= $UTR5_end) )
				{
					$n_variant_effect = $n_variant_effect + 1;
					$gene_symbol[$n_variant_effect] = $name2;
					$transcript_ID[$n_variant_effect] = $name;
					$gene_component[$n_variant_effect] = '5UTR';
					$tx_position_summary[$n_variant_effect] = '.';
					$cds_position_summary[$n_variant_effect] = '.';
					$amino_acid_position_summary[$n_variant_effect] = '.';
					$ref_codon_summary[$n_variant_effect] = '.';
					$alt_codon_summary[$n_variant_effect] = '.';
					$ref_aa_summary[$n_variant_effect] = '.';
					$alt_aa_summary[$n_variant_effect] = '.';
					$impact[$n_variant_effect] = 'unknown';
					
					
					$n_5UTR = $n_5UTR + 1;
				}
				
			}
			
			#3UTR (has to overlap with an exon)
			if ($has_3UTR == 1 && $has_exon == 1)
			{
				if( ($end >= $UTR3_start && $end <= $UTR3_end) || ($start >= $UTR3_start && $start <= $UTR3_end) || ($start <= $UTR3_start && $end >= $UTR3_end) )
				{
					$n_variant_effect = $n_variant_effect + 1;
					$gene_symbol[$n_variant_effect] = $name2;
					$transcript_ID[$n_variant_effect] = $name;
					$gene_component[$n_variant_effect] = '3UTR';
					$tx_position_summary[$n_variant_effect] = '.';
					$cds_position_summary[$n_variant_effect] = '.';
					$amino_acid_position_summary[$n_variant_effect] = '.';
					$ref_codon_summary[$n_variant_effect] = '.';
					$alt_codon_summary[$n_variant_effect] = '.';
					$ref_aa_summary[$n_variant_effect] = '.';
					$alt_aa_summary[$n_variant_effect] = '.';
					$impact[$n_variant_effect] = 'unknown';
										
					$n_3UTR = $n_3UTR + 1;
				}
				
			}
			
			#splice site: DONOR or ACCEPTOR
			
					
		}
		
		$i = 1;
		while ($i <= $n_variant_effect)
		{
			if ($variant_effect_attribute eq '')
			{
				$variant_effect_attribute = "$impact[$i] $variant_seq_index $gene_component[$i] $transcript_ID[$i] $gene_symbol[$i] $tx_position_summary[$i] $cds_position_summary[$i] $amino_acid_position_summary[$i] $ref_codon_summary[$i] $alt_codon_summary[$i] $ref_aa_summary[$i] $alt_aa_summary[$i]";
			}
			else
			{
				$variant_effect_attribute = $variant_effect_attribute.",$impact[$i] $variant_seq_index $gene_component[$i] $transcript_ID[$i] $gene_symbol[$i] $tx_position_summary[$i] $cds_position_summary[$i] $amino_acid_position_summary[$i] $ref_codon_summary[$i] $alt_codon_summary[$i] $ref_aa_summary[$i] $alt_aa_summary[$i]";
			}
			$i = $i + 1;
		}
		
		if ($n_variant_effect == 0)
		{
			$variant_effect_attribute = 'unknown 0 intergenic . . . . . . . . .';
		}
		
		$new_attribute = $original_attribute."Variant_effect=$variant_effect_attribute";
					
		print output "$chromosome\t$source\t$varType\t$var_begin\t$var_end\t$score\t$strand\t$phase\t$new_attribute\n"; 
					
		#print "$locus\t$ploidy\t$allele\t$chromosome\t$CGI_begin\t$CGI_end\t$varType\t$reference\t$alleleSeq\t$gene_symbol\t$transcript_ID\t$gene_annotation\t$tx_position_summary\t$cds_position_summary\t$amino_acid_position_summary\t$ref_codon_summary\t$alt_codon_summary\t$ref_aa_summary\t$alt_aa_summary\t$impact\n";
		#$row_count = $row_count + 1;
		#print "$row_count\n";
		
	}
	
}
	

	

		


close output;

	
	

	
		


