#!/usr/bin/perl -w
use strict;

open(FH, "< $ARGV[0]") or die("Can't read $ARGV[0]: $!|n");
my $header = <FH>;
my @header = map { s/-/_/g; $_ } split /\t/, $header;
print STDERR join("\t", map { $header[$_] . "[$_]" } (0 .. $#header)), "\n";
#my $tmp = <STDIN>;

my (%var_id, %count);
while (<FH>) {
  chomp;
  my @t = split /\t/;
  my $var_id = $t[8];
  foreach my $i ((2, 15, 17)) {
    ++$count{$header[$i] . "_" . $t[$i]}->{$var_id};
    ++$var_id{$var_id};
  }
  my ($af_dbsnp, $af_1k, $af_200) = @t[12, 13, 14];
  if ($af_dbsnp == -10 && $af_1k == -10 && $af_200 == -10) {
    ++$count{allele_frequency_novel}->{$var_id};
  } elsif ($af_dbsnp < 0.01 && $af_1k < 0.01 && $af_200 < 0.01 && ($af_dbsnp != -10 || $af_1k != -10 || $af_200 != -10)) {
    ++$count{allele_frequency_rare}->{$var_id};
  } elsif ($af_dbsnp <= 0.05 && $af_1k <= 0.05 && $af_200 <= 0.05 && ($af_dbsnp >= 0.01 || $af_1k >= 0.01 || $af_200 >= 0.01)) {
    ++$count{allele_frequency_less_common}->{$var_id};
  } elsif ($af_dbsnp > 0.05 || $af_1k > 0.05 || $af_200 > 0.05) {
    ++$count{allele_frequency_common}->{$var_id};
  }
}
close FH;

open(FH, "> tmp/genomes.dat") or die("Can't write tmp/genomes.dat: $!\n");
print FH join("\t", "unique_variants", sort keys %count), "\n";
print FH join("\t", scalar(keys %var_id), map { scalar(keys %{ $count{$_} }) } sort keys %count), "\n";
close FH;

print STDERR join("\t", "unique_variants", scalar(keys %var_id)), "\n";

foreach my $i (sort keys %count) {
  my $count = scalar(keys %{ $count{$i} } );
  print STDERR join("\t", $i, $count), "\n";
}
