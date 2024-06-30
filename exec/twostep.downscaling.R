#!/usr/bin/env Rscript
#
# 2019 Mitchell L. Krock mitchell.krock@colorado.edu 
# Copyright (C) 2019 Regents of the University of Colorado
#
library(raster)
library(ranger)

library(devtools)
proj_path <- paste0("/projects/", Sys.getenv("LOGNAME"), "/ESPFusion")
setwd(proj_path)
#devtools::install()

suppressPackageStartupMessages(require(optparse))

### Get default environment
devtools::load_all()
myEnv <- ESPFusion::Env()
myEnv$getFusionDir()
## change environment to Env.R file instead of R package
#source("R/Env.R")
#myEnv <- Env()

### Parse inputs
option_list = list(
    make_option(c("-y", "--year"), type="integer",
                default=2020,
                help="year of data to process [default=%default]",
                metavar="integer"),
    make_option(c("-d", "--dayOfYear"), type="integer",
                default=165,
                help="day of year to process [default=%default]",
                metavar="integer"),
    make_option(c("-i", "--modisVersion"), type="integer",
                default=5,
                help="version of MODIS input data to process [default=%default]",
                metavar="integer"),
    make_option(c("-m", "--modelVersion"), type="integer",
                default=5,
                help="version of model classifier/regresionfiles to use [default=%default]",
                metavar="integer"),
    make_option(c("-t", "--numTrees"), type="integer",
                default=50,
                help="number of trees in regression forest [default=%default]",
                metavar="integer"),
    make_option(c("-f", "--forceOverwrite"), type="logical",
                default=FALSE,
                help="force output files to overwrite any previous outputs [default=%default]",
                metavar="logical"),
    make_option(c("-o", "--outDir"), type="character",
                default=myEnv$getFusionDir(),
                help=paste0("top-level output directory\n",
                            "\t\t[default=%default]\n",
                            "\t\twill contain output for downscaled, prob.btwn,\n",
                            "\t\tprob.hundred and regression"),
                metavar="character")
);

parser <- OptionParser(usage = "%prog [options]", option_list=option_list);
opt <- parse_args(parser);

if(opt$modisVersion < 5){
    throw("modisVersion must be 5 or greater")
}

print(paste(Sys.time(), ": Begin"))
print(sprintf("year=%d, doy=%d, numTrees=%d", opt$year, opt$dayOfYear, opt$numTrees))
print(sprintf("outDir=%s", opt$outDir))

##
## Setup for downscaling
## (this should contain daydat and theseNA)
##
#setupFile <- myEnv$getPredictorFilenameFor(version=0)
setupFile <- "/pl/active/rittger_esp/SierraBighorn/Rdata/predictors.SCA.v00.RData"
load(setupFile)

### Make output directories if needed
outDirs <- ESPFusion::PrepOutDirs(opt$outDir, myEnv$getTrain.size(), opt$year)

## Get study Extent information
extent <- ESPFusion::StudyExtent("SouthernSierraNevada")

classes <- rep(NA, dim(daydat)[1])
regressionvalues <- rep(NA, dim(daydat)[1])
prob.btwn <- rep(NA, dim(daydat)[1])
prob.hundred <- rep(NA, dim(daydat)[1])
downscaled <- rep(NA, times=extent$highResCols * extent$highResRows)

### For classification, done in chunks,
### avoids memory issues when trying to do all points simultaneously
splits <- seq(1, dim(daydat)[1], by=1e6)
splits <- c(splits, dim(daydat)[1])

## Grab a landsat raster to initialize output sizing
landsat.sc.file.names <- myEnv$allLandsatFiles("snow_cover_percent")
pred.rast <- raster(landsat.sc.file.names[1])

## Find the modis file to process
modis.sc.file.name <- myEnv$modisFileFor(opt$year, opt$dayOfYear,
                                         'snow_cover_percent',
                                         opt$modisVersion)

modis.yyyymmdd <- myEnv$parseDateFrom(modis.sc.file.name)
print(paste0("Processing MODIS file: ", modis.sc.file.name))

