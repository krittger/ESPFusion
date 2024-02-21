#!/bin/sh

#### Switch to this for preemptable blanca job:
#SBATCH --account=ucb398_asc1
#SBATCH --partition=amilan
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=64
#SBATCH --time=4:00:00
#SBATCH --qos=normal
#SBATCH --output=/projects/lost1845/ESPFusion/output/run.SCA.comparedays.amilan.%j.out
#SBATCH --job-name=run.SCA.comparedays.amilan


#source $RC_CONDA
source /projects/lost1845/miniconda3/etc/profile.d/conda.sh
conda init bash
conda activate r_ESP

Rscript --no-save --no-restore /projects/lost1845/ESPFusion/exec/SCA.comparedays.R 
