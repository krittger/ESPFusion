#!/usr/bin/env Rscript
library(raster)
library(ranger)

suppressPackageStartupMessages(require(optparse))

### Get default environment
myEnv <- ESPFusion::Env()

### Parse inputs
option_list = list(
    make_option(c("-i", "--dayIndex"), type="integer",
                default=1,
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

parser <- OptionParser(usage = "%prog [options]", option_list=option_list);
opt <- parse_args(parser);

print(paste(Sys.time(), ": Begin"))

##
## Setup for downscaling
##
load(myEnv$setupFile)

### Make output directories if needed
outDirs <- ESPFusion::PrepOutDirs(opt$outDir, train.size)

classes <- rep(NA, dim(daydat)[1])
regressionvalues <- rep(NA, dim(daydat)[1])
prob.btwn <- rep(NA, dim(daydat)[1])
prob.hundred <- rep(NA, dim(daydat)[1])
downscaled <- rep(NA, times=myEnv$SSN30mCols * myEnv$SSN30mRows)

### For classification, done in chunks,
### avoids memory issues when trying to do all points simultaneously
splits <- seq(1, dim(daydat)[1], by=1e6)
splits <- c(splits, dim(daydat)[1])

## Grab a landsat raster to initialize output sizing
landsat.file.names <- list.files(myEnv$landsatDir)
landsat.sc.file.names <- landsat.file.names[grepl(".snow_cover_percent.",
                                                  landsat.file.names,
                                                  fixed=TRUE)]

pred.rast <- raster(file.path(myEnv$landsatDir, tail(landsat.sc.file.names)[1]))

##
## Do downscaling test
##

## Setup
day <- opt$dayIndex
print(paste0("Processing MODIS file: ", modis.sc.file.names[day]))

## FIXME: why are rows/columns transposed?
## Is this something with Matlab/R?
mod <- t(matrix(values(raster(file.path(modis.path, modis.sc.file.names[day]))),
                nc=myEnv$SSN500mRows,
                nr=myEnv$SSN500mCols))

## format MODIS into a matrix the size of the final downscaled images
## Consider adding factor to Env variables
MOD.big <- array(dim=c(myEnv$SSN30mRows, myEnv$SSN30mCols)) 
for(k in 1:dim(mod)[1]){
    for(ell in 1:dim(mod)[2]){
        MOD.big[(16*k-15):(16*k),(16*ell-15):(16*ell)] <- mod[k,ell]
    }
}
	
MOD.big <- MOD.big[-theseNA]

daydat$da <- mod.da[day]
daydat$mod <- MOD.big
rm(MOD.big, mod)
gc()

##
## First step of downscaling: classification
##


# Load fitted classification and regression forests
classifierFile <- paste0(Rdata_path,
                         "forest/twostep/classification/ranger.classifier.prob",
                         as.character(train.size),
                         ".Rda")
print(paste0(Sys.time(), ": loading classifierFile: ", classifierFile))
load(classifierFile)

print(paste0(Sys.time(), ": starting classification"))

for(s in 1:(length(splits)-1)){
  these <- splits[s]:splits[s+1]
  ## tops out at ~112G on Blanca
  ## ranger.temp <- predict(ranger.classifier,data=daydat[these,], num.threads=128) 
  ranger.temp <- predict(ranger.classifier,data=daydat[these,], num.trees=opt$numTrees)
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
regressionFile <- paste0(Rdata_path,
                         "forest/twostep/regression/ranger.regression.prob",
                         as.character(train.size),
                         ".Rda")
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

rm(these,ranger.temp)
rm(ranger.regression)
gc()

##
## Save out
##

print(paste0(Sys.time(), ": saving rasters..."))

# regression values
downscaled[-theseNA] <- as.integer(round(regressionvalues)) 	    
values(pred.rast) <- c(t(matrix(downscaled,
                                nr=myEnv$SSN30mRows,
                                nc=myEnv$SSN30mCols)))
outFile <- file.path(outDirs$regression,
                     sprintf("SSN.downscaled.regression.%s.v3.%s.tif",
                             format(mod.date[day],"%Y%m%d"),
                             as.character(train.size)))
writeRaster(pred.rast,
            filename=outFile,
            format="GTiff",
            option="COMPRESS=LZW",
            datatype="INT1U",
            overwrite=TRUE)
print(paste(Sys.time(), ": regression saved to: ", outFile))

# fully downscaled image
downscaled[-theseNA][classes == 0] <- as.integer(0)
downscaled[-theseNA][classes == 2] <- as.integer(100)
values(pred.rast) <- c(t(matrix(downscaled,
                                nr=myEnv$SSN30mRows,
                                nc=myEnv$SSN30mCols)))
outFile <- file.path(outDirs$downscaled,
                     sprintf("SSN.downscaled.%s.v3.%s.tif",
                             format(mod.date[day],"%Y%m%d"),
                             as.character(train.size)))
writeRaster(pred.rast,
            filename=outFile,
            format="GTiff",
            option="COMPRESS=LZW",
            datatype="INT1U",
            overwrite=TRUE)
print(paste(Sys.time(), ": full downscaled saved to: ", outFile))

# probabilities of (0,100)
downscaled[-theseNA] <- prob.btwn
values(pred.rast) <- c(t(matrix(downscaled,
                                nr=myEnv$SSN30mRows,
                                nc=myEnv$SSN30mCols)))
outFile <- file.path(outDirs$prob.btwn,
                     sprintf("SSN.downscaled.prob.0.100.%s.v3.%s.tif",
                             format(mod.date[day], "%Y%m%d"),
                             as.character(train.size)))
writeRaster(pred.rast,
            filename=outFile,
            format="GTiff",
            option="COMPRESS=LZW",
            datatype="INT1U",
            overwrite=TRUE)
print(paste(Sys.time(), ": prob of (0,100) saved to:", outFile))

# probabilities of 100% [we can get P(0) = 1 - P(100) - P((0,100))]
downscaled[-theseNA] <- prob.hundred
values(pred.rast) <- c(t(matrix(downscaled,
                                nr=myEnv$SSN30mRows,
                                nc=myEnv$SSN30mCols)))
outFile <- file.path(outDirs$prob.hundred,
                     sprintf("SSN.downscaled.prob.100.%s.v3.%s.tif",
                             format(mod.date[day], "%Y%m%d"),
                             as.character(train.size)))
writeRaster(pred.rast,
            filename=outFile,
            format="GTiff",
            option="COMPRESS=LZW",
            datatype="INT1U",
            overwrite=TRUE)
print(paste(Sys.time(), ": prob of 100 saved to:", outFile))

quit(status=0)

