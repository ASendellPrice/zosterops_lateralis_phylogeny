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
NORGAL=/data/zool-zost/cont7348/zosterops_lateralis_phylogeny/norgal/norgal.py

#Concatinating fasta files
#cat /data/zool-zost/Novogene/ChathamIsland/CI1/CI1_FDSW202476971-1r_HC5LKDSXY_L1_1.fq.gz \
#/data/zool-zost/Novogene/ChathamIsland/CI1/CI1_FDSW202476971-1r_HCJNYDSXY_L4_1.fq.gz \
#> CI1_1.fasta.gz
#cat /data/zool-zost/Novogene/ChathamIsland/CI1/CI1_FDSW202476971-1r_HC5LKDSXY_L1_2.fq.gz \
#/data/zool-zost/Novogene/ChathamIsland/CI1/CI1_FDSW202476971-1r_HCJNYDSXY_L4_2.fq.gz \
#> CI1_2.fasta.gz

python $NORGAL \
-i CI1_1.fasta.gz CI1_2.fasta.gz -o norgal_test --blast