## If all expected output files already exist for this date, don't repeat
## processing. This behavior can be overridden with --forceOverwrite
outRegressionFile <-
    myEnv$getDownscaledFilenameFor(outDirs$regression,
                                   "regression",
                                   extent$shortName,
                                   modis.yyyymmdd,
                                   version=opt$modelVersion)
outDownscaledFile <-
    myEnv$getDownscaledFilenameFor(outDirs$downscaled,
                                   "downscaled",
                                   extent$shortName,
                                   modis.yyyymmdd,
                                   version=opt$modelVersion)

outProbBtwnFile <-
    myEnv$getDownscaledFilenameFor(outDirs$prob.btwn,
                                   "prob.btwn",
                                   extent$shortName,
                                   modis.yyyymmdd,
                                   version=opt$modelVersion)

outProbHundredFile <-
    myEnv$getDownscaledFilenameFor(outDirs$prob.hundred,
                                   "prob.hundred",
                                   extent$shortName,
                                   modis.yyyymmdd,
                                   version=opt$modelVersion)

if (!opt$forceOverwrite) {
    if (file.exists(outRegressionFile)
        && file.exists(outDownscaledFile)
        && file.exists(outProbBtwnFile)
        && file.exists(outProbHundredFile)) {

        print(
            sprintf(
                "%s: Skipping downscaling for %s, output files already exist.\n",
                Sys.time(), modis.yyyymmdd))
        quit(status=0)
    }
} else {
    print(sprintf("%s: forceOverwrite=TRUE for %s\n", Sys.time(), modis.yyyymmdd))
}

## if working with MODIS v3 or higher, read in at highRes dimensions
## and do not resize 
if (3 <= opt$modisVersion) {

    ## Note that rows/cols are transposed because R's matrix and raster
    ## packages don't define them the same way
    print(paste0(Sys.time(), ": reading MODIS file at highRes"))
    MOD.big <- t(matrix(values(raster(modis.sc.file.name)),
                        nc=extent$highResRows,
                        nr=extent$highResCols))

} else {
    
    print(paste0(Sys.time(), ": reading MODIS file at lowRes and resampling."))
    mod <- t(matrix(values(raster(modis.sc.file.name)),
                    nc=extent$lowResRows,
                    nr=extent$lowResCols))

    ## format MODIS into a matrix the size of the final downscaled images
    MOD.big <- array(dim=c(extent$highResRows, extent$highResCols)) 
    for(k in 1:dim(mod)[1]){
        for(ell in 1:dim(mod)[2]){
            MOD.big[(16*k-15):(16*k),(16*ell-15):(16*ell)] <- mod[k,ell]
        }
    }
    rm(mod)

}
	
daydat$mod <- MOD.big[-theseNA]

## The model is only defined for 365 days of year, so
## for days in leap years after the leap day, subtract 1 day
daydat$da <- opt$dayOfYear
if (myEnv$isPostLeapDay(opt$year, opt$dayOfYear)) {
    daydat$da <- daydat$da - 1
}

rm(MOD.big)
gc()

print(sprintf("Using model information for year=%d, (model) doy=%d",
              opt$year, daydat$da[1]))

##
## First step of downscaling: classification
##

# Load fitted classification and regression forests
classifierFile <- myEnv$getModelFilenameFor("classifier", version=opt$modelVersion)
print(paste0(Sys.time(), ": loading classifierFile: ", classifierFile))
load(classifierFile)

print(paste0(Sys.time(), ": starting classification..."))

