#!/bin/sh

#SBATCH --qos=normal
#SBATCH --account=ucb-general
#SBATCH --ntasks-per-node=1
#SBATCH --nodes=1
#SBATCH --time=00:02:00
#SBATCH --output=output/run_hw-%A_%a.out
#SBATCH --job-name=run_hw
#SBATCH --mail-type=ALL
#SBATCH --mail-user=brodzik@nsidc.org
#SBATCH --array=1850,2530,3014,4080

# 1850: 20050123
# 2530: 20061204
# 3014: 20080401
# 4080: 20110303

SLURM_ARRAY_TASK_ID=12

usage() {
    echo "" 1>&2
    echo " Calls hw script" 1>&2
    echo "Options: " 1>&2
    echo "  -h: display help message and exit" 1>&2
    echo "Arguments: " 1>&2
    echo "  CONDAENV: conda env to activate with R and libraries" 1>&2
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

echo "${PROGNAME}: Processing dayIndex: ${SLURM_ARRAY_TASK_ID}" 1>&2
Rscript --no-save --no-restore ../exec/hw.R ${SLURM_ARRAY_TASK_ID}

echo "${PROGNAME}: Done."
