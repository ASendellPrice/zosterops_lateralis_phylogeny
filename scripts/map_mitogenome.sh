#!/bin/bash
#SBATCH --clusters=htc
#SBATCH --time=1-00:00:00 
#SBATCH --job-name=MapMitoGenome
#SBATCH --partition=long
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ashley.sendell.price@gmail.com

#####
#PIPELINE IN DEVELOPMENT!!!!
#####

#Testing out mitogenome harvesting from our 5X data
#Using CI1 as a test sample
#####
#####

#Set path to norgal
MEANGS=/data/zool-zost/cont7348/zosterops_lateralis_phylogeny/MEANGS/meangs.py

#Concatinating fasta files
#cat /data/zool-zost/Novogene/ChathamIsland/CI1/CI1_FDSW202476971-1r_HC5LKDSXY_L1_1.fq.gz \
#/data/zool-zost/Novogene/ChathamIsland/CI1/CI1_FDSW202476971-1r_HCJNYDSXY_L4_1.fq.gz \
#> CI1_1.fastq.gz
#cat /data/zool-zost/Novogene/ChathamIsland/CI1/CI1_FDSW202476971-1r_HC5LKDSXY_L1_2.fq.gz \
#/data/zool-zost/Novogene/ChathamIsland/CI1/CI1_FDSW202476971-1r_HCJNYDSXY_L4_2.fq.gz \
#> CI1_2.fastq.gz

python $MEANGS \
-1 CI1_1.fastq.gz \
-2 CI1_2.fastq.gz \
-o CI1_test --deepin

