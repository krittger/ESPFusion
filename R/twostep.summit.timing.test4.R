
library(raster)
library(ranger)

##
## Setup for downscaling
##

print(Sys.time())

load("/pl/active/SierraBighorn/Rdata/decade.setup.RData")

# Load fitted classification and regression forests
print(Sys.time())
load(paste0(Rdata_path,"forest/twostep/classification/ranger.classifier.prob",as.character(train.size),".Rda"))
load(paste0(Rdata_path,"forest/twostep/regression/ranger.regression.prob",as.character(train.size),".Rda"))
print(Sys.time())

classes <- rep(NA,dim(daydat)[1])
regressionvalues <- rep(NA,dim(daydat)[1])
prob.btwn <- rep(NA,dim(daydat)[1])
prob.hundred <- rep(NA,dim(daydat)[1])
downscaled <- rep(NA,times=9712*14752)

# For classification, done in chunks, run into memory issues when trying to do all points simultaneously
splits <- seq(1,dim(daydat)[1],by=1e6)
splits <- c(splits,dim(daydat)[1])

## Grab a landsat raster to initialize output sizing
landsat.path <- "/pl/active/SierraBighorn/scag/Landsat/UCSB_v3_processing/SSN/v01/"
landsat.file.names <- list.files(landsat.path)
landsat.sc.file.names <- landsat.file.names[grepl(".snow_cover_percent.",landsat.file.names,fixed=TRUE)]

pred.rast <- raster(paste0(landsat.path,tail(landsat.sc.file.names)[1]))

##
## Do downscaling test
##

## Setup
day <- 1850 # 20050123
print(modis.sc.file.names[day])

mod <- t(matrix(values(raster(paste0(modis.path, modis.sc.file.names[day]))),nc=922,nr=607))
# format MODIS into a matrix the size of the final downscaled images
MOD.big <- array(dim=c(14752,9712)) 
for(k in 1:dim(mod)[1]){
  for(ell in 1:dim(mod)[2]){
    MOD.big[(16*k-15):(16*k),(16*ell-15):(16*ell)] <- mod[k,ell]
  }
}
	
MOD.big <- MOD.big[-theseNA]

daydat$da <- mod.da[day]
daydat$mod <- MOD.big
rm(MOD.big,mod)

##
## First step of downscaling: classification
##

print(paste("starting classification",Sys.time()))

for(s in 1:(length(splits)-1)){
  these <- splits[s]:splits[s+1]
  ranger.temp <- predict(ranger.classifier,data=daydat[these,],num.threads=128)
  # numthreads was found to empirically work a bit faster, no real other justification for this #
  class.predictions <- colnames(ranger.temp$predictions)[max.col(ranger.temp$predictions,"first")]
  classes[these][class.predictions == "zero"] <- as.integer(0)
  classes[these][class.predictions == "btwn"] <- as.integer(1)
  classes[these][class.predictions == "hundred"] <- as.integer(2)

  prob.btwn[these] <- as.integer(round(100*ranger.temp$predictions[,1]))
  prob.hundred[these] <- as.integer(round(100*ranger.temp$predictions[,2]))
  print(s)
}   

print(paste("classification done",Sys.time()))

rm(these,ranger.temp,class.predictions)

##
## Second step of downscaling: regression for values in (0,100)
##

print(paste("starting regression",Sys.time()))

for(s in 1:(length(splits)-1)){
  these <- splits[s]:splits[s+1]
  ranger.temp <- predict(ranger.regression,data=daydat[these,],num.threads=128)
  regressionvalues[these] <- ranger.temp$predictions
  print(s)
}

print(paste("regression done",Sys.time()))

rm(these,ranger.temp)

##
## Save out
##

print(paste("Saving rasters",Sys.time()))

# regression values
downscaled[-theseNA] <- as.integer(round(regressionvalues)) 	    
values(pred.rast) <- c(t(matrix(downscaled,nr=14752,nc=9712)))
writeRaster(pred.rast,filename=paste0("/pl/active/SierraBighorn/downscaledv3/regression/",as.character(train.size),"/SSN.downscaled.regression.", format(mod.date[day],"%Y%m%d"),".v3.tif"), format="GTiff",option="COMPRESS=LZW",datatype="INT1U",overwrite=TRUE)

print(paste("regression saved",Sys.time()))

# fully downscaled image
downscaled[-theseNA][classes == 0] <- as.integer(0)
downscaled[-theseNA][classes == 2] <- as.integer(100)
values(pred.rast) <- c(t(matrix(downscaled,nr=14752,nc=9712)))
writeRaster(pred.rast,filename=paste0("/pl/active/SierraBighorn/downscaledv3/downscaled/",as.character(train.size),"/SSN.downscaled.", format(mod.date[day],"%Y%m%d"),".v3.tif"),     format="GTiff",option="COMPRESS=LZW",datatype="INT1U",overwrite=TRUE)

print(paste("full downscaled saved",Sys.time()))

# probabilities of (0,100)
downscaled[-theseNA] <- prob.btwn
values(pred.rast) <- c(t(matrix(downscaled,nr=14752,nc=9712)))
writeRaster(pred.rast,filename=paste0("/pl/active/SierraBighorn/downscaledv3/prob.btwn/",as.character(train.size), "/SSN.downscaled.prob.0.100.", format(mod.date[day],"%Y%m%d"),".v3.tif"),     format="GTiff",option="COMPRESS=LZW",datatype="INT1U",overwrite=TRUE)

print(paste("prob of (0,100) saved",Sys.time()))

# probabilities of 100% [we can get P(0) = 1 - P(100) - P((0,100))]
downscaled[-theseNA] <- prob.hundred
values(pred.rast) <- c(t(matrix(downscaled,nr=14752,nc=9712)))
writeRaster(pred.rast,filename=paste0("/pl/active/SierraBighorn/downscaledv3/prob.hundred/", as.character(train.size),"/SSN.downscaled.prob.100.", format(mod.date[day],"%Y%m%d"),".v3.tif"),     format="GTiff",option="COMPRESS=LZW",datatype="INT1U",overwrite=TRUE)

print(paste("prob of 100 saved",Sys.time()))

