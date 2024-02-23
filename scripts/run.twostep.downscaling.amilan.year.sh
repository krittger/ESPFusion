#!/bin/sh

#### Switch to this for preemptable blanca job:
#SBATCH --partition=amilan
#SBATCH --account=ucb398_asc1
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --time=4:00:00
#SBATCH --qos=normal
#SBATCH --output=/projects/lost1845/ESPFusion/output/run.twostep.downscaling.amilan.year.-%A_%a.out
#SBATCH --job-name=run.twostep.downscaling.amilan
#SBATCH --array=1-366

PROGNAME=$(basename $0)

year=$1

#source $RC_CONDA
source /projects/lost1845/miniconda3/etc/profile.d/conda.sh
conda init bash
conda activate r_ESP



if [ ${SLURM_ARRAY_TASK_ID} -le 365 ] || [ 0 -eq $(( ${year} % 4 )) ]
   then
       echo "${PROGNAME}: Processing year=${year}, dayOfYear=${SLURM_ARRAY_TASK_ID}" 1>&2
       Rscript --no-save --no-restore /projects/lost1845/ESPFusion/exec/twostep.downscaling.R \
--year=${year} --dayOfYear=${SLURM_ARRAY_TASK_ID} \
--modelVersion=5 \
--modisVersion=5 \

else
    echo "${PROGNAME}: Skipping year=${year}, dayOfYear=${SLURM_ARRAY_TASK_ID}" 1>&2
fi
    
echo "${PROGNAME}: Done."
