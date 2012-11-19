#!/usr/bin/env perl

use strict;
use warnings;

use IO::File;
use POSIX qw/strftime/;

usage() unless @ARGV == 2;

my $raw_path = $ARGV[0];
my $output_path = $ARGV[1];
my $ref_path = "23andme_hg19ref_20121017.txt.gz";

my $date = strftime('%Y%m%d',localtime);

missing($raw_path) unless -s $raw_path;
missing($ref_path) unless -s $ref_path;

#open the raw data as a zip or text
my $fh = ($raw_path =~ m/zip$/) ? IO::File->new("gunzip -c $raw_path|") : IO::File->new($raw_path);

#open the compressed reference file
my $ref_fh = IO::File->new("gunzip -c $ref_path|");

my $output_fh = IO::File->new(">$output_path");

#print the header for the VCF
print $output_fh "##fileformat=VCFv4.1\n";
print $output_fh "##fileDate=$date\n";
print $output_fh "##source=23andme_to_vcf.pl\n";
print $output_fh "##reference=file://$ref_path\n";
print $output_fh "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n";
print $output_fh "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tGENOTYPE\n";

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
	my $ref = getRef($chr,$pos);

	#get the genotype
	my ($alt,$genotype) = getAltAndGenotype($ref, $alleles);

	#output a line of VCF data
	print $output_fh "$chr\t$pos\t$rsid\t$ref\t$alt\t.\t.\t.\tGT\t$genotype\n";
}

$fh->close;
$output_fh->close;

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

#grab a line(s) from the reference file
sub getRef {
	my $my_chr = shift;
	my $my_pos = shift;
	my $get_ref_line = 1;
	my $my_ref;
	my $data_line;

	#if the reference line is less than our current position, 
	# grab lines until the current position is reached or exceded
	while($get_ref_line) {
		$data_line = $ref_fh->getline;
		chomp $data_line;
		my ($chr,$pos,$rsid,$ref) = split /\t/, $data_line;
		if (($chr eq $my_chr) && ($pos == $my_pos)) {
			$my_ref = $ref;
			$get_ref_line = 0;
		}
		if ($pos > $my_pos) {
            if ($chr eq $my_chr) {
			    die "raw data file and reference file are out of sync" unless ($chr eq "chrY");
            }
		}
	}
	return $my_ref;
}

sub usage {
	print "usage:   ./23andme2vcf /path/to/23andme/raw_data.(zip,txt) /path/to/output/file.vcf\n";
	exit(1);
}

sub missing {
	my $path = shift;
	print "Could not locate a file at: $path\n";
	usage();
}
