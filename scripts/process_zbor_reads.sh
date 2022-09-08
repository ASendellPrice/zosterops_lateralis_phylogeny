#!/bin/bash
#SBATCH --clusters=htc
#SBATCH --ntasks-per-node=1
#SBATCH --time=1-00:00:00 
#SBATCH --job-name=downloadZbor
#SBATCH --partition=long
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ashley.sendell-price@zoo.ox.ac.uk

#Get borbonicus reads from ENA
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR885/004/SRR8858134/SRR8858134_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR885/004/SRR8858134/SRR8858134_2.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR888/000/SRR8881980/SRR8881980_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR888/000/SRR8881980/SRR8881980_2.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR888/004/SRR8881994/SRR8881994_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR888/004/SRR8881994/SRR8881994_2.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR888/005/SRR8881995/SRR8881995_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR888/005/SRR8881995/SRR8881995_2.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR888/001/SRR8887131/SRR8887131_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR888/001/SRR8887131/SRR8887131_2.fastq.gz
