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

### MySQL tables
# dbSNP132, pop = CEU + Europe + CAU, 
	# [dbSNP132_hg18_2010_11_06] (0-based)
	# [dbSNP132_hg19_2010_11_06]
 	# [dbSNP132_rs_fasta_header]
	# [AlleleFreqBySsPop_europe_ceu_cau_allele_info_samplesize], sample_size_GtyFreqBySsPop_1N >= 15 or sample_size_SubPop_2N >= 30, 
# 1000 genomes, EUR
	# [seq.1000_genomes_SNP_20100804_EUR_AF_hg18] (1-based)
	# [seq.1000_genomes_EUR_dindel_20100804_sites_hg18_info_for_CGI]
# 200 exomes, EUR
	# [seq.LuCAMP_200exomeFinal_maf_hg18] (1-based)

open input, "<$ARGV[0]"; #input GVF file
open output, ">$ARGV[1]"; #output GVF file

$pragmas = 0;
$row_count = 0;

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
					print output "##allele-frequency AF_dbSNP132_EUR=allele frequency based on european populations from dbSNP132;AF_1000G_EUR=allele frequency based on european populations from 1000 Genomes;AF_200E_EUR=allele frequency based on european populations from 200 exomes;\n";
					$pragmas = 1;
				}
				
				$chromosome = $1;
				$source = $2;
				$varType = $3;
				$begin = $4;
				$end = $5;
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
				$variant_call = $attribute_detail{Variant_seq};
				
				#$locus = $1;
				#$ploidy = $2;
				#$CGI_allele = $3;
				#$chromosome = $4;
				#$begin = $5;
				#$end = $6;
				#$varType = $7;
				#$reference = $8;
				#$variant_call = $9;
				#$totalScore = $10;
				#$hapLink = $11;
				#$xRef = $12;
		
				if ($varType eq 'snp' || $varType eq 'ins' || $varType eq 'del' || $varType eq 'sub')
				{
					
		
				
					#check for dbSNP132
					$dbSNP132_detail = '';
					$dbSNP132_allele_freq = -10;
					$dbSNP132_detail_hapmapCEU = '';
					$dbSNP132_allele_freq_hapmapCEU = -10;
					
					if ($varType eq 'snp') ### SNP
					{
						#use the allele freq from snp_id(s) with the largest sample size (based on the corresponding subsnp_id)
						$largest_sample_size = 0; 
						$largest_sample_size_hapmapCEU = 0;
						
						# 1. check if chr= chr AND CGI begin = dbSNP start, if match, get the snp_id
						my $dbSNP_sth_snp_1 = $dbh->prepare("select snp_id from dbSNP132_hg18_2010_11_06 where chr = '$chromosome' AND start = ($begin - 1)");
						$dbSNP_sth_snp_1->execute( );
						while ( ($SNP_snp_ID) = $dbSNP_sth_snp_1->fetchrow_array( ) )
						{
							
							$CGI_allele_match = 0;
							$has_allele_freq = 0;
							$has_allele_freq_hapmapCEU = 0;
							$dbSNP_allele_orien;
							
							
							if ($SNP_snp_ID =~ m/(\d+)/)
							{
								$dbSNP132_rsID = $1;
								
								# 2. check snp orientation (orien: 0 = '+', 1 = '-'), if orien = 1 ('-' strand), use the rev_allele
			  				my $dbSNP_sth_snp_2 = $dbh->prepare("select orien from dbSNP132_hg19_2010_11_06 where snp_id = $dbSNP132_rsID");
								$dbSNP_sth_snp_2->execute( );
								while ( ($allele_orien) = $dbSNP_sth_snp_2->fetchrow_array( ) )
								{
									$dbSNP_allele_orien = $allele_orien;
									
									if ($allele_orien == 1)
									{
										### ref
										$CGI_ref_allele = $reference;
										#convert A,T,G,C to 1,2,3,4
										$CGI_ref_allele =~ s/A/1/g;
										$CGI_ref_allele =~ s/T/2/g;
										$CGI_ref_allele =~ s/G/3/g;
										$CGI_ref_allele =~ s/C/4/g;
										#convert 1,2,3,4 to T,A,C,G
										$CGI_ref_allele =~ s/1/T/g;
										$CGI_ref_allele =~ s/2/A/g;
										$CGI_ref_allele =~ s/3/C/g;
										$CGI_ref_allele =~ s/4/G/g;
										#reverse allele
										$final_CGI_ref_allele = reverse $CGI_ref_allele;
											
										### variant
										$CGI_var_allele = $variant_call;
										#convert A,T,G,C to 1,2,3,4
										$CGI_var_allele =~ s/A/1/g;
										$CGI_var_allele =~ s/T/2/g;
										$CGI_var_allele =~ s/G/3/g;
										$CGI_var_allele =~ s/C/4/g;
										#convert 1,2,3,4 to T,A,C,G
										$CGI_var_allele =~ s/1/T/g;
										$CGI_var_allele =~ s/2/A/g;
										$CGI_var_allele =~ s/3/C/g;
										$CGI_var_allele =~ s/4/G/g;
										#reverse allele
										$final_CGI_var_allele = reverse $CGI_var_allele;
											
									}
									elsif ($allele_orien == 0)
									{
										$final_CGI_ref_allele = $reference;
										$final_CGI_var_allele = $variant_call;
									}
								}
								
								# 3. check if the CGI allele matches with the fasta header
								my $dbSNP_sth_snp_3 = $dbh->prepare("select allele from dbSNP132_rs_fasta_header where snp_id = $dbSNP132_rsID");
								$dbSNP_sth_snp_3->execute( );
								while ( ($rs_header_allele) = $dbSNP_sth_snp_3->fetchrow_array( ) )
								{
									if ($rs_header_allele eq $final_CGI_ref_allele)
									{
										$CGI_allele_match = $CGI_allele_match + 1;
									}
									elsif ($rs_header_allele eq $final_CGI_var_allele)
									{
										$CGI_allele_match = $CGI_allele_match + 1;
									}
								}
								
								if ($CGI_allele_match == 2)
								{
									# 4. get allele freq: check if variant_call match with any of the allele in dbSNP132_SNPAlleleFreq_allele, where snp_id = snp_id, and allele = variant_call
									my $dbSNP_sth_snp_4 = $dbh->prepare("select subsnp_id, pop_id, freq, allele, sample_size_GtyFreqBySsPop_1N, sample_size_SubPop_2N from AlleleFreqBySsPop_europe_ceu_cau_allele_info_samplesize where snp_id = $dbSNP132_rsID AND allele = '$final_CGI_var_allele' AND (sample_size_GtyFreqBySsPop_1N >= 15 OR sample_size_SubPop_2N >= 30)");
									$dbSNP_sth_snp_4->execute( );
									while ( ($subsnp_id, $pop_id, $freq, $allele, $sample_size_GtyFreqBySsPop_1N, $sample_size_SubPop_2N) = $dbSNP_sth_snp_4->fetchrow_array( ) )
									{
										$sample_size = max($sample_size_GtyFreqBySsPop_1N*2, $sample_size_SubPop_2N);
										
										if ($sample_size > $largest_sample_size)
										{
											$has_allele_freq = 1;
											# 5. report snp_id, and allele frequency
											$dbSNP132_detail = $dbSNP132_detail."$dbSNP132_rsID|$subsnp_id|$pop_id|$sample_size|$freq|$dbSNP_allele_orien, ";
												
											#assign the final allele freq to the one with largest sample size there are more than one dbSNP ID
											$dbSNP132_allele_freq = $freq;
											
											$largest_sample_size = $sample_size;
																	
										}
										
										#get AF from HapMap-CEU
										if ($pop_id == 1409)
										{
											if ($sample_size > $largest_sample_size_hapmapCEU)
											{
												$has_allele_freq_hapmapCEU = 1;
												# 5. report snp_id, and allele frequency
												$dbSNP132_detail_hapmapCEU = $dbSNP132_detail_hapmapCEU."$dbSNP132_rsID|$subsnp_id|$pop_id|$sample_size|$freq|$dbSNP_allele_orien, ";
													
												#assign the final allele freq to the one with largest sample size there are more than one dbSNP ID
												$dbSNP132_allele_freq_hapmapCEU = $freq;
												
												$largest_sample_size_hapmapCEU = $sample_size;
																	
											}
																	
										}
										
										
									}
									
									if ($has_allele_freq == 0)
									{
										$dbSNP132_detail = $dbSNP132_detail."$dbSNP132_rsID|-|-|-|-1|$dbSNP_allele_orien, ";
										$dbSNP132_allele_freq = max($dbSNP132_allele_freq, -1);
									}
									
									if ($has_allele_freq_hapmapCEU == 0)
									{
										$dbSNP132_detail_hapmapCEU = $dbSNP132_detail_hapmapCEU."$dbSNP132_rsID|-|-|-|-1|$dbSNP_allele_orien, ";
										$dbSNP132_allele_freq_hapmapCEU = max($dbSNP132_allele_freq_hapmapCEU, -1);
									}
									
								}
								
							}
						}
					}
					elsif ($varType eq 'ins')	### insertion
					{
						#use the allele freq from snp_id(s) with the largest sample size (based on the corresponding subsnp_id)
						$largest_sample_size = 0; 
						$largest_sample_size_hapmapCEU = 0;
						
						# 1. check if chr=chr, and CGI begin = dbSNP end, get the snp_id
						my $dbSNP_sth_ins_1 = $dbh->prepare("select snp_id from dbSNP132_hg18_2010_11_06 where chr = '$chromosome' AND end = $begin");
						$dbSNP_sth_ins_1->execute( );
						while ( ($INS_snp_ID) = $dbSNP_sth_ins_1->fetchrow_array( ) )
						{
							$CGI_allele_match = 0;
							$has_allele_freq = 0;
							$has_allele_freq_hapmapCEU = 0;
							$dbSNP_allele_orien;
							
							if ($INS_snp_ID =~ m/(\d+)/)
							{
								$dbSNP132_rsID = $1;
								
								# 2. check orientation (orien: 0 = '+', 1 = '-'), if orien = 1 ('-' strand), use the rev_allele
			  				my $dbSNP_sth_ins_2 = $dbh->prepare("select orien from dbSNP132_hg19_2010_11_06 where snp_id = $dbSNP132_rsID");
								$dbSNP_sth_ins_2->execute( );
								while ( ($allele_orien) = $dbSNP_sth_ins_2->fetchrow_array( ) )
								{
									$dbSNP_allele_orien = $allele_orien;
									
									if ($allele_orien == 1)
									{
										### ref
										$final_CGI_ref_allele = '-';
										
										### variant
										$CGI_var_allele = $variant_call;
										#convert A,T,G,C to 1,2,3,4
										$CGI_var_allele =~ s/A/1/g;
										$CGI_var_allele =~ s/T/2/g;
										$CGI_var_allele =~ s/G/3/g;
										$CGI_var_allele =~ s/C/4/g;
										#convert 1,2,3,4 to T,A,C,G
										$CGI_var_allele =~ s/1/T/g;
										$CGI_var_allele =~ s/2/A/g;
										$CGI_var_allele =~ s/3/C/g;
										$CGI_var_allele =~ s/4/G/g;
										#reverse allele
										$final_CGI_var_allele = reverse $CGI_var_allele;
											
									}
									elsif ($allele_orien == 0)
									{
										$final_CGI_ref_allele = '-';
										$final_CGI_var_allele = $variant_call;
									}
								}
								
								# 3. check if the CGI allele matches with the fasta header
								my $dbSNP_sth_ins_3 = $dbh->prepare("select allele from dbSNP132_rs_fasta_header where snp_id = $dbSNP132_rsID");
								$dbSNP_sth_ins_3->execute( );
								while ( ($rs_header_allele) = $dbSNP_sth_ins_3->fetchrow_array( ) )
								{
									if ($rs_header_allele eq $final_CGI_ref_allele)
									{
										$CGI_allele_match = $CGI_allele_match + 1;
									}
									elsif ($rs_header_allele eq $final_CGI_var_allele)
									{
										$CGI_allele_match = $CGI_allele_match + 1;
									}
								}
								
								if ($CGI_allele_match == 2)
								{
									# 4. get allele freq: check if variant_call match with any of the allele in dbSNP132_SNPAlleleFreq_allele, where snp_id = snp_id, and allele = variant_call
									my $dbSNP_sth_ins_4 = $dbh->prepare("select subsnp_id, pop_id, freq, allele, sample_size_GtyFreqBySsPop_1N, sample_size_SubPop_2N from AlleleFreqBySsPop_europe_ceu_cau_allele_info_samplesize where snp_id = $dbSNP132_rsID AND allele = '$final_CGI_var_allele' AND (sample_size_GtyFreqBySsPop_1N >= 15 OR sample_size_SubPop_2N >= 30)");
									$dbSNP_sth_ins_4->execute( );
									while ( ($subsnp_id, $pop_id, $freq, $allele, $sample_size_GtyFreqBySsPop_1N, $sample_size_SubPop_2N) = $dbSNP_sth_ins_4->fetchrow_array( ) )
									{
										$sample_size = max($sample_size_GtyFreqBySsPop_1N*2, $sample_size_SubPop_2N);
										
										if ($sample_size > $largest_sample_size)
										{
											$has_allele_freq = 1;
											# 5. report snp_id, and allele frequency
											$dbSNP132_detail = $dbSNP132_detail."$dbSNP132_rsID|$subsnp_id|$pop_id|$sample_size|$freq|$dbSNP_allele_orien, ";
												
											#assign the final allele freq to the one with largest sample size there are more than one dbSNP ID
											$dbSNP132_allele_freq = $freq;
											
											$largest_sample_size = $sample_size;
																	
										}
										
										#get AF from HapMap-CEU
										if ($pop_id == 1409)
										{
											if ($sample_size > $largest_sample_size_hapmapCEU)
											{
												$has_allele_freq_hapmapCEU = 1;
												# 5. report snp_id, and allele frequency
												$dbSNP132_detail_hapmapCEU = $dbSNP132_detail_hapmapCEU."$dbSNP132_rsID|$subsnp_id|$pop_id|$sample_size|$freq|$dbSNP_allele_orien, ";
													
												#assign the final allele freq to the one with largest sample size there are more than one dbSNP ID
												$dbSNP132_allele_freq_hapmapCEU = $freq;
												
												$largest_sample_size_hapmapCEU = $sample_size;
																	
											}
																	
										}
									}
									
									if ($has_allele_freq == 0)
									{
										$dbSNP132_detail = $dbSNP132_detail."$dbSNP132_rsID|-|-|-|-1|$dbSNP_allele_orien, ";
										$dbSNP132_allele_freq = max($dbSNP132_allele_freq, -1);
									}
									
									if ($has_allele_freq_hapmapCEU == 0)
									{
										$dbSNP132_detail_hapmapCEU = $dbSNP132_detail_hapmapCEU."$dbSNP132_rsID|-|-|-|-1|$dbSNP_allele_orien, ";
										$dbSNP132_allele_freq_hapmapCEU = max($dbSNP132_allele_freq_hapmapCEU, -1);
									}
									
								}
							}
						}
					}
					elsif ($varType eq 'del')	### deletion
					{
						#use the allele freq from snp_id(s) with the largest sample size (based on the corresponding subsnp_id)
						$largest_sample_size = 0; 
						$largest_sample_size_hapmapCEU = 0;
						
						# 1. check if chr= chr AND CGI begin = dbSNP start, if match, get the snp_id
						my $dbSNP_sth_del_1 = $dbh->prepare("select snp_id from dbSNP132_hg18_2010_11_06 where chr = '$chromosome' AND start = ($begin - 1)");
						$dbSNP_sth_del_1->execute( );
						while ( ($DEL_snp_ID) = $dbSNP_sth_del_1->fetchrow_array( ) )
						{
							$CGI_allele_match = 0;
							$has_allele_freq = 0;
							$has_allele_freq_hapmapCEU = 0;
							$dbSNP_allele_orien;
							
							if ($DEL_snp_ID =~ m/(\d+)/)
							{
								$dbSNP132_rsID = $1;
								# 2. check snp orientation (orien: 0 = '+', 1 = '-'), if orien = 1 ('-' strand), use the rev_allele
			  				my $dbSNP_sth_del_2 = $dbh->prepare("select orien from dbSNP132_hg19_2010_11_06 where snp_id = $dbSNP132_rsID");
								$dbSNP_sth_del_2->execute( );
								while ( ($allele_orien) = $dbSNP_sth_del_2->fetchrow_array( ) )
								{
									$dbSNP_allele_orien = $allele_orien;
									
									if ($allele_orien == 1)
									{
										### ref
										$CGI_ref_allele = $reference;
										#convert A,T,G,C to 1,2,3,4
										$CGI_ref_allele =~ s/A/1/g;
										$CGI_ref_allele =~ s/T/2/g;
										$CGI_ref_allele =~ s/G/3/g;
										$CGI_ref_allele =~ s/C/4/g;
										#convert 1,2,3,4 to T,A,C,G
										$CGI_ref_allele =~ s/1/T/g;
										$CGI_ref_allele =~ s/2/A/g;
										$CGI_ref_allele =~ s/3/C/g;
										$CGI_ref_allele =~ s/4/G/g;
										#reverse allele
										$final_CGI_ref_allele = reverse $CGI_ref_allele;
											
										### variant
										$final_CGI_var_allele = '-';
											
									}
									elsif ($allele_orien == 0)
									{
										$final_CGI_ref_allele = $reference;
										$final_CGI_var_allele = '-';
									}
								}
								
								# 3. check if the ref allele matches with the fasta header
								my $dbSNP_sth_del_3 = $dbh->prepare("select allele from dbSNP132_rs_fasta_header where snp_id = $dbSNP132_rsID");
								$dbSNP_sth_del_3->execute( );
								while ( ($rs_header_allele) = $dbSNP_sth_del_3->fetchrow_array( ) )
								{
									if ($rs_header_allele eq $final_CGI_ref_allele)
									{
										$CGI_allele_match = $CGI_allele_match + 1;
									}
									elsif ($rs_header_allele eq $final_CGI_var_allele)
									{
										$CGI_allele_match = $CGI_allele_match + 1;
									}
								}
								
								if ($CGI_allele_match == 2)
								{
									# 4. check if snp_id = snp_id, and allele = '-' from dbSNP132_SNPAlleleFreq_allele
									my $dbSNP_sth_del_4 = $dbh->prepare("select subsnp_id, pop_id, freq, allele, sample_size_GtyFreqBySsPop_1N, sample_size_SubPop_2N from AlleleFreqBySsPop_europe_ceu_cau_allele_info_samplesize where snp_id = $dbSNP132_rsID AND allele = '$final_CGI_var_allele' AND (sample_size_GtyFreqBySsPop_1N >= 15 OR sample_size_SubPop_2N >= 30)");
									$dbSNP_sth_del_4->execute( );
									while ( ($subsnp_id, $pop_id, $freq, $allele, $sample_size_GtyFreqBySsPop_1N, $sample_size_SubPop_2N) = $dbSNP_sth_del_4->fetchrow_array( ) )
									{
										$sample_size = max($sample_size_GtyFreqBySsPop_1N*2, $sample_size_SubPop_2N);
										
										if ($sample_size > $largest_sample_size)
										{
											$has_allele_freq = 1;
											# 5. report snp_id, and allele frequency
											$dbSNP132_detail = $dbSNP132_detail."$dbSNP132_rsID|$subsnp_id|$pop_id|$sample_size|$freq|$dbSNP_allele_orien, ";
												
											#assign the final allele freq to the one with largest sample size there are more than one dbSNP ID
											$dbSNP132_allele_freq = $freq;
											
											$largest_sample_size = $sample_size;
																	
										}
										
										#get AF from HapMap-CEU
										if ($pop_id == 1409)
										{
											if ($sample_size > $largest_sample_size_hapmapCEU)
											{
												$has_allele_freq_hapmapCEU = 1;
												# 5. report snp_id, and allele frequency
												$dbSNP132_detail_hapmapCEU = $dbSNP132_detail_hapmapCEU."$dbSNP132_rsID|$subsnp_id|$pop_id|$sample_size|$freq|$dbSNP_allele_orien, ";
													
												#assign the final allele freq to the one with largest sample size there are more than one dbSNP ID
												$dbSNP132_allele_freq_hapmapCEU = $freq;
												
												$largest_sample_size_hapmapCEU = $sample_size;
																	
											}
																	
										}
										
									}
									
									if ($has_allele_freq == 0)
									{
										$dbSNP132_detail = $dbSNP132_detail."$dbSNP132_rsID|-|-|-|-1|$dbSNP_allele_orien, ";
										$dbSNP132_allele_freq = max($dbSNP132_allele_freq, -1);
									}
									
									if ($has_allele_freq_hapmapCEU == 0)
									{
										$dbSNP132_detail_hapmapCEU = $dbSNP132_detail_hapmapCEU."$dbSNP132_rsID|-|-|-|-1|$dbSNP_allele_orien, ";
										$dbSNP132_allele_freq_hapmapCEU = max($dbSNP132_allele_freq_hapmapCEU, -1);
									}
									
								}
							}
						}
					}
					elsif ($varType eq 'sub') ### substitution
					{
						
						$simple_event = 0;
						
						#use the allele freq from snp_id(s) with the largest sample size (based on the corresponding subsnp_id)
						$largest_sample_size = 0; 
						$largest_sample_size_hapmapCEU = 0;
						
						### check for single event, need to match obth ref and variant alleles to dbSNP
							# 1. check if chr= chr AND CGI begin = dbSNP start, if match, get the snp_id
							my $dbSNP_sth_sub_1 = $dbh->prepare("select snp_id from dbSNP132_hg18_2010_11_06 where chr = '$chromosome' AND start = ($begin - 1)");
							$dbSNP_sth_sub_1->execute( );
							while ( ($SUB_snp_ID) = $dbSNP_sth_sub_1->fetchrow_array( ) )
							{
								$CGI_allele_match = 0;
								$has_allele_freq = 0;
								$has_allele_freq_hapmapCEU = 0;
								$dbSNP_allele_orien;
							
								if ($SUB_snp_ID =~ m/(\d+)/)
								{
									$dbSNP132_rsID = $1;
									
									# 2. check snp orientation (orien: 0 = '+', 1 = '-'), if orien = 1 ('-' strand), use the rev_allele
				  				my $dbSNP_sth_sub_2 = $dbh->prepare("select orien from dbSNP132_hg19_2010_11_06 where snp_id = $dbSNP132_rsID");
									$dbSNP_sth_sub_2->execute( );
									while ( ($allele_orien) = $dbSNP_sth_sub_2->fetchrow_array( ) )
									{
										$dbSNP_allele_orien = $allele_orien;
										
										if ($allele_orien == 1)
										{
											### ref
											$CGI_ref_allele = $reference;
											#convert A,T,G,C to 1,2,3,4
											$CGI_ref_allele =~ s/A/1/g;
											$CGI_ref_allele =~ s/T/2/g;
											$CGI_ref_allele =~ s/G/3/g;
											$CGI_ref_allele =~ s/C/4/g;
											#convert 1,2,3,4 to T,A,C,G
											$CGI_ref_allele =~ s/1/T/g;
											$CGI_ref_allele =~ s/2/A/g;
											$CGI_ref_allele =~ s/3/C/g;
											$CGI_ref_allele =~ s/4/G/g;
											#reverse allele
											$final_CGI_ref_allele = reverse $CGI_ref_allele;
											
											### variant
											$CGI_var_allele = $variant_call;
											#convert A,T,G,C to 1,2,3,4
											$CGI_var_allele =~ s/A/1/g;
											$CGI_var_allele =~ s/T/2/g;
											$CGI_var_allele =~ s/G/3/g;
											$CGI_var_allele =~ s/C/4/g;
											#convert 1,2,3,4 to T,A,C,G
											$CGI_var_allele =~ s/1/T/g;
											$CGI_var_allele =~ s/2/A/g;
											$CGI_var_allele =~ s/3/C/g;
											$CGI_var_allele =~ s/4/G/g;
											#reverse allele
											$final_CGI_var_allele = reverse $CGI_var_allele;
											
										}
										elsif ($allele_orien == 0)
										{
											$final_CGI_ref_allele = $reference;
											$final_CGI_var_allele = $variant_call;
										}
									}
									
									# 3. check if the CGI allele matches with the fasta header
									my $dbSNP_sth_sub_3 = $dbh->prepare("select allele from dbSNP132_rs_fasta_header where snp_id = $dbSNP132_rsID");
									$dbSNP_sth_sub_3->execute( );
									while ( ($rs_header_allele) = $dbSNP_sth_sub_3->fetchrow_array( ) )
									{
										if ($rs_header_allele eq $final_CGI_ref_allele)
										{
											$CGI_allele_match = $CGI_allele_match + 1;
										}
										elsif ($rs_header_allele eq $final_CGI_var_allele)
										{
											$CGI_allele_match = $CGI_allele_match + 1;
										}
										
									}
									
									if ($CGI_allele_match == 2)
									{
										$simple_event = 1;
										
										# 4. get allele freq: check if variant_call match with any of the allele in dbSNP132_SNPAlleleFreq_allele, where snp_id = snp_id, and allele = variant_call
										my $dbSNP_sth_sub_4 = $dbh->prepare("select subsnp_id, pop_id, freq, allele, sample_size_GtyFreqBySsPop_1N, sample_size_SubPop_2N from AlleleFreqBySsPop_europe_ceu_cau_allele_info_samplesize where snp_id = $dbSNP132_rsID AND allele = '$final_CGI_var_allele' AND (sample_size_GtyFreqBySsPop_1N >= 15 OR sample_size_SubPop_2N >= 30)");
										$dbSNP_sth_sub_4->execute( );
										while ( ($subsnp_id, $pop_id, $freq, $allele, $sample_size_GtyFreqBySsPop_1N, $sample_size_SubPop_2N) = $dbSNP_sth_sub_4->fetchrow_array( ) )
										{
											$sample_size = max($sample_size_GtyFreqBySsPop_1N*2, $sample_size_SubPop_2N);
											
											if ($sample_size > $largest_sample_size)
											{
												$has_allele_freq = 1;
												# 5. report snp_id, and allele frequency
												$dbSNP132_detail = $dbSNP132_detail."$dbSNP132_rsID|$subsnp_id|$pop_id|$sample_size|$freq|$dbSNP_allele_orien, ";
													
												#assign the final allele freq to the one with largest sample size there are more than one dbSNP ID
												$dbSNP132_allele_freq = $freq;
												
												$largest_sample_size = $sample_size;
																	
											}
										
											#get AF from HapMap-CEU
											if ($pop_id == 1409)
											{
												if ($sample_size > $largest_sample_size_hapmapCEU)
												{
													$has_allele_freq_hapmapCEU = 1;
													# 5. report snp_id, and allele frequency
													$dbSNP132_detail_hapmapCEU = $dbSNP132_detail_hapmapCEU."$dbSNP132_rsID|$subsnp_id|$pop_id|$sample_size|$freq|$dbSNP_allele_orien, ";
														
													#assign the final allele freq to the one with largest sample size there are more than one dbSNP ID
													$dbSNP132_allele_freq_hapmapCEU = $freq;
													
													$largest_sample_size_hapmapCEU = $sample_size;
																		
												}
																		
											}
											
										}
										
										if ($has_allele_freq == 0)
										{
											$dbSNP132_detail = $dbSNP132_detail."$dbSNP132_rsID|-|-|-|-1|$dbSNP_allele_orien, ";
											$dbSNP132_allele_freq = max($dbSNP132_allele_freq, -1);
										}
										
										if ($has_allele_freq_hapmapCEU == 0)
										{
											$dbSNP132_detail_hapmapCEU = $dbSNP132_detail_hapmapCEU."$dbSNP132_rsID|-|-|-|-1|$dbSNP_allele_orien, ";
											$dbSNP132_allele_freq_hapmapCEU = max($dbSNP132_allele_freq_hapmapCEU, -1);
										}
										
										
									}
									
								}
							}
							
							### check for multiple event, need to match obth ref and variant alleles to dbSNP
							if ($simple_event == 0) 
							{
								
								$n_mismatch = 0;
								
								$n_allele_freq = 0;
								$n_allele_freq_hapmapCEU = 0;
								
								$final_allele_freq = 1;
								$final_allele_freq_hapmapCEU = 1;
								
								$has_dbSNP_match = 0;
								
								$ref_allele_length = length $reference;
								$var_allele_length = length $variant_call;
								
								if ($ref_allele_length == $var_allele_length)
								{
									@ref_allele_base = split('',$reference);
									@var_allele_base = split('',$variant_call);
									
									$i = 0;
									while ($i < $ref_allele_length)
									{
										#compare each base, and check for possible SNPs
										if ($ref_allele_base[$i] ne $var_allele_base[$i])
										{
											$n_mismatch = $n_mismatch + 1;
											$temp_allele_freq = -10;
											$temp_allele_freq_hapmapCEU = -10;
			
											$has_positive_allele_freq = 0;
											$has_positive_allele_freq_hapmapCEU = 0;
											
											#use the allele freq from snp_id(s) with the largest sample size (based on the corresponding subsnp_id)
											$largest_sample_size = 0; 
											$largest_sample_size_hapmapCEU = 0;
											
											# 1. check if chr= chr AND CGI begin = dbSNP start, if match, get the snp_id
											my $dbSNP_sub_sth_snp_1 = $dbh->prepare("select snp_id from dbSNP132_hg18_2010_11_06 where chr = '$chromosome' AND start = ($begin - 1 + $i)");
											$dbSNP_sub_sth_snp_1->execute( );
											while ( ($SUB_SNP_snp_ID) = $dbSNP_sub_sth_snp_1->fetchrow_array( ) )
											{
												
												$CGI_allele_match = 0;
												$has_allele_freq = 0;
												$has_allele_freq_hapmapCEU = 0;
												$dbSNP_allele_orien;
												
												if ($SUB_SNP_snp_ID =~ m/(\d+)/)
												{
													$dbSNP132_rsID = $1;
													
													# 2. check snp orientation (orien: 0 = '+', 1 = '-'), if orien = 1 ('-' strand), use the rev_allele
								  				my $dbSNP_sub_sth_snp_2 = $dbh->prepare("select orien from dbSNP132_hg19_2010_11_06 where snp_id = $dbSNP132_rsID");
													$dbSNP_sub_sth_snp_2->execute( );
													while ( ($allele_orien) = $dbSNP_sub_sth_snp_2->fetchrow_array( ) )
													{
														$dbSNP_allele_orien = $allele_orien;
														
														if ($allele_orien == 1)
														{
															### ref
															$CGI_ref_allele = $ref_allele_base[$i];
															#convert A,T,G,C to 1,2,3,4
															$CGI_ref_allele =~ s/A/1/g;
															$CGI_ref_allele =~ s/T/2/g;
															$CGI_ref_allele =~ s/G/3/g;
															$CGI_ref_allele =~ s/C/4/g;
															#convert 1,2,3,4 to T,A,C,G
															$CGI_ref_allele =~ s/1/T/g;
															$CGI_ref_allele =~ s/2/A/g;
															$CGI_ref_allele =~ s/3/C/g;
															$CGI_ref_allele =~ s/4/G/g;
															#reverse allele
															$final_CGI_ref_allele = reverse $CGI_ref_allele;
																
															### variant
															$CGI_var_allele = $var_allele_base[$i];
															#convert A,T,G,C to 1,2,3,4
															$CGI_var_allele =~ s/A/1/g;
															$CGI_var_allele =~ s/T/2/g;
															$CGI_var_allele =~ s/G/3/g;
															$CGI_var_allele =~ s/C/4/g;
															#convert 1,2,3,4 to T,A,C,G
															$CGI_var_allele =~ s/1/T/g;
															$CGI_var_allele =~ s/2/A/g;
															$CGI_var_allele =~ s/3/C/g;
															$CGI_var_allele =~ s/4/G/g;
															#reverse allele
															$final_CGI_var_allele = reverse $CGI_var_allele;
																
														}
														elsif ($allele_orien == 0)
														{
															$final_CGI_ref_allele = $ref_allele_base[$i];
															$final_CGI_var_allele = $var_allele_base[$i];
														}
													}
													
													# 3. check if the CGI allele matches with the fasta header
													my $dbSNP_sub_sth_snp_3 = $dbh->prepare("select allele from dbSNP132_rs_fasta_header where snp_id = $dbSNP132_rsID");
													$dbSNP_sub_sth_snp_3->execute( );
													while ( ($rs_header_allele) = $dbSNP_sub_sth_snp_3->fetchrow_array( ) )
													{
														if ($rs_header_allele eq $final_CGI_ref_allele)
														{
															$CGI_allele_match = $CGI_allele_match + 1;
														}
														elsif ($rs_header_allele eq $final_CGI_var_allele)
														{
															$CGI_allele_match = $CGI_allele_match + 1;
														}
													}
													
													if ($CGI_allele_match == 2)
													{
														$has_dbSNP_match = 1;
														# 4. get allele freq: check if variant_call match with any of the allele in dbSNP132_SNPAlleleFreq_allele, where snp_id = snp_id, and allele = variant_call
														my $dbSNP_sub_sth_snp_4 = $dbh->prepare("select subsnp_id, pop_id, freq, allele, sample_size_GtyFreqBySsPop_1N, sample_size_SubPop_2N from AlleleFreqBySsPop_europe_ceu_cau_allele_info_samplesize where snp_id = $dbSNP132_rsID AND allele = '$final_CGI_var_allele' AND (sample_size_GtyFreqBySsPop_1N >= 15 OR sample_size_SubPop_2N >= 30)");
														$dbSNP_sub_sth_snp_4->execute( );
														while ( ($subsnp_id, $pop_id, $freq, $allele, $sample_size_GtyFreqBySsPop_1N, $sample_size_SubPop_2N) = $dbSNP_sub_sth_snp_4->fetchrow_array( ) )
														{
															$sample_size = max($sample_size_GtyFreqBySsPop_1N*2, $sample_size_SubPop_2N);
															
															if ($sample_size > $largest_sample_size)
															{
																$has_allele_freq = 1;
																$has_positive_allele_freq = 1;
																
																# 5. report snp_id, and allele frequency
																$dbSNP132_detail = $dbSNP132_detail."$dbSNP132_rsID|$subsnp_id|$pop_id|$sample_size|$freq|$dbSNP_allele_orien, ";
												
																#assign the final allele freq to the highest freq from multiple SNPs if there are more than one dbSNP ID
																$temp_allele_freq = $freq;
																
																$largest_sample_size = $sample_size;
																					
															}
															
															#get AF from HapMap-CEU
															if ($pop_id == 1409)
															{
																if ($sample_size > $largest_sample_size_hapmapCEU)
																{
																	$has_allele_freq_hapmapCEU = 1;
																	$has_positive_allele_freq_hapmapCEU = 1;
																	
																	# 5. report snp_id, and allele frequency
																	$dbSNP132_detail_hapmapCEU = $dbSNP132_detail_hapmapCEU."$dbSNP132_rsID|$subsnp_id|$pop_id|$sample_size|$freq|$dbSNP_allele_orien, ";
																		
																	#assign the final allele freq to the one with largest sample size there are more than one dbSNP ID
																	$temp_allele_freq_hapmapCEU = $freq;
																	
																	$largest_sample_size_hapmapCEU = $sample_size;
																						
																}
																						
															}
															
														}
														
														if ($has_allele_freq == 0)
														{
															$dbSNP132_detail = $dbSNP132_detail."$dbSNP132_rsID|-|-|-|-1|$dbSNP_allele_orien, ";
															$temp_allele_freq = max($temp_allele_freq, -1);
														}
														
														if ($has_allele_freq_hapmapCEU == 0)
														{
															$dbSNP132_detail_hapmapCEU = $dbSNP132_detail_hapmapCEU."$dbSNP132_rsID|-|-|-|-1|$dbSNP_allele_orien, ";
															$temp_allele_freq_hapmapCEU = max(temp_allele_freq_hapmapCEU, -1);
														}
														
														
													}
													
													
													
												}
											}
											
											if ($has_positive_allele_freq == 1)
											{
												$n_allele_freq = $n_allele_freq + 1;
												$final_allele_freq = $final_allele_freq * $temp_allele_freq;
											}
											
											if ($has_positive_allele_freq_hapmapCEU == 1)
											{
												$n_allele_freq_hapmapCEU = $n_allele_freq_hapmapCEU + 1;
												$final_allele_freq_hapmapCEU = $final_allele_freq_hapmapCEU * $temp_allele_freq_hapmapCEU;
											}
											
										}
										
										 
										$i = $i + 1;
									}
									
									if ($n_allele_freq == $n_mismatch)
									{
										$dbSNP132_allele_freq = $final_allele_freq;
									}
									elsif($n_allele_freq < $n_mismatch && $has_dbSNP_match == 1)
									{
										$dbSNP132_allele_freq = -1;
									}
									
									if ($n_allele_freq_hapmapCEU == $n_mismatch)
									{
										$dbSNP132_allele_freq_hapmapCEU = $final_allele_freq_hapmapCEU;
									}
									elsif($n_allele_freq_hapmapCEU < $n_mismatch && $has_dbSNP_match == 1)
									{
										$dbSNP132_allele_freq_hapmapCEU = -1;
									}
									
									
								}
							
							}
						
					}
							
					
					
					#check for 1000 genomes
					$G1000_detail_EUR = ''; 
					$G1000_allele_freq_EUR = -10;
					
					
					
					if ($varType eq 'snp') ### SNP
					{
						my $g1000_snp = $dbh->prepare("select varID, ALT_AF from 1000_genomes_SNP_20100804_EUR_AF_hg18 where chr = '$chromosome' AND start = $begin AND REF = '$reference' AND ALT = '$variant_call'");
						$g1000_snp->execute( );
						while ( ($varID, $ALT_AF) = $g1000_snp->fetchrow_array( ) )
						{
							$G1000_detail_EUR = $G1000_detail_EUR."$varID, $ALT_AF; ";
							$G1000_allele_freq_EUR = max($G1000_allele_freq_EUR, $ALT_AF);
						}
					}
					elsif ($varType eq 'ins')	### insertion
					{
						
						my $g1000_ins = $dbh->prepare("select varID, ALT_AF from 1000_genomes_EUR_dindel_20100804_sites_hg18_info_for_CGI where chr = '$chromosome' AND start = $begin AND ALT_base = '$variant_call' AND varType = 'ins'");
						$g1000_ins->execute( );
						while ( ($varID, $ALT_AF) = $g1000_ins->fetchrow_array( ) )
						{
							$G1000_detail_EUR = $G1000_detail_EUR."$varID, $ALT_AF; ";
							$G1000_allele_freq_EUR = max($G1000_allele_freq_EUR, $ALT_AF);
						}
					}
					elsif ($varType eq 'del')	### deletion
					{
						my $g1000_del = $dbh->prepare("select varID, ALT_AF from 1000_genomes_EUR_dindel_20100804_sites_hg18_info_for_CGI where chr = '$chromosome' AND start = ($begin -1) AND REF_base = '$reference' AND varType = 'del'");
						$g1000_del->execute( );
						while ( ($varID, $ALT_AF) = $g1000_del->fetchrow_array( ) )
						{
							$G1000_detail_EUR = $G1000_detail_EUR."$varID, $ALT_AF; ";
							$G1000_allele_freq_EUR = max($G1000_allele_freq_EUR, $ALT_AF);
						}
					}
				
			
			
					#check for 200 exomes
					$E200_SNP_detail = '';
					$E200_allele_freq = -10;
					
					if ($varType eq 'snp') ### SNP
					{
						# 1. check if chr= chr AND CGI begin = dbSNP start, if match, get the snp_id
						my $E200_sth_snp_1 = $dbh->prepare("select major_allele, minor_allele, major_allele_freq, minor_allele_freq from LuCAMP_200exomeFinal_maf_hg18 where chr = '$chromosome' AND start = $begin");
						$E200_sth_snp_1->execute( );
						while ( ($major_allele, $minor_allele, $major_allele_freq, $minor_allele_freq) = $E200_sth_snp_1->fetchrow_array( ) )
						{
							
							
											
							
							if ($major_allele eq $reference && $minor_allele eq $variant_call)
							{
								
								# report snp_id, and allele frequency
								$E200_SNP_detail = $E200_SNP_detail."$major_allele ($major_allele_freq), $minor_allele ($minor_allele_freq); ";
								
								#assign the final allele freq to the highest freq from multiple SNPs if there are more than one dbSNP ID
								$E200_allele_freq = max($E200_allele_freq, $minor_allele_freq);
							}
							elsif ($minor_allele eq $reference && $major_allele eq $variant_call)
							{
								# report snp_id, and allele frequency
								$E200_SNP_detail = $E200_SNP_detail."$major_allele ($major_allele_freq), $minor_allele ($minor_allele_freq); ";
								
								#assign the final allele freq to the highest freq from multiple SNPs if there are more than one dbSNP ID
								$E200_allele_freq = max($E200_allele_freq, $major_allele_freq);
							}
							
							
								
						}
					}
					
					$new_attribute = $original_attribute."AF_dbSNP132_EUR=$dbSNP132_allele_freq;AF_1000G_EUR=$G1000_allele_freq_EUR;AF_200E_EUR=$E200_allele_freq;";
					
					print output "$chromosome\t$source\t$varType\t$begin\t$end\t$score\t$strand\t$phase\t$new_attribute\n"; 
					
					#$locus\t$ploidy\t$CGI_allele\t$chromosome\t$begin\t$end\t$varType\t$reference\t$variant_call\t$totalScore\t$hapLink\t$xRef\t$dbSNP132_detail\t$dbSNP132_allele_freq\t$dbSNP132_detail_hapmapCEU\t$dbSNP132_allele_freq_hapmapCEU\t$G1000_detail_EUR\t$G1000_allele_freq_EUR\t$E200_SNP_detail\t$E200_allele_freq\n";
					
					
				}
				
				$row_count = $row_count + 1;
				#print "$row_count\n";
			}
			
				
			
		
}

close input;
close output;

			
	
	

	
		


