#specify the number of points to be randomly sampled from the good indices each day. 
train.size <- 3e5


library(fields)
library(raster)
library(ranger)


## List data files and set up region bounds
### modis.path needs to be updated to include v02 *and* use all years within .../v02/year#/
modis.path <- "/pl/active/SierraBighorn/scag/MODIS/SSN/v03/"
### these are hardcoded and probably shouldn't be
clear.landsat.path <- "/pl/active/SierraBighorn/scag/Landsat/UCSB_v3_processing/SSN/v01/"
cloudy.landsat.path <- "/pl/active/SierraBighorn/scag/Landsat/UCSB_v3_processing/SSN_cloudy/v01/"
Rdata_path <- "/pl/active/SierraBighorn/Rdata/"
### through here

### note that this uses only a single modis path here, so with new directory structure needs to be changed
modis.file.names <- list.files(modis.path,recursive = TRUE)

#### file names does not have viewable in v02
modis.sc.file.names <- modis.file.names[!grepl("viewable",modis.file.names)]
### through here

clear.landsat.file.names <- list.files(clear.landsat.path)
clear.sat.mask.file.names <- clear.landsat.file.names[grepl("saturation_mask",clear.landsat.file.names)]
clear.landsat.sc.file.names <- clear.landsat.file.names[grepl("snow_cover",clear.landsat.file.names)]
clear.landsat.sc.file.names <- clear.landsat.sc.file.names[!grepl("viewable",clear.landsat.sc.file.names)]


cloudy.landsat.file.names <- list.files(cloudy.landsat.path)
cloudy.landsat.file.names <- cloudy.landsat.file.names[grepl("ProbCM",cloudy.landsat.file.names)]
cloudy.sat.mask.file.names <- cloudy.landsat.file.names[grepl("saturation_mask",cloudy.landsat.file.names)]

cloudy.landsat.sc.file.names <- cloudy.landsat.file.names[grepl("snow_cover",cloudy.landsat.file.names)]
cloudy.landsat.sc.file.names <- cloudy.landsat.sc.file.names[!grepl("viewable",cloudy.landsat.sc.file.names)]

landsat.sc.file.names <- c(clear.landsat.sc.file.names,cloudy.landsat.sc.file.names)
sat.mask.file.names <- c(clear.sat.mask.file.names,cloudy.sat.mask.file.names)

rm(clear.landsat.file.names, cloudy.landsat.file.names, cloudy.sat.mask.file.names,clear.sat.mask.file.names, modis.file.names)

## Get dates
### CHECK: make sure the substr on the new modis.sc.file.names actually grabs yyyymmdd
####changed start and end to reflect date position
mod.date <- lst.date <- cloudy.lst.date <- NULL
for(i in 1:length(modis.sc.file.names)){
	mod.date[i] <- regmatches(modis.sc.file.names[i], regexpr("\\d{4}\\d{2}\\d{2}",modis.sc.file.names[i]))
	}
