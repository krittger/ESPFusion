#!/bin/sh

#### Switch to this for preemptable blanca job:
#SBATCH --account=ucb398_asc1
#SBATCH --partition=amilan
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=64
#SBATCH --time=100:00:00
#SBATCH --qos=long
#SBATCH --output=/projects/lost1845/ESPFusion/output/run.twostep.prediction.amilan.%j.out
#SBATCH --job-name=run.twostep.prediction.amilan


#source $RC_CONDA
source /projects/lost1845/miniconda3/etc/profile.d/conda.sh
conda init bash
conda activate r_ESP

Rscript --no-save --no-restore /projects/lost1845/ESPFusion/exec/twostep.prediction.R 
