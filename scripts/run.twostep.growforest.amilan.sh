#!/bin/sh

#### Switch to this for preemptable blanca job:
#SBATCH --account=ucb398_asc1
#SBATCH --partition=amilan
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --time=2:00:00
#SBATCH --qos=normal
#SBATCH --output=/projects/lost1845/ESPFusion/output/run.twostep.growforest.amilan.%j.out
#SBATCH --job-name=run.twostep.growforest.amilan


#source $RC_CONDA
source /projects/lost1845/miniconda3/etc/profile.d/conda.sh
conda init bash
conda activate r_ESP

Rscript --no-save --no-restore /projects/lost1845/ESPFusion/exec/twostep.growforest.R 