for(s in 1:(length(splits)-1)){
  these <- splits[s]:splits[s+1]
  ## tops out at ~112G on Blanca
  ## ranger.temp <- predict(ranger.classifier,data=daydat[these,], num.threads=128) 
  ranger.temp <- predict(ranger.classifier,
                         data=daydat[these,],
                         num.trees=opt$numTrees)
  # 90g RES (92/93g VIRT) with num.trees=50 without regression tree loaded for s=1
  # 92/96g (RES/VIRT) for s=2
  class.predictions <- colnames(ranger.temp$predictions)[max.col(ranger.temp$predictions,"first")]
  classes[these][class.predictions == "zero"] <- as.integer(0)
  classes[these][class.predictions == "btwn"] <- as.integer(1)
  classes[these][class.predictions == "hundred"] <- as.integer(2)

  prob.btwn[these] <- as.integer(round(100 * ranger.temp$predictions[,1]))
  prob.hundred[these] <- as.integer(round(100 * ranger.temp$predictions[,2]))
  rm(these, ranger.temp, class.predictions)
  gc()
  print(paste0(Sys.time(), ": done with split=", s))
}

print(paste0(Sys.time(), ": classification done"))

rm(ranger.classifier)
gc()

##
## Second step of downscaling: regression for values in (0,100)
##

# Load fitted classification and regression forests
regressionFile <- myEnv$getModelFilenameFor("regression", version=opt$modelVersion)
print(paste0(Sys.time(), ": loading regressionFile: ", regressionFile))
load(regressionFile)

print(paste0(Sys.time(), ": starting regression"))

for(s in 1:(length(splits)-1)){
  these <- splits[s]:splits[s+1]
  ##ranger.temp <- predict(ranger.regression,data=daydat[these,],num.threads=128)
  ## tops out between 60-70Gb for 100 trees
  ranger.temp <- predict(ranger.regression,
                         data=daydat[these,]) 
  regressionvalues[these] <- ranger.temp$predictions
  print(paste0(Sys.time(), ": done with split=", s))
}

print(paste0(Sys.time(), ": regression done"))

rm(these, ranger.temp)
rm(ranger.regression)
gc()

##
## Save out
##
print(paste0(Sys.time(), ": saving rasters..."))

## FIXME: move the extent shortname "SSN" to the Env class, since
## it is related to the HiRes/LowRes dimensions.  Then build the
## output file names here using whatever that name is.

# regression values
downscaled[-theseNA] <- as.integer(round(regressionvalues)) 	    
values(pred.rast) <- c(t(matrix(downscaled,
                                nr=extent$highResRows,
                                nc=extent$highResCols)))
writeRaster(pred.rast,
            filename=outRegressionFile,
            format="GTiff",
            option="COMPRESS=LZW",
            datatype="INT1U",
            overwrite=TRUE)
print(paste(Sys.time(), ": regression saved to: ", outRegressionFile))

# fully downscaled image
downscaled[-theseNA][classes == 0] <- as.integer(0)
downscaled[-theseNA][classes == 2] <- as.integer(100)
values(pred.rast) <- c(t(matrix(downscaled,
                                nr=extent$highResRows,
                                nc=extent$highResCols)))
writeRaster(pred.rast,
            filename=outDownscaledFile,
            format="GTiff",
            option="COMPRESS=LZW",
            datatype="INT1U",
            overwrite=TRUE)
print(paste(Sys.time(), ": full downscaled saved to: ", outDownscaledFile))

# probabilities of (0,100)
downscaled[-theseNA] <- prob.btwn
values(pred.rast) <- c(t(matrix(downscaled,
                                nr=extent$highResRows,
                                nc=extent$highResCols)))
writeRaster(pred.rast,
            filename=outProbBtwnFile,
            format="GTiff",
            option="COMPRESS=LZW",
            datatype="INT1U",
            overwrite=TRUE)
print(paste(Sys.time(), ": prob of (0,100) saved to:", outProbBtwnFile))

# probabilities of 100% [we can get P(0) = 1 - P(100) - P((0,100))]
downscaled[-theseNA] <- prob.hundred
values(pred.rast) <- c(t(matrix(downscaled,
                                nr=extent$highResRows,
                                nc=extent$highResCols)))
writeRaster(pred.rast,
            filename=outProbHundredFile,
            format="GTiff",
            option="COMPRESS=LZW",
            datatype="INT1U",
            overwrite=TRUE)
print(paste(Sys.time(), ": prob of 100 saved to:", outProbHundredFile))

quit(status=0)

