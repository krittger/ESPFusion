#!/bin/sh

#### Switch to this for normal summit job:
#SBATCH --qos=normal
#SBATCH --account=ucb157_summit1
#SBATCH --ntasks-per-node=24
#SBATCH --nodes=1
#SBATCH --mem=100GB
#SBATCH --time=08:00:00
#SBATCH --output=output/run.twostep.downscaling.summit-%A_%a.out
#SBATCH --job-name=run.twostep.downscaling.summit
#SBATCH --mail-type=END,FAIL,REQUEUE,STAGE_OUT
#SBATCH --mail-user=brodzik@nsidc.org
#SBATCH --array=338,92,62

# Original array indices (for regression tests):
# 1850: 20050123:  23
# 2530: 20061204: 338
# 3014: 20080401:  92
# 4080: 20110303:  62

usage() {
    echo "" 1>&2
    echo " Job array to call ESPFusion twostep.downscaling" 1>&2
    echo "Options: " 1>&2
    echo "  -h: display help message and exit" 1>&2
    echo "Arguments: " 1>&2
    echo "  CONDAENV: conda env to activate with R and libraries" 1>&2
    echo "  yyyy: 4-digit year to process" 1>&2
    echo "" 1>&2
}

PROGNAME=$(basename $0)

error_exit() {
    # Use for fatal program error
    # Argument:
    #   optional string containing descriptive error message
    #   if no error message, prints "Unknown Error"

    echo "${PROGNAME}: ERROR: ${1:-"Unknown Error"}" 1>&2
    exit 1
}

while getopts "h" opt
do
    case $opt in
	h) usage
	   exit 1;;
	?) usage
           exit 1;;
	esac
done

shift $(($OPTIND - 1))

[[ "$#" -eq 1 ]] || error_exit "Line $LINENO: Unexpected number of arguments."

condaenv=$1
source activate $condaenv

case ${SLURM_ARRAY_TASK_ID} in
    23) year=2005;;
    338) year=2006;;
    92) year=2008;;
    *) year=2011;;
esac

echo "${PROGNAME}: Processing year=${year}, dayOfYear=${SLURM_ARRAY_TASK_ID}" 1>&2
Rscript --no-save --no-restore ../exec/twostep.downscaling.R \
--year=${year} --dayOfYear=${SLURM_ARRAY_TASK_ID} \
--outDir=/pl/active/SierraBighorn/downscaledv3_test	

echo "${PROGNAME}: Done, status= $?"
