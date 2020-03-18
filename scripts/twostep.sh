#!/bin/bash

#SBATCH --nodes=1
#SBATCH --mem=180G
#SBATCH --ntasks=64
#SBATCH --time=160:00:00
#SBATCH --qos=blanca-rittger
#SBATCH --output=twostep.%j.out
#SBATCH --job-name=twostep-trial


source $RC_CONDA

conda activate $USER_R

R CMD BATCH --no-save --no-restore twostep.growforest.R
R CMD BATCH --no-save --no-restore twostep.prediction.R
R CMD BATCH --no-save --no-restore SCA.comparedays.R
