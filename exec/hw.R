#!/usr/bin/env Rscript

### usage: ./hw.sh dayindex

suppressPackageStartupMessages(require(optparse))
### manual: http://cran.r-project.org/web/packages/optparse/optparse.pdf
### Nice tutorials on using optparse:
### http://www.cureffi.org/2014/01/15/running-r-batch-mode-linux/
### https://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines/

option_list = list(
    make_option(c("-t", "--numTrees"), type="integer",
                default=50,
                help="number of trees in regression forest [default=%default]",
                metavar="integer"),
    make_option(c("-o", "--outDir"), type="character",
                default="/pl/active/SierraBighorn/downscaledv3_test/",
                help=paste0("top-level output directory [default=%default]",
                            " will contain 'downscaled', 'prob.btwn', 'prob.hundred'"),
                metavar="character")
);

parser <- OptionParser(usage = "%prog [options] dayIndex",
                      option_list=option_list);
arguments <- parse_args(parser, positional_arguments = 1);

opt <- arguments$options
dayIndex <- arguments$args

print(paste("numTrees=", opt$numTrees))
print(paste("outDir=", opt$outDir))
print(paste("dayindex=", dayIndex))

myEnv <- ESPFusion::Env()
print(paste("modisDir: ", myEnv$modisDir))
print(paste("landsatDir: ", myEnv$landsatDir))

