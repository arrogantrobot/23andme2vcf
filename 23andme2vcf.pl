#!/usr/bin/env perl

use strict;
use warnings;

use IO::File;
use POSIX qw/strftime/;

usage() unless @ARGV >= 2;

my ($ref_chr, $ref_pos, $ref_base);
my $PASS = "PASS";
my $skip_count = 0;

my $raw_path = $ARGV[0];
my $output_path = $ARGV[1];
my $version = (defined($ARGV[2])) ? int($ARGV[2]) : 3;
my $ref_path = "23andme_v".$version."_hg19_ref.txt.gz";
my $missing_ref_path = "sites_not_in_reference.txt";

my $date = strftime('%Y%m%d',localtime);

missing($raw_path) unless -s $raw_path;
missing($ref_path) unless -s $ref_path;

#open the raw data as a zip or text
my $fh = ($raw_path =~ m/zip$/) ? IO::File->new("gunzip -c $raw_path|") : IO::File->new($raw_path);

my $output_fh = IO::File->new(">$output_path");
my $missing_ref_fh = -1;

#print the header for the VCF
print $output_fh "##fileformat=VCFv4.2\n";
print $output_fh "##fileDate=$date\n";
print $output_fh "##source=23andme2vcf.pl https://github.com/arrogantrobot/23andme2vcf\n";
print $output_fh "##reference=file://$ref_path\n";
print $output_fh "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n";
print $output_fh "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tGENOTYPE\n";

# load reference into memory, thank you @MattBrauer for this chunk of code! -- issue #4
my %ref = ();
my $ref_fh = IO::File->new("gunzip -c $ref_path|");
while(<$ref_fh>) {
  chomp $_;
  my ($chr,$pos,$rsid,$ref) = split /\t/, $_;
  $ref{$chr}{$pos} = { 
    rsid => $rsid,
    ref => $ref,
  };
}
close $ref_fh;

#skip the header of the 23andme file
my $line = $fh->getline;
while($line =~ m/^#/) {
  $line = $fh->getline;
}
seek($fh, -length($line), 1);

#process 23andme data line by line
while(my $line = $fh->getline) {
  chomp $line;

  #read in a line of the 23andme data
  my ($rsid, $chr, $pos, $alleles) = split /\t/, $line;
  if (not $rsid) { 
    $rsid = ".";
  }
  chomp $alleles;
  #skip current line if the call was "--"
  if (substr($alleles,0,1) eq '-') {
    next;
  }

  #skip insertions and deletions
  my $al = substr($alleles,0,1);
  if (($al eq "D") || ($al eq "I")) { 
    next;
  }
  #change MT to M, to match reference
  if (substr($chr, 0, 2) eq 'MT') {
    $chr = "M";
  }

  #append "chr" to chromosome names to match reference
  $chr = "chr$chr";

  #get the reference base from 23andme ref 
  my $ref;
  if (exists($ref{$chr}{$pos})) {
    $ref = $ref{$chr}{$pos}{ref};
  } else {
    missing_sites($rsid,$chr,$pos);
    next;
  }

  if ($ref eq $PASS) {
    next;
  }

  #get the genotype
  my ($alt,$genotype) = getAltAndGenotype($ref, $alleles);

  #output a line of VCF data
  print $output_fh "$chr\t$pos\t$rsid\t$ref\t$alt\t.\t.\t.\tGT\t$genotype\n";
}

$fh->close;
$output_fh->close;
if ($missing_ref_fh != -1) {
  $missing_ref_fh->close;
}

skips();

#determine genotype
sub getAltAndGenotype {
  my $ref = shift;
  my $alleles = shift;
  #retrieve alleles from raw data
  my ($a, $b) = split //, $alleles;
  if ($b !~ m/[A,C,G,T,N,a,c,g,t,n]/) {
    $b = undef;
  }
  my $alt;
  my $lc_ref = lc($ref);
  my $lc_a = lc($a);

  my $genotype;

  #determine which of the alleles are alts, if any
  if ($a && not $b) {
    if ($lc_a eq $lc_ref) {
      $alt = ".";
      $genotype = "0";
    } else {
      $alt = $a;
      $genotype = "1";
    }
  } else {
    my $lc_b = lc($b);
    if ($lc_a ne $lc_b) {
      if ($lc_ref eq $lc_a) {
        $alt = $b;
        $genotype = "0/1";
      } elsif ($lc_ref eq $lc_b) {
        $alt = $a;
        $genotype = "0/1";
      } else {
        $alt = "$a,$b";
        $genotype = "1/2";
      }
    } else {
      if ($lc_a eq $lc_ref) {
        $alt = ".";
        $genotype = "0/0";
      } else {
        $alt = "$a";
        $genotype = "1/1";
      }
    }
  }
  return $alt, $genotype;
}

sub usage {
  print "usage:   ./23andme2vcf /path/to/23andme/raw_data.(zip,txt) /path/to/output/file.vcf [23andme chip version, 3|4]\n";
  exit(1);
}

sub missing {
  my $path = shift;
  print "Could not locate a file at: $path\n";
  usage();
}

sub missing_sites {
  my $rsid = shift;
  my $chr = shift;
  my $pos = shift;
  if ($missing_ref_fh == -1) {
    $missing_ref_fh = IO::File->new(">$missing_ref_path");
  }
  print $missing_ref_fh "$rsid\t$chr\t$pos\n";
  $skip_count++;
}

sub skips {
  if ($skip_count) {
    my $other_version = ($version == 3) ? 4 : 3;
    print "$skip_count sites were not included; these unmatched references can be found in $missing_ref_path." . 
    "Try running again, but specify the other reference version:\n".
    "./23andme2vcf.pl $ARGV[0] $ARGV[1] $other_version\n"
  }
}