for(i in 1:length(landsat.sc.file.names)){
	lst.date[i] <- regmatches(landsat.sc.file.names[i], regexpr("\\d{4}\\d{2}\\d{2}",landsat.sc.file.names[i]))
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

cloudy.days <- grepl("ProbCM",landsat.sc.file.names)


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

out <- raster("/pl/active/SierraBighorn/predictors/SouthernSierraNevada_Elevation.tif")
elev <- t(matrix(values(out),nc=14752,nr=9712))
elev[elev < (-100)] <- NA
rm(out)

out <- raster("/pl/active/SierraBighorn/predictors/SouthernSierraNevada_Slope.tif")
slope <- t(matrix(values(out),nc=14752,nr=9712))
slope[slope < 0] <- NA
rm(out)

out <- raster("/pl/active/SierraBighorn/predictors/SouthernSierraNevada_Aspect.tif")
asp <- t(matrix(values(out),nc=14752,nr=9712))
asp[asp < (-2)] <- NA
rm(out)

out <- raster("/pl/active/SierraBighorn/predictors/SouthernSierraNevada_LandClassNLCD.tif")
lty <- t(matrix(values(out),nc=14752,nr=9712))
rm(out)

out <- raster("/pl/active/SierraBighorn/landcover/LandFireEVH_ucsb/SSN.LandFireEVH_SN30m_height_m.v01.tif")
forest.height <- t(matrix(values(out),nc=14752,nr=9712))
rm(out)

out <- raster("/pl/active/SierraBighorn/predictors/SouthernSierraNevada_NorthWestBarrierDistance.tif")
nw.barrierdist <- t(matrix(values(out),nc=14752,nr=9712))
rm(out)

out <- raster("/pl/active/SierraBighorn/predictors/SouthernSierraNevada_SouthWestBarrierDistance.tif")
sw.barrierdist <- t(matrix(values(out),nc=14752,nr=9712))
rm(out)

out <- raster("/pl/active/SierraBighorn/predictors/SouthernSierraNevada_WestBarrierDistance.tif")
w.barrierdist <- t(matrix(values(out),nc=14752,nr=9712))
rm(out)

out <- raster("/pl/active/SierraBighorn/predictors/SouthernSierraNevada_SouthWestDistanceToWater.tif")
sw.waterdist <- t(matrix(values(out),nc=14752,nr=9712))
rm(out)

out <- raster("/pl/active/SierraBighorn/predictors/SouthernSierraNevada_WestDistanceToWater.tif")
w.waterdist <- t(matrix(values(out),nc=14752,nr=9712))
rm(out)

out <- raster("/pl/active/SierraBighorn/predictors/downscaled_s_sierra_winds_dec_april_climatology_nldas2.tif")
windspeed <- t(matrix(values(out),nc=14752,nr=9712))
rm(out)


locs <- expand.grid(x=1:9712,y=1:14752) #expand.grid(x=seq(from=129187.3,by=30,length.out= 9712), y=seq(from=3918807,by=30,length.out= 14752))
locs.x <-  t(matrix(locs[,1],nc= 14752,nr= 9712))
locs.y <-  t(matrix(locs[,2],nc= 14752,nr= 9712))
locs <- cbind(c(locs.x),rev(locs.y))/14752


smalllocs <- expand.grid(x=1:607,y=1:922) #expand.grid(x=seq(from=129187.3,to= 420517.3,length.out= 607), y=seq(from=3918807,to= 4361337,length.out= 922))
smalllocs.x <-  t(matrix(smalllocs[,1],nc= 922,nr= 607))
smalllocs.y <-  t(matrix(smalllocs[,2],nc= 922,nr= 607))
smalllocs <- cbind(c(smalllocs.x),rev(smalllocs.y))/922

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
	

	
	if(cloudy.days[day]) {
		landsat.path <- cloudy.landsat.path
	} else {
		landsat.path <- clear.landsat.path
	}
	
	LST  <- t(matrix(values(raster(paste0(landsat.path,landsat.sc.file.names[day]))),nc= 14752,nr= 9712))
	LST.NA <- which(LST==255)
	
	sat.mask <- t(matrix(values(raster(paste0(landsat.path,sat.mask.file.names[day]))),nc= 14752,nr= 9712))
	LST.sat <- which(sat.mask==1)
	rm(sat.mask)
	
	these.good.day <- (1:(14752*9712))[-c(LST.sat,LST.NA,feature.NA)]
	train.indices.day <- sample(these.good.day,train.size)
	
	train.LST[[day]] <- LST[train.indices.day]
	rm(LST)
### might need to be careful here since this only calls a single modis.path	
####added year inside path
	MOD.big <- t(matrix(values(raster(paste0(modis.path, modis.sc.file.names[day]))),nc=14752,nr=9712))
###

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

### I think this is unnecessary
train.da.nNA <- unlist(lapply(train.LST,length))
sum(train.da.nNA)/1e6 # how many millions of data points you grabbed
### to here
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



##
## Growing and saving the classification forest
##

print(Sys.time())
ranger.classifier <- ranger(class~ da+elev+slope+asp+lty+mod+lon+lat+ forest.height+ nw.barrierdist+ sw.barrierdist+ w.barrierdist+ sw.waterdist+ w.waterdist + windspeed,data=train.dat,num.trees=100,probability=TRUE) #,importance='impurity_corrected')
print(Sys.time())

print(object.size(ranger.classifier),units="GB")
ranger.classifier$prediction.error

### Need to change the filename to reflect v02
print(Sys.time())
save(ranger.classifier,file=paste0(Rdata_path,"forest/ranger.classifier.SCA.v03",as.character(train.size),".Rda"))
print(Sys.time())
rm(ranger.classifier)
###

##
## Growing and saving the regression forest
##

print(dim(train.dat[train.dat$class=="btwn",]))

print(Sys.time())
ranger.regression <- ranger(lst ~ da+elev+slope+asp+lty+mod+lon+lat+ forest.height+ nw.barrierdist+ sw.barrierdist+ w.barrierdist+ sw.waterdist+ w.waterdist + windspeed,data=train.dat[train.dat$class=="btwn",],num.trees=100) #,importance='impurity_corrected')
print(Sys.time())

print(object.size(ranger.regression),units="GB")
ranger.regression$prediction.error

### same thing: need to change filename to reflect v02
save(ranger.regression,file=paste0(Rdata_path,"/forest/ranger.regression.SCA.v03",as.character(train.size),".Rda"))
###


