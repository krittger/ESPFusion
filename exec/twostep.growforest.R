#
# 2019 Mitchell L. Krock mitchell.krock@colorado.edu 
# Copyright (C) 2019 Regents of the University of Colorado
#

print(paste0("Begin script:", Sys.time()))

library(fields)
library(raster)
library(ranger)

## Following 3 lines used for live debugging
library(devtools)
proj_path <- paste0("/projects/", Sys.getenv("LOGNAME"), "/ESPFusion")
setwd(proj_path)
devtools::load_all()
myEnv <- ESPFusion::Env()
studyExtent <- ESPFusion::StudyExtent("SouthernSierraNevada")

suppressPackageStartupMessages(require(optparse))

### Parse inputs
option_list = list(
  make_option(c("-i", "--modisVersion"), type="integer",
              default=5,
              help="version of MODIS input data to process [default=%default]",
              metavar="integer"),
  make_option(c("-m", "--modelVersion"), type="integer",
              default=5,
              help="version of model classifier/regresionfiles to use [default=%default]",
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



## FIX ME
## add options as in other files for modis version, etc

## List data files and set up region bounds
modis.sc.file.names <- myEnv$allModisFiles("snow_cover_percent",version=opt$modisVersion)



clear.sat.mask.file.names <- myEnv$allLandsatFiles("saturation_mask",version=1,includeCloudy=FALSE)
clear.landsat.sc.file.names <- myEnv$allLandsatFiles("snow_cover_percent",version=1,includeCloudy=FALSE)

cloudy.sat.mask.file.names <- myEnv$allLandsatFiles("saturation_mask.ProbCM",version=1,includeCloudy=TRUE)
cloudy.landsat.sc.file.names <- myEnv$allLandsatFiles("snow_cover_percent.ProbCM",version=1,includeCloudy=TRUE)

landsat.sc.file.names <- c(clear.landsat.sc.file.names,cloudy.landsat.sc.file.names)
sat.mask.file.names <- c(clear.sat.mask.file.names,cloudy.sat.mask.file.names)

rm(cloudy.sat.mask.file.names,clear.sat.mask.file.names)

## Get dates
mod.date <- lst.date <- cloudy.lst.date <- NULL
for(i in 1:length(modis.sc.file.names)){
	mod.date[i] <- regmatches(modis.sc.file.names[i], regexpr("\\d{8}",modis.sc.file.names[i]))
	}
for(i in 1:length(landsat.sc.file.names)){
	lst.date[i] <- regmatches(landsat.sc.file.names[i], regexpr("\\d{8}",landsat.sc.file.names[i]))
	}

mod.date <- as.integer(mod.date)
lst.date <- as.integer(lst.date)
sort.indices <- sort(lst.date,index.return=TRUE)


landsat.sc.file.names <- landsat.sc.file.names[sort.indices$ix]
sat.mask.file.names <- sat.mask.file.names[sort.indices$ix]
lst.date <- lst.date[sort.indices$ix]

##
## Set up day of year variables and remove leap days
##

mod.date <- strptime(x=as.character(mod.date),format="%Y%m%d")
lst.date <- strptime(x=as.character(lst.date),format="%Y%m%d")

out <- format(mod.date,"%Y%m%d") %in% format(lst.date,"%Y%m%d")
modis.sc.file.names <- modis.sc.file.names[out]
mod.date <- mod.date[out]


out <- format(lst.date,"%Y%m%d") %in% format(mod.date,"%Y%m%d")
landsat.sc.file.names <- landsat.sc.file.names[out]
sat.mask.file.names <- sat.mask.file.names[out]
lst.date <- lst.date[out]
rm(out)

## Not necessary after censoring only dates on which both LST and MOD are available
## Remove leap days
#these <- which(format(mod.date,"%m%d")=="0229")
#mod.date <- mod.date[-these]
#MOD <- MOD[,,-these]
#rm(these)



## Fix count for leap years for every day past Feb 29 = day 59 of year
mod.da <- mod.date$yday
mod.yr <- as.integer(format(mod.date,"%Y"))

these <- ((mod.yr %% 4) == 0) & (mod.da >= 59)
mod.da[these] <- mod.da[these] - 1
#### using mod.yr later for path definition
rm(these,mod.yr)

mod.da <- mod.da + 1
nday <- length(mod.da)



##
## Load and organize feature data
##

out <- raster("/pl/active/rittger_esp/SierraBighorn/predictors/SouthernSierraNevada_Elevation.tif")
elev <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
elev[elev < (-100)] <- NA
rm(out)

out <- raster("/pl/active/rittger_esp/SierraBighorn/predictors/SouthernSierraNevada_Slope.tif")
slope <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
slope[slope < 0] <- NA
rm(out)

out <- raster("/pl/active/rittger_esp/SierraBighorn/predictors/SouthernSierraNevada_Aspect.tif")
asp <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
asp[asp < (-2)] <- NA
rm(out)

out <- raster("/pl/active/rittger_esp/SierraBighorn/predictors/SouthernSierraNevada_LandClassNLCD.tif")
lty <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
rm(out)

out <- raster("/pl/active/rittger_esp/SierraBighorn/landcover/LandFireEVH_ucsb/SSN.LandFireEVH_SN30m_height_m.v01.tif")
forest.height <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
rm(out)

out <- raster("/pl/active/rittger_esp/SierraBighorn/predictors/SouthernSierraNevada_NorthWestBarrierDistance.tif")
nw.barrierdist <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
rm(out)

out <- raster("/pl/active/rittger_esp/SierraBighorn/predictors/SouthernSierraNevada_SouthWestBarrierDistance.tif")
sw.barrierdist <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
rm(out)

out <- raster("/pl/active/rittger_esp/SierraBighorn/predictors/SouthernSierraNevada_WestBarrierDistance.tif")
w.barrierdist <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
rm(out)

out <- raster("/pl/active/rittger_esp/SierraBighorn/predictors/SouthernSierraNevada_SouthWestDistanceToWater.tif")
sw.waterdist <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
rm(out)

out <- raster("/pl/active/rittger_esp/SierraBighorn/predictors/SouthernSierraNevada_WestDistanceToWater.tif")
w.waterdist <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
rm(out)

out <- raster("/pl/active/rittger_esp/SierraBighorn/predictors/downscaled_s_sierra_winds_dec_april_climatology_nldas2.tif")
windspeed <- t(matrix(values(out),nc=studyExtent$highResRows,nr=studyExtent$highResCols))

rm(out)


locs <- expand.grid(x=1:studyExtent$highResCols,y=1:studyExtent$highResRows) 
locs.x <-  t(matrix(locs[,1],nc= studyExtent$highResRows,nr= studyExtent$highResCols))
locs.y <-  t(matrix(locs[,2],nc= studyExtent$highResRows,nr= studyExtent$highResCols))
locs <- cbind(c(locs.x),rev(locs.y))/studyExtent$highResRows


smalllocs <- expand.grid(x=1:studyExtent$lowResCols,y=1:studyExtent$lowResRows) 
smalllocs.x <-  t(matrix(smalllocs[,1],nc= studyExtent$lowResRows,nr= studyExtent$lowResCols))
smalllocs.y <-  t(matrix(smalllocs[,2],nc= studyExtent$lowResRows,nr= studyExtent$lowResCols))
smalllocs <- cbind(c(smalllocs.x),rev(smalllocs.y))/studyExtent$lowResRows

#plot with quilt.plot(locs,c(elev))

rm(locs.x,locs.y,smalllocs.x,smalllocs.y)

elev <- elev/1000
slope <- slope/90
nw.barrierdist <- nw.barrierdist/1000
sw.barrierdist <- sw.barrierdist/1000
w.barrierdist <- w.barrierdist/1000
sw.waterdist <- sw.waterdist/1000
w.waterdist <- w.waterdist/1000





##
## Grab the training data in a for loop, then make it into a data frame at the end.
##

train.LST <- train.MOD <- train.slope <- train.asp  <- train.elev <- train.lty <- train.lon <- train.lat <- train.nw.barrierdist <- train.sw.barrierdist <- train.w.barrierdist <- train.sw.waterdist <- train.w.waterdist <- train.forest.height <- train.windspeed <- list()

feature.NA <- which(is.na(elev)) 


for(day in 1:nday){ 
	
	LST  <- t(matrix(values(raster(landsat.sc.file.names[day])),nc= studyExtent$highResRows,nr= studyExtent$highResCols))
	LST.NA <- which(LST==255)
	
	sat.mask <- t(matrix(values(raster(sat.mask.file.names[day])),nc= studyExtent$highResRows,nr= studyExtent$highResCols))
	LST.sat <- which(sat.mask==1)
	rm(sat.mask)
	
	these.good.day <- (1:(studyExtent$highResRows*studyExtent$highResCols))[-c(LST.sat,LST.NA,feature.NA)]
	train.indices.day <- sample(these.good.day,myEnv$getTrain.size())
	
	train.LST[[day]] <- LST[train.indices.day]
	rm(LST)

	MOD.big <- t(matrix(values(raster(modis.sc.file.names[day])),nc=studyExtent$highResRows,nr=studyExtent$highResCols))

  train.MOD[[day]] <- MOD.big[train.indices.day]
  rm(MOD.big)

  train.slope[[day]] <- slope[train.indices.day]
  train.asp[[day]] <- asp[train.indices.day]
  train.elev[[day]] <- elev[train.indices.day]
  train.lty[[day]] <- lty[train.indices.day]
  train.lon[[day]] <- locs[,1][train.indices.day]
  train.lat[[day]] <- locs[,2][train.indices.day]
  train.forest.height[[day]] <- forest.height[train.indices.day]
  train.nw.barrierdist[[day]] <- nw.barrierdist[train.indices.day]
  train.sw.barrierdist[[day]] <- sw.barrierdist[train.indices.day]
  train.w.barrierdist[[day]] <- w.barrierdist[train.indices.day]
  train.sw.waterdist[[day]] <- sw.waterdist[train.indices.day]
  train.w.waterdist[[day]] <- w.waterdist[train.indices.day]
  train.windspeed[[day]] <- windspeed[train.indices.day]

	print(paste0("Starting ",mod.date[day]," at ",Sys.time()))
	print(paste0("Day ", day, " of ", nday, ", ", length(train.indices.day), " training indices from ", length(these.good.day), " possible"))
}

train.da.nNA <- unlist(lapply(train.LST,length))

#training data fully constructed here
train.dat <- data.frame(lst=unlist(train.LST),
	da=rep(mod.da,times=train.da.nNA),
	elev=unlist(train.elev),
	slope=unlist(train.slope),
	asp=unlist(train.asp),
	lty=as.factor(unlist(train.lty)),
	mod=unlist(train.MOD),
	lon=unlist(train.lon),
	lat=unlist(train.lat),
	forest.height=as.factor(unlist(train.forest.height)),
	nw.barrierdist=unlist(train.nw.barrierdist),
	sw.barrierdist=unlist(train.sw.barrierdist),
	w.barrierdist=unlist(train.w.barrierdist),
	sw.waterdist=unlist(train.sw.waterdist),
	w.waterdist=unlist(train.w.waterdist),
	windspeed=unlist(train.windspeed))
	
rm(train.LST,train.elev,train.slope,train.asp,train.lty,train.MOD,train.lon,train.lat,
train.forest.height, train.nw.barrierdist, train.sw.barrierdist, train.w.barrierdist, train.sw.waterdist, train.w.waterdist,train.windspeed)


#setting up the classes for classification

vec <- rep("btwn",dim(train.dat)[1])
zero_indices <- which(train.dat$lst==0)
hundred_indices <- which(train.dat$lst==100)

vec[zero_indices] <- "zero"
vec[hundred_indices] <-  "hundred"
train.dat$class <- as.factor(vec)

rm(vec,zero_indices,hundred_indices)



## Create forest directory for classification and regression models
ESPFusion::PrepModelDir(myEnv$getModelDir())

##
## Growing and saving the classification forest
##


print(Sys.time())
ranger.classifier <- ranger(class~ da+elev+slope+asp+lty+mod+lon+lat+ forest.height+ nw.barrierdist+ sw.barrierdist+ w.barrierdist+ sw.waterdist+ w.waterdist + windspeed,data=train.dat,num.trees=100,probability=TRUE) #,importance='impurity_corrected')
print(Sys.time())

print(object.size(ranger.classifier),units="GB")
ranger.classifier$prediction.error

print(Sys.time())
save(ranger.classifier,file=myEnv$getModelFilenameFor("classifier",version=opt$modelVersion))
print(Sys.time())
rm(ranger.classifier)

##
## Growing and saving the regression forest
##

print(dim(train.dat[train.dat$class=="btwn",]))

print(Sys.time())
ranger.regression <- ranger(lst ~ da+elev+slope+asp+lty+mod+lon+lat+ forest.height+ nw.barrierdist+ sw.barrierdist+ w.barrierdist+ sw.waterdist+ w.waterdist + windspeed,data=train.dat[train.dat$class=="btwn",],num.trees=100) #,importance='impurity_corrected')
print(Sys.time())

print(object.size(ranger.regression),units="GB")
ranger.regression$prediction.error

save(ranger.regression,file=myEnv$getModelFilenameFor("regression",version=opt$modelVersion))



print(paste0("End Script:", Sys.time()))
