#!/bin/sh

#### Switch to this for preemptable blanca job:
#SBATCH --partition=amilan
#SBATCH --nodes=1
#SBATCH --mem=100GB
#SBATCH --time=5:00:00
#SBATCH --qos=normal
#SBATCH --output=/projects/lost1845/ESPFusion/output/run.twostep.downscaling.amilan.%j.out
#SBATCH --job-name=run.twostep.downscaling.amilan


#source $RC_CONDA
source /projects/lost1845/miniconda3/etc/profile.d/conda.sh
conda init bash
conda activate r_ESP

Rscript --no-save --no-restore /projects/lost1845/ESPFusion/exec/twostep.downscaling.R 
