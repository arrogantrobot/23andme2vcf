#include <stdio.h>
#include <stdlib.h>
#include <string.h>


void print_usage() {
    printf("usage:  ./23andme2vcf /path/to/raw/data.txt /path/to/23andme.fa\n");
    exit(1);
}

void get_data(char * raw_string, char * chrom, char * pos, char * rsid, char * alleles) {
    int idx = 0, start = 0;
    while (raw_string[idx] != '\t') idx++;
    strncpy(rsid, raw_string, idx);
    start = idx;
    while (raw_string[idx] != '\t') idx++;
    strncpy(chrom, raw_string + start, idx);
    start = idx;
    while (raw_string[idx] != '\t') idx++;
    strncpy(pos, raw_string + start, idx);
    start = idx;
    while (raw_string[idx] != '\n') idx++;
    strncpy(alleles, raw_string + start, idx);
}

char* get_output(char * answer, char * raw_string, char * ref_string) {
    char chrom[40], pos[40], rsid[40], alleles[40];
    char ref[40];
    get_data(raw_string, chrom, pos, rsid, alleles);
    get_ref(ref_string, ref);

    return answer;
}

void process_line(FILE *input, FILE *ref, FILE *output) {
    char raw_string[200], ref_string[200];
    char answer[1024];
    fscanf(input, "%s", raw_string);
    fscanf(ref, "%s", ref_string);
    get_output(answer, raw_string, ref_string);
    fprintf(output, answer);
}

int main(int argc, char * argv[]) {
    
    if (argc < 3) {
        print_usage();
    }

    FILE *input,*output, *ref;

    input = fopen(argv[1],"r");
    ref = fopen(argv[2], "r");
    output = fopen(argv[3], "w");

    unsigned char done = '0';

    while (! done)
        process_line(input, ref, output);

    fclose(output);
    fclose(input);
    fclose(ref);

    return 0;

}
