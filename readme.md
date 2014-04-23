Convert your 23andme raw data into VCF format
=============

This tool has been built in order to allow a user of 23andme to process the raw file format into a format more widely useful across bioinformatics tools, the VCF (see [format details](http://www.1000genomes.org/wiki/Analysis/Variant%20Call%20Format/vcf-variant-call-format-version-41 "VCF format description")).

Two references are included which are limited to only those sites targetted by the 23andme microarray. 23andme recently made the change from build36 (hg18) to build37 (hg19), so any raw files downloaded before August 9, 2012 will be based on the older build36 coordinates. Simply download the raw data again and it will be on the build37 coordinates. If there is a need for build36 support, let me know and I can add that in as an option.

*IN/DELs* are currently unsupported by this program.

If your sample was processed recently, since November of 2013, you may have version 4 results. If you see a suggestion to run on version 4 after your first conversion attempt, please do so, as you will get more usable results.


Usage
=======

git clone git://github.com/arrogantrobot/23andme2vcf.git

cd 23andme2vcf

perl 23andme2vcf.pl /path/to/23andme_raw.(zip,txt) /path/to/output.vcf

This tool will work equally well with the compressed raw file (.zip format) or the uncompressed, text file.

Reference
=========

The reference contained here-in is a list of reference bases taken from [NCBI build37] (http://hgdownload.cse.ucsc.edu/goldenPath/hg19/chromosomes/ "NCBI build37"), which matches those sites included in the 23andme microarray exactly, in order to limit the file size and speed up creation of the VCF.
