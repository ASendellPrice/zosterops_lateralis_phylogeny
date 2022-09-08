#!/bin/bash
#SBATCH --clusters=all
#SBATCH --ntasks-per-node=1
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

#Load arc anaconda module
module load angsd/0.935-GCC-10.2.0

#Set chromosome name using slurm array job id
CHROM=$(head -n $SLURM_ARRAY_JOB_ID autosomes_minus4A.txt | tail -n 1)

#Make directory for chromosome and move into it
mkdir $CHROM
cd $CHROM

#Set path to info file specifying sample IDs, population assignment and bam paths
#12569	chlorocephalus	HeronIsland	ramaciotti	/data/zool-zir/cont7348/Ramaciotti/bams_pseudochroms/12569.sorted.bam
INFO=../resources/sample_info_noAgResearch.txt

#Count number of lines in file
LINE_COUNT=$(cat $INFO | wc -l)

#For each line in the info file do the following ...
for LINE in $(seq 1 $LINE_COUNT)
do
    #Set sample name, population and bam path
    SAMPLE_NAME=$(head -n $LINE $INFO | tail -n 1 | cut -f 1)
    POPULATION=$(head -n $LINE $INFO | tail -n 1 |  cut -f 3)
    SAMPLE_BAM=$(head -n $LINE $INFO | tail -n 1 | cut -f 5)

    #Generate fasta file for sample
    angsd -i $SAMPLE_BAM \
    -doCounts 1 -minQ 20 -minMapQ 20 -uniqueOnly \
    -doFasta 4 -setMinDepth 3 \
    -r $CHROM \
    -out ${CHROM}_${SAMPLE_NAME}

    #Create a combined fasta file (new samples will be appended)
    echo ">"${POPULATION}"-"${SAMPLE_NAME} >> $CHROM.fasta
    zcat ${CHROM}_${SAMPLE_NAME}.fa.gz | tail -n +2 >> $CHROM.fasta

    #Remove un-needed files
    rm ${CHROM}_${SAMPLE_NAME}*
done

#Convert chrom fasta to IQTREE counts format
export PATH="/home/cont7348/.local/bin/:$PATH"
FastaToCounts.py $CHROM.fasta $CHROM.cf --iupac

#Remove sites where a population has only missing data
grep -v "0,0,0,0" $CHROM.cf > $CHROM.filtered.cf

#Thin counts file taking 1% of sites at random
tail -n +3 $CHROM.filtered.cf | perl -ne 'print if (rand() < .05)' | sort -nk2 | uniq > temp
N=$(cat temp | wc -l)
echo "COUNTSFILE NPOP 13 NSITES" $N > thinned_$CHROM.cf
sed -n '2p' $CHROM.filtered.cf >> thinned_$CHROM.cf
cat temp >> thinned_$CHROM.cf
rm temp

#Run IQtree
iqtree -s thinned_$CHROM.cf -m MF+P -o Reunion -safe