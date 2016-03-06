#!/usr/bin/env python

import sys
import getopt
import gzip

from memoized import memoize

RSID = 0
CHROM = 1
POS = 2
CALLS = 3

QUAL = "."
FILTER = "."
INFO = "."
FORMAT = "GT"

def usage(problem):
    print(problem)
    print("\n23andme2vcf.py usage:")
    print("./23andme2vcf.py /path/to/unzipped/raw_data.txt /path/to/my/output.vcf\n")
    sys.exit()

def get_reference(ref_ver):
    reference_path = "23andme_v{0}_hg19_ref.txt.gz".format(ref_ver)
    try:
        with gzip.open(reference_path, 'rb') as f:
            ref_data = f.readlines()
    except IOError as e:
        print("Error opening reference file")
        print("I/O error({0}): {1}".format(e.errno, e.strerror))
        sys.exit()
    ref = {}

    for line in ref_data:
        data = line.strip().split()
        ref[data[2]] = data[3]

    return ref

def dump_missed_calls(missed_calls):
    if len(missed_calls) > 10000:
        print("There were more than 10,000 calls in the input data that could not be converted to VCF rows")
        print("Try running 23andme2vcf with the v3 option:")
        print("     ./23andme2vcf.py /path/to/input.txt /path/to/output.vcf --v3")
        ""
    try:
        f = open("missed_calls.txt", 'w')
    except IOError as e:
        print("Error opening missed_calls.txt for output")
        print("I/O error({0}): {1}".format(e.errno, e.strerror))
        sys.exit()
    for call in missed_calls:
        f.write(call)

def get_input(path):
    try:
        f = open(path, 'r')
    except IOError as e:
        print("Error opening raw data file")
        print("I/O error({0}): {1}".format(e.errno, e.strerror))
        sys.exit()
    return f

@memoize
def get_alt_alleles(ref, calls):
    allele_one = calls[0]
    allele_two = calls[0] if len(calls)==1 else calls[1]
    hom = allele_one == allele_two
    if hom:
        if ref.upper() == allele_one.upper():
            return "0/0"
        else :
            return "1/1"
    else:
        if ref in calls:
            return "0/1"
        else:
            return "1/2"
    
def convert_raw_data(input_path, output_path, ref_ver):
    refs = get_reference(ref_ver)
    raw_calls = get_input(input_path)
    vcf_rows = []
    missed_calls = []

    for line in raw_calls.readlines():
        if "#" in line:
            continue
        (rsid, chrom, pos, calls) = line.strip().split()
        ref = ""
        if rsid in refs:
            ref = refs[rsid]
        else:
            missed_calls.append(line.strip())
            continue
        alts = get_alt_alleles(ref,calls)
        vcf_rows.append("\t".join([chrom, pos, rsid, ref, alts, QUAL, FILTER, INFO, FORMAT, "genotype"]))

    raw_calls.close()
    dump_missed_calls(missed_calls)

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "v")
    except getopt.GetoptError as err:
        print str(err)
        usage()
        sys.exit(2)
    ref_ver = "4"
    for o, a in opts:
        if o == "-v":
            ref_ver = "3"
    convert_raw_data(args[0], args[1], ref_ver)

if __name__ == "__main__":
    main()
