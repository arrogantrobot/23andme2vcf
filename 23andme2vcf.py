#!/usr/bin/env python

import sys
import getopt
import gzip
from datetime import date

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

def open_file_for_output(path):
    try:
        f = open(path, 'w')
    except IOError as e:
        print("Error opening {0} for output".format(path))
        print("I/O error({0}): {1}".format(e.errno, e.strerror))
        sys.exit()
    return f

def write_header_to_file(f, ref_ver,name):
    f.write("##fileformat=VCFv4.3\n")
    f.write("##fileDate={0}\n".format(date.today().isoformat()))
    f.write("##source=23andme2vcf.pl https://github.com/arrogantrobot/23andme2vcf\n")
    f.write("##reference=https://github.com/arrogantrobot/23andme2vcf/blob/master/23andme_v{0}_hg19_ref.txt.gz\n".format(ref_ver))
    f.write("##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n")
    f.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t{0}\n".format(name))

@memoize
def get_genotype(ref, calls):
    allele_one = calls[0]
    allele_two = calls[0] if len(calls)==1 else calls[1]
    hom = allele_one == allele_two
    if hom:
        if ref == allele_one:
            return "0/0"
        else:
            return "1/1"
    else:
        if ref in calls:
            return "0/1"
        else:
            return "1/2"

@memoize
def get_alt_alleles(ref, calls):
    allele_one = calls[0]
    allele_two = calls[0] if len(calls)==1 else calls[1]
    hom = allele_one == allele_two
    if hom:
        if ref.upper() == allele_one.upper():
            return "."
        else:
            return "{0}".format(allele_one)
    else:
        if ref.upper() == allele_one.upper():
            return "{0}".format(allele_two)
        elif ref.upper() == allele_two.upper():
            return "{0}".format(allele_one)
        else:
            return "{0},{1}".format(allele_one, allele_two)
    
def convert_raw_data(input_path, output_path, ref_ver):
    refs = get_reference(ref_ver)
    raw_calls_f = get_input(input_path)
    missed_calls = []
    
    output = open_file_for_output(output_path)
    write_header_to_file(output, ref_ver, input_path.split("/")[-1]) 

    count = 0

    for line in raw_calls_f.readlines():
        count += 1
        if "#" in line:
            continue
        (rsid, chrom, pos, calls) = line.strip().split()
        calls = calls.upper()
        if "I" in calls or "D" in calls:
            continue #indels are unsupported
        ref = ""
        if rsid in refs:
            ref = refs[rsid].upper()
        else:
            missed_calls.append(line.strip())
            continue
        genotype = get_genotype(ref, calls)
        alts = get_alt_alleles(ref, calls)
        output.write("\t".join([chrom, pos, rsid, ref, alts, QUAL, FILTER, INFO, FORMAT, genotype, "\n"]))

    output.close()
    raw_calls_f.close()

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
