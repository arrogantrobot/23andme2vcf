# Convert your 23andme raw data into VCF format

This tool has been built in order to allow a user of 23andme to process the raw file format into a format more widely useful across bioinformatics tools, the VCF (see [format details](http://www.1000genomes.org/wiki/Analysis/Variant%20Call%20Format/vcf-variant-call-format-version-41 "VCF format description")).

Two references are included which are limited to only those sites targetted by the 23andme microarray. 23andme recently made the change from build36 (hg18) to build37 (hg19), so any raw files downloaded before August 9, 2012 will be based on the older build36 coordinates. Simply download the raw data again and it will be on the build37 coordinates. If there is a need for build36 support, let me know and I can add that in as an option.

*IN/DELs* are currently unsupported by this program. If you would like to see support for indels, please suggest a location where I can find the exact alleles, so they can be correctly represented in the resulting VCF.

If your sample was processed after November of 2013, you have version 4 results. If you see a suggestion to run on version 4 after your first conversion attempt, please do so, as you will get more usable results.

## Usage

First, download your raw data from 23andme. Log in and click on your name in the upper right corner. Select the "browse raw data" option. Look just below your name, for a link called "DOWNLOAD". You can also just [click here] (https://www.23andme.com/you/download/ "23andme raw data download"). Enter your password, answer the secret question, and grab the "All DNA" data set. Hit the "download data" button. Once you have downloaded the raw data, unzip the file and note it's name and location.

If you are on windows, I won't be able to help you with specific commands, but it should be easy to figure out.

Dependencies:
* git
* perl
* 23andme raw data

These instructions will work from any bash shell, and probably plenty of other shells as well.

```bash
git clone git://github.com/arrogantrobot/23andme2vcf.git

cd 23andme2vcf
```

If you don't know what git is, or don't have the ability to install it, you can just click on the "download zip" button on near the top right of this github page. Once the download completes, go to the terminal, `cd` to the directory you downloaded the .zip to and unzip it. Then cd into the `23andme2vcf-master` directory. Now run the script as shown below.

```bash
perl 23andme2vcf.pl /path/to/23andme_raw.txt /path/to/output.vcf
```

Reference
=========

The reference contained here-in is a list of reference bases taken from [NCBI build37] (http://hgdownload.cse.ucsc.edu/goldenPath/hg19/chromosomes/ "NCBI build37"), which matches those sites included in the 23andme microarray exactly, in order to limit the file size and speed up creation of the VCF.
