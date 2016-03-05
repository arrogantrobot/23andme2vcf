#!/usr/bin/env python

import sys
import gzip

reference_path = "23andme_v4_hg19_ref.txt.gz"

def usage(problem):
    print(problem)
    print("\n23andme2vcf.py usage:")
    print("./23andme2vcf.py /path/to/unzipped/raw_data.txt /path/to/my/output.vcf\n")
    sys.exit()

def get_reference():
    try:
        with gzip.open(reference_path, 'rb') as f:
            ref_data = f.readlines()
    except IOError as e:
        print "I/O error({0}): {1}".format(e.errno, e.strerror)
        sys.exit()
    ref = {}

    for line in ref_data:
        data = line.strip().split()
        ref[data[2]] = data[3]

    return ref

def get_input(path):
    try:
        f = open(path, 'r')
    except IOError as e:
        print "I/O error({0}): {1}".format(e.errno, e.strerror)
        sys.exit()
    return f

def convert_raw_data(input_path, output_path):
    ref = get_reference()
    raw_calls = get_input(input_path)
    for line in raw_calls.readlines():
        print line.strip()
    raw_calls.close()

    for line in ref.keys():
        print(line, ref[line])
    print(input_path, output_path)
    return "nuts"

if __name__ == "__main__":
    if len(sys.argv) != 3:
        usage("wrong number of parameters")

    convert_raw_data(sys.argv[1], sys.argv[2])
