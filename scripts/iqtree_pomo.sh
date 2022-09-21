#!/bin/bash
#SBATCH --clusters=arc
#SBATCH --array=18-18:1
#SBATCH --time=4-00:00:00 
#SBATCH --job-name=IQtree
#SBATCH --partition=long
#SBATCH --output=IQtree_%a.log
#SBATCH --error=IQtree_%a.error
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ashley.sendell-price@zoo.ox.ac.uk

#Activate IQTREE conda environment which includes both iqtree and cflib-pomo
conda activate /data/zool-zost/BIN/IQTREE
export PATH="/home/cont7348/.local/bin/:$PATH"

#Load arc anaconda module
module load angsd/0.935-GCC-10.2.0

#Set chromosome name using slurm array task id
CHROM=$(head -n $SLURM_ARRAY_TASK_ID autosomes_minus4A.txt | tail -n 1)

#Make directory for chromosome and move into it
mkdir $CHROM
cd $CHROM
mkdir temp

#Set path to info file specifying sample IDs, population assignment and bam paths
#12569	chlorocephalus	HeronIsland	ramaciotti	/data/zool-zir/cont7348/Ramaciotti/bams_pseudochroms/12569.sorted.bam
INFO=../resources/samples.txt

#For each unique population in that file do the following
for POPULATION in $(cut -f 3 $INFO | uniq)
do
    #Count number of samples in file
    LINE_COUNT=$(grep -w $POPULATION $INFO | wc -l)
    
    #For each line in the info file do the following ...
    for LINE in $(seq 1 $LINE_COUNT)
    do
        #Set sample name, population and bam path
        SAMPLE_NAME=$(grep -w $POPULATION $INFO | head -n $LINE | tail -n 1 | cut -f 1)
        SAMPLE_BAM=$(grep -w $POPULATION $INFO | head -n $LINE | tail -n 1 | cut -f 5)

        #Generate fasta file for sample
        angsd -i $SAMPLE_BAM \
        -doCounts 1 -minQ 20 -minMapQ 20 -uniqueOnly \
        -doFasta 4 -setMinDepth 3 -explode \
        -r $CHROM \
        -out ${CHROM}_${SAMPLE_NAME}

        #Create a combined fasta file (new samples will be appended)
        echo ">"${POPULATION}"-"${SAMPLE_NAME} >> ${CHROM}_${POPULATION}.fasta
        zcat ${CHROM}_${SAMPLE_NAME}.fa.gz | tail -n +2 >> ${CHROM}_${POPULATION}.fasta

        #Remove un-needed files
        rm ${CHROM}_${SAMPLE_NAME}*
    done

    #Compress population fasta file
    gzip ${CHROM}_${POPULATION}.fasta

    #Convert chrom fasta to IQTREE counts format
    #As we have a lot of population we have do to this seperately for each pop
    #or the converter freaks out
    FastaToCounts.py --iupac ${CHROM}_${POPULATION}.fasta.gz \
    ${CHROM}_${POPULATION}.cf

    #Extract count for population
    cut -d " " -f 3 ${CHROM}_${POPULATION}.cf \
    | tail -n +2 > temp/${CHROM}_${POPULATION}.allelecounts.txt

    #Extract positions
    cut -d " " -f 1,2 ${CHROM}_${POPULATION}.cf \
    | tail -n +2 > ${CHROM}.positions.txt

    #Remove un-needed file
    rm ${CHROM}_${POPULATION}.*
done

#Combine positions and count files and remove sites where a population
#has only missing data
paste -d " " ${CHROM}.positions.txt temp/* | grep -v "0,0,0,0" \
> ${CHROM}.combined.allelecounts.txt

#Thin counts file taking 0.1% of sites at random
tail -n +3 ${CHROM}.combined.allelecounts.txt | perl -ne 'print if (rand() < .001)' \
| sort -nk2 | uniq > ${CHROM}.randomsubset.combined.allelecounts.txt
N_SITES=$(expr $(cat ${CHROM}.randomsubset.combined.allelecounts.txt | wc -l) - 1)
N_POPS=$(ls temp/*.allelecounts.txt | wc -l)
echo "COUNTSFILE NPOP" $N_POPS "NSITES" $N_SITES > ${CHROM}.randomsubset.cf
sed -n '1p' ${CHROM}.combined.allelecounts.txt >> ${CHROM}.randomsubset.cf
tail -n +2 ${CHROM}.randomsubset.combined.allelecounts.txt >> ${CHROM}.randomsubset.cf
#rm -r temp *.txt

#Run IQtree
iqtree -s ${CHROM}.randomsubset.cf -m MF+P -o Reunion -safe
