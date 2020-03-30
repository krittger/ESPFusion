#!/bin/bash

#SBATCH --qos=normal
#SBATCH --account=ucb-general
#SBATCH --ntasks-per-node=24
#SBATCH --nodes=1
#SBATCH --mem=100GB
#SBATCH --time=160:00:00
#SBATCH --output=twostep.summit.timing2.%j.out
#SBATCH --job-name=twostep-timing2

module purge

module load R
module load gdal
module load proj

R CMD BATCH --no-save --no-restore twostep.summit.timing.test2.R
