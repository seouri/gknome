#!/usr/bin/perl -w
use strict;

unless ($#ARGV == 1) {
  die("usage: $0 <input file> <genome_id>\n");
}

my ($input, $genome_id) = @ARGV;

open(FH, "< $input") or die("Can't read $input: $!\n");
open(RE, "> tmp/results.dat") or die("Can't write tmp/results.dat: $!\n");
my $head = <FH>;
while (<FH>) {
  print RE join("\t", $genome_id, $_);
}
close RE;
close FH;
