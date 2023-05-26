mkdir mapping/Zlat_mitogenome
#!/bin/bash

#################################################################################################
# Project:  Zosterops lateralis phylogeny
# Script:   harvest_mito_genomes_NOVOGENE.sh
# Author:   Ash Sendell-Price
# Date:     26/05/2023
# System:   ARC HTC (Oxford)
# Summary:  Uses norgal to identify reads of mitochondrial origin and attempts de novo mito genome
#           assembly construction for all samples. Outputs "mito" genome sequence plus fastq files
#           containing mito reads.
#################################################################################################

#Load required modules and set path to norgal
module load matplotlib
NORGAL=/data/zool-zost/BIN/norgal/norgal.py

#Make directory for storing norgal output
mkdir mitogenomes
mkdir mitogenomes/reads
mkdir mitogenomes/fasta




#For each of the novogene sequenced samples in "resources/novogene_samples.txt"
#do the following:
for SAMPLE in $(cat resources/novogene_samples.txt)
do
    #Make directory for input files
    mkdir norgal_input

    #Combine read files for each pair into a single forward and reverse fastq
    for ReadPair in $(ls novogene_filtered_reads/${SAMPLE}/Filtered_${SAMPLE}_*_1.fq.gz | rev | cut -d "_" -f2- | rev)
    do
        zcat ${ReadPair}_1.fq.gz >> norgal_input/forward.fastq
        zcat ${ReadPair}_2.fq.gz >> norgal_input/reverse.fastq
    done

    #Run norgal
    python bin/norgal/norgal.py \
    -i norgal_input/forward.fastq norgal_input/reverse.fastq \
    -m 15000 \
    -o norgal_output

    #Move files we want to keep
    mv norgal_output/mtDNA_coverage_plot.png mitogenomes/coverage/${SAMPLE}_mtDNA_coverage_plot.png
    mv norgal_output/*longest.fa mitogenomes/fasta/${SAMPLE}_mtDNA_longest.fa
    mv norgal_output/reads/mtread1.fq mitogenomes/reads/${SAMPLE}_mtread1.fq
    mv norgal_output/reads/mtread2.fq mitogenomes/reads/${SAMPLE}_mtread2.fq

    #Delete temp "norgal_input" and "norgal_output" directories
    rm -r norgal_output
    rm -r norgal_input

done
