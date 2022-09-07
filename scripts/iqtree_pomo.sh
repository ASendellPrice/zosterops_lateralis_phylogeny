#!/bin/bash
#SBATCH --clusters=all
#SBATCH --ntasks-per-node=1
#SBATCH --mem-per-cpu=100G
#SBATCH --array=14-15:1
#SBATCH --time=5-00:00:00 
#SBATCH --job-name=EstimateGLs_ImputeGTs
#SBATCH --partition=long
#SBATCH --output=EstimateGLs_ImputeGTs_%A_%a.log
#SBATCH --error=EstimateGLs_ImputeGTs_%A_%a.error
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ashley.sendell-price@zoo.ox.ac.uk

#Load anaconda module
module load angsd/0.935-GCC-10.2.0

#SET CHROMOSOME NAME
CHROM=

#Set path to reference assembly and list of bam files (bam.list)
#info file specifying sample IDs, population assignment and bam paths
REF=/data/zool-zost/Ref_Genome/Ref_Genome_PseudoChroms/Zlat_2_Tgut_pseudochromosomes.fasta.gz
INFO=resources/bam_info.txt

#For each line in the info file do the following ...
for LINE in $(cat $INFO)
do
    #Set sample name, population and bam path
    SAMPLE_NAME=$(echo $LINE | cut -f 1)
    POPULATION=$(echo $LINE | cut -f 2)
    BAM_PATH=$(echo $LINE | cut -f 3)

    #Generate fasta file for sample
    angsd -i $SAMPLE_BAM \
    -doCounts 1 -minQ 20 -minMapQ 20 -uniqueOnly \
    -doFasta 4 -iupacRatio 0.1 -basesPerLine 1 \
    -r $CHROM \
    -out ${CHROM}_${SAMPLE_NAME}
done





for SPECIES in $(cut -f 1 ../sample.bams | sort | uniq | grep -v "hybrid")
do
    #Create list of sample bams
    cat ../sample.bams | grep -v "hybrid" | grep $SPECIES | cut -f 2 \
    > bam.list.temp
      
    #For each sample bam do the following
    for SAMPLE_BAM in $(cat bam.list.temp)
    do
        #Get sample name from bam name
        SAMPLE_NAME=$(basename $SAMPLE_BAM | cut -d "." -f 1)
        #Generate FASTA consensus sequence using angsd
        angsd -i ${SAMPLE_BAM} \
        -doCounts 1 -minQ 20 -minMapQ 20 -uniqueOnly \
        -doFasta 4 -iupacRatio 0.25 -basesPerLine 1 \
        -r ${CHR}:${START}-${END} \
        -out Loci${LOCI_NO}_${SAMPLE_NAME}
            
        #Create fasta file for region of interest
        echo ">"${SPECIES}"-"${SAMPLE_NAME} \
        > TEMP/Loci${LOCI_NO}_${SAMPLE_NAME}.fasta.tmp
        zcat Loci${LOCI_NO}_${SAMPLE_NAME}.fa.gz \
        | sed -n "$(expr ${START} + 1),$(expr ${END} + 1) p" \
        >> TEMP/Loci${LOCI_NO}_${SAMPLE_NAME}.fasta.tmp
        fasta_formatter -i TEMP/Loci${LOCI_NO}_${SAMPLE_NAME}.fasta.tmp -w 50 -e \
        >> FASTAs/Loci${LOCI_NO}.fa

        #Tidy up!
        rm Loci${LOCI_NO}_${SAMPLE_NAME}*
    done

    #Some more tidying up!
    rm bam.list.temp

done

#Some more tidying up!
rm -r TEMP

#Convert loci fasta to IQTREE counts format
/domus/h1/ashle/.local/bin/FastaToCounts.py \
FASTAs/Loci${LOCI_NO}.fa COUNTs/Loci${LOCI_NO}.cf --iupac

#Run IQTREE for loci of interest
iqtree -s COUNTs/Loci${LOCI_NO}.cf \
-m MFP -nt AUTO -bb 1000 -T AUTO \
-o barbadensis -safe
