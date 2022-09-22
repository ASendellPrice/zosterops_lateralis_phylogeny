#!/bin/bash
#SBATCH --clusters=htc
#SBATCH --time=1-00:00:00 
#SBATCH --job-name=process_Zbor
#SBATCH --partition=long
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ashley.sendell-price@zoo.ox.ac.uk

FASTP=/data/zool-zost/BIN/fastp
ml SAMtools/1.12-GCC-10.2.0
BWA=/data/zool-zost/BIN/bwa/bwa
REF=/data/zool-zost/Ref_Genome/Ref_Genome_PseudoChroms/Zlat_2_Tgut_pseudochromosomes.shortChromNames.fasta.gz

#Make directory and move into it
#mkdir Zbor
#cd Zbor

#Set path to file specifying Z.bor IDs and ftp paths to raw read files
INFO=../resources/zbor_info.txt

#For each line in the file do the following 
#for $LINE in $(seq 1 $(cat $INFO | wc -l))
for $LINE in $(seq 1 1)
do
    #Set sample name and FTP paths
    SAMPLE_ID=$(cut -f 1 $INFO | head -n $LINE | tail -n 1)
    FTP_PATH=$(cut -f 2 $INFO | head -n $LINE | tail -n 1)

    #Download reads from ENA
    #wget ftp://ftp.sra.ebi.ac.uk/${FTP_PATH}_1.fastq.gz
    #wget ftp://ftp.sra.ebi.ac.uk/${FTP_PATH}_2.fastq.gz

    #Filter read files
    $FASTP \
    -i ${SAMPLE_ID}_1.fastq.gz \
    -o Filtered_${SAMPLE_ID}_1.fastq.gz \
    -I ${SAMPLE_ID}_2.fastq.gz \
    -O Filtered_${SAMPLE_ID}_2.fastq.gz \
    --trim_front1 10 \
    --trim_front2 10

    #Remove un-filtered reads
    rm ${SAMPLE_ID}_1.fastq.gz 
    rm ${SAMPLE_ID}_2.fastq.gz

    #Map reads to pseudochromosome reference assembly
    $BWA mem $REF ./Filtered_${SAMPLE_ID}_1.fastq.gz ./Filtered_${SAMPLE_ID}_2.fastq.gz \
    -R "@RG\tID:${SAMPLE_ID}\tSM:${SAMPLE_ID}" \
    | samtools view -bS - > full_${SAMPLE_ID}.bam
    
    #Sort bam file
    samtools sort full_${SAMPLE_ID}.bam -o full_${SAMPLE_ID}.sorted.bam
    rm full_${SAMPLE_ID}.bam

    #Calculate current average depth of bam
    REFGENOME_LENGTH=$(cat ${REF}.fai | awk '{sum+=$2} END {print sum}')
    MEAN_DEPTH=$(samtools depth -a full_${SAMPLE_ID}.sorted.bam | awk -v len=${REFGENOME_LENGTH} '{sum+=$3} END { print sum/len}')

    #Calculate proportion of reads to keep to acheive desired depth of coverage
    TARGET_DEPTH=5
    PROP_RETAIN=$(awk "BEGIN {print $TARGET_DEPTH/$MEAN_DEPTH}")

    #Round proportion to 3 decimal places
    PROP_RETAIN_3D=$(printf '%.*f\n' 3 $PROP_RETAIN)

    #Downsample bam file
    samtools view -s $PROP_RETAIN_3D -b full_${SAMPLE_ID}.sorted.bam > downsampled_${SAMPLE_ID}.bam
    rm full_${SAMPLE_ID}.sorted.bam

    #Sort bam file
    samtools sort downsampled_${SAMPLE_ID}.bam -o downsampled_${SAMPLE_ID}.sorted.bam
    rm downsampled_${SAMPLE_ID}.bam 

    #Index bam file
    samtools index -@ 2 downsampled_${SAMPLE_ID}.sorted.bam

done
