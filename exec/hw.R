#!/usr/bin/env Rscript
library(raster)

### usage: ./hw.sh dayindex

suppressPackageStartupMessages(require(optparse))
### manual: http://cran.r-project.org/web/packages/optparse/optparse.pdf
### Nice tutorials on using optparse:
### http://www.cureffi.org/2014/01/15/running-r-batch-mode-linux/
### https://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines/

### Get default environment
myEnv <- ESPFusion::Env()

option_list = list(
    make_option(c("-i", "--dayIndex"), type="integer",
                default=0,
                help="day index into files array [default=%default]",
                metavar="integer"),
    make_option(c("-t", "--numTrees"), type="integer",
                default=50,
                help="number of trees in regression forest [default=%default]",
                metavar="integer"),
    make_option(c("-o", "--outDir"), type="character",
                default=myEnv$fusionDir,
                help=paste0("top-level output directory\n",
                            "\t\t[default=%default]\n",
                            "\t\twill contain output for downscaled, prob.btwn,\n",
                            "\t\tprob.hundred and regression"),
                metavar="character")
);

parser <- OptionParser(usage = "%prog [options]",
                      option_list=option_list);
opt <- parse_args(parser);

print(paste("numTrees=", opt$numTrees))
print(paste("outDir=", opt$outDir))
print(paste("dayindex=", opt$dayIndex))

print(paste("landsatDir: ", myEnv$landsatDir))
print(paste("fusionDir: ", myEnv$fusionDir))
print(paste("30mRows: ", myEnv$SSN30mRows))
print(paste("30mCols: ", myEnv$SSN30mCols))
print(paste("500mRows: ", myEnv$SSN500mRows))
print(paste("500mCols: ", myEnv$SSN500mCols))

out <- ESPFusion::PrepOutDirs(opt$outDir, 3e+05)

print(out$downscaled)
print(out$prob.btwn)
print(paste(Sys.time(), ":", out$regression))

s <- 2
print(paste0(Sys.time(), ": done with split=", s))

quit(status=0);
    

