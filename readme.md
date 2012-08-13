Convert your 23andme raw data into VCF format
=============

This tool has been built in order to allow a user of 23andme to process the raw file format into a format more widely useful across bioinformatics tools, the VCF (see [format details](http://www.1000genomes.org/wiki/Analysis/Variant%20Call%20Format/vcf-variant-call-format-version-41 "VCF format description").

A reference is included which is limited to only those sites targetted by the 23andme microarray. 23andme recently made the change from build36 (hg18) to build37 (hg19), so any raw files downloaded before August 9, 2012 will be based on the older build36 coordinates. Simply download the raw data again and it will be on the build37 coordinates. If there is a need for build36 support, let me know and I can add that in as an option.

Usage
=======

git clone git://github.com/arrogantrobot/23andme2vcf.git

cd 23andme2vcf

perl 23andme2vcf.pl /path/to/23andme_raw.txt /path/to/output.vcf

