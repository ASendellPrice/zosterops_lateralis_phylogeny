#!/bin/bash
#!/bin/bash
#SBATCH --clusters=htc
#SBATCH --array=2-10:1
#SBATCH --time=2-00:00:00 
#SBATCH --job-name=norgal
#SBATCH --partition=long
#SBATCH --output=norgal_%a.log
#SBATCH --error=norgal_%a.error
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ashley.sendell.price@gmail.com


#################################################################################################
# Project:  Zosterops lateralis phylogeny
# Script:   harvest_mito_genomes_NOVOGENE.sh
# Author:   Ash Sendell-Price
# Date: 26/05/2023
# System:   ARC HTC (Oxford)
# Summary:  Uses norgal to identify reads of mitochondrial origin and attempts de novo mito genome
#   assembly construction for all samples. Outputs "mito" genome sequence plus fastq files
#   containing mito reads.
#################################################################################################

#Load required modules and set path to norgal
module load matplotlib
NORGAL=/data/zool-zost/BIN/norgal/norgal.py

#Make directory for storing norgal output
mkdir mitogenomes
mkdir mitogenomes/reads
mkdir mitogenomes/fasta
mkdir mitogenomes/coverage
cd mitogenomes

#Make directory for input files
mkdir task${SLURM_ARRAY_TASK_ID}_input

#Set sample info parameters
SAMPLE_ID=$(head -n $SLURM_ARRAY_TASK_ID ../resources/sample_info.txt | tail -n 1 | cut -f 1) # e.g GT224
SUBSPECIES=$(head -n $SLURM_ARRAY_TASK_ID ../resources/sample_info.txt | tail -n 1 | cut -f 2) # e.g. griseonota
LOCATION=$(head -n $SLURM_ARRAY_TASK_ID ../resources/sample_info.txt | tail -n 1 | cut -f 3) # e.g. GrandTerre
PLATFORM=$(head -n $SLURM_ARRAY_TASK_ID ../resources/sample_info.txt | tail -n 1 | cut -f 4) # e.g. Novogene
DIRECTORY=$(head -n $SLURM_ARRAY_TASK_ID ../resources/sample_info.txt | tail -n 1 | cut -f 5) # e.g. /data/zool-zost/Novogene/GrandeTerre/GT224

#Combine read files for each pair into a single forward and reverse fastq
for ReadPair in $(ls ${DIRECTORY}/*_1.fq.gz | rev | cut -d "_" -f2- | rev)
do
zcat ${ReadPair}_1.fq.gz >> task${SLURM_ARRAY_TASK_ID}_input/forward.fastq
zcat ${ReadPair}_2.fq.gz >> task${SLURM_ARRAY_TASK_ID}_input/reverse.fastq
done

#Run norgal
python $NORGAL \
-i task${SLURM_ARRAY_TASK_ID}_input/forward.fastq task${SLURM_ARRAY_TASK_ID}_input/reverse.fastq \
-m 15000 \
-o task${SLURM_ARRAY_TASK_ID}_output

#Move files we want to keep
mv task${SLURM_ARRAY_TASK_ID}_output/mtDNA_coverage_plot.png \
mitogenomes/coverage/${SAMPLE_ID}_${SUBSPECIES}_${LOCATION}_${PLATFORM}_mtDNA_coverage_plot.png
mv task${SLURM_ARRAY_TASK_ID}_output/*longest.fa mitogenomes/fasta/${SAMPLE_ID}_${SUBSPECIES}_${LOCATION}_${PLATFORM}_mtDNA_longest.fa
mv task${SLURM_ARRAY_TASK_ID}_output/reads/mtread1.fq mitogenomes/reads/${SAMPLE_ID}_${SUBSPECIES}_${LOCATION}_${PLATFORM}_mtread1.fq
mv task${SLURM_ARRAY_TASK_ID}_output/reads/mtread2.fq mitogenomes/reads/${SAMPLE_ID}_${SUBSPECIES}_${LOCATION}_${PLATFORM}_mtread2.fq

#Delete temp "norgal_input" and "task${SLURM_ARRAY_TASK_ID}_output" directories
rm -r task${SLURM_ARRAY_TASK_ID}_output
rm -r task${SLURM_ARRAY_TASK_ID}_input
