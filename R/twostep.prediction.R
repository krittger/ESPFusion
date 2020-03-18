#specify the number of points to be randomly sampled from the good indices each day. 
train.size <- 3e5


library(fields)
library(raster)
library(ranger)


## List data files and set up region bounds
modis.path <- "/pl/active/SierraBighorn/scag/MODIS/SSN/v01/"
clear.landsat.path <- "/pl/active/SierraBighorn/scag/Landsat/UCSB_v3_processing/SSN/v01/"
cloudy.landsat.path <- "/pl/active/SierraBighorn/scag/Landsat/UCSB_v3_processing/SSN_cloudy/v01/"
Rdata_path <- "/pl/active/SierraBighorn/Rdata/"

modis.file.names <- list.files(modis.path)
modis.sc.file.names <- modis.file.names[!grepl("viewable",modis.file.names)]

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
mod.date <- lst.date <- cloudy.lst.date <- NULL
for(i in 1:length(modis.sc.file.names)){
	mod.date[i] <- substr(modis.sc.file.names[i],start=15,stop=22)
	}
for(i in 1:length(landsat.sc.file.names)){
	lst.date[i] <- substr(landsat.sc.file.names[i],start=14,stop=21)
	}

mod.date <- as.integer(mod.date)
lst.date <- as.integer(lst.date)
sort.indices <- sort(lst.date,index.return=TRUE)


landsat.sc.file.names <- landsat.sc.file.names[sort.indices$ix]
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


rm(locs.x,locs.y,smalllocs.x,smalllocs.y)

elev <- elev/1000
slope <- slope/90
nw.barrierdist <- nw.barrierdist/1000
sw.barrierdist <- sw.barrierdist/1000
w.barrierdist <- w.barrierdist/1000
sw.waterdist <- sw.waterdist/1000
w.waterdist <- w.waterdist/1000



# Classification and regression forests loaded

print(Sys.time())
load(paste0(Rdata_path,"forest/twostep/classification/ranger.classifier.prob",as.character(train.size),".Rda"))
load(paste0(Rdata_path,"forest/twostep/regression/ranger.regression.prob",as.character(train.size),".Rda"))
print(Sys.time())


#preparing variables for the main for loop

theseNA <- union(which(is.na(elev)),which(is.na(w.barrierdist)))

slope <- slope[-theseNA]
asp <- asp[-theseNA]
elev <- elev[-theseNA]
lty <- lty[-theseNA]
lon <- locs[,1][-theseNA]
lat <- locs[,2][-theseNA]
forest.height <- forest.height[-theseNA]
nw.barrierdist <- nw.barrierdist[-theseNA]
sw.barrierdist <- sw.barrierdist[-theseNA]
w.barrierdist <- w.barrierdist[-theseNA]
sw.waterdist <- sw.waterdist[-theseNA]
w.waterdist <- w.waterdist[-theseNA]
windspeed <- windspeed[-theseNA]

print(Sys.time())
daydat <- data.frame(elev=elev,
  slope=slope,asp=asp,lty=as.factor(lty),lon=lon,lat=lat,
  forest.height=as.factor(forest.height),
  nw.barrierdist=nw.barrierdist,
  sw.barrierdist=sw.barrierdist,
  w.barrierdist=w.barrierdist,
  sw.waterdist=sw.waterdist,
  w.waterdist=w.waterdist,
  windspeed=windspeed)
  print(Sys.time())


rm(slope, asp, elev, lty, lon, lat, forest.height, nw.barrierdist, sw.barrierdist, w.barrierdist, sw.waterdist, w.waterdist, windspeed, locs,  smalllocs)

 classes <- rep(NA,dim(daydat)[1])
 regressionvalues <- rep(NA,dim(daydat)[1])
 prob.btwn <- rep(NA,dim(daydat)[1])
 prob.hundred <- rep(NA,dim(daydat)[1])
 downscaled <- rep(NA,times=9712*14752)

#for classification, done in chunks
  splits <- seq(1,dim(daydat)[1],by=8e6)
  splits <- c(splits,dim(daydat)[1])


for(day in 1:nday){ 
	print(paste0("Starting ",mod.date[day]," at ",Sys.time()))
	
	
	
	if(cloudy.days[day]) {
		landsat.path <- cloudy.landsat.path
	} else {
		landsat.path <- clear.landsat.path
	}
	
	
	mod <- t(matrix(values(raster(paste0(modis.path, modis.sc.file.names[day]))),nc=922,nr=607))

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

  
    print(paste("starting classification",Sys.time()))
  for(s in 1:(length(splits)-1))
  {     these <- splits[s]:splits[s+1]
  	    ranger.temp <- predict(ranger.classifier,data=daydat[these,],num.threads=128)
  	    class.predictions <- colnames(ranger.temp$predictions)[max.col(ranger.temp$predictions,"first")]
  	    classes[these][class.predictions == "zero"] <- as.integer(0)
  	    classes[these][class.predictions == "btwn"] <- as.integer(1)
  	    classes[these][class.predictions == "hundred"] <- as.integer(2)
  	    
  	    prob.btwn[these] <- as.integer(round(100*ranger.temp$predictions[,1]))
  	    prob.hundred[these] <- as.integer(round(100*ranger.temp$predictions[,2]))
  }   
  	  print(paste("classification done",Sys.time()))
  	    	    rm(these,ranger.temp,class.predictions)

  	  
  
  	  
  	    print(paste("starting regression",Sys.time()))
  for(s in 1:(length(splits)-1))
  {     these <- splits[s]:splits[s+1]
  	    ranger.temp <- predict(ranger.regression,data=daydat[these,],num.threads=128)
  	    regressionvalues[these] <- ranger.temp$predictions
   }   
  	  print(paste("regression done",Sys.time()))
  	    	    rm(these,ranger.temp)
  	    	     	    
  	    	     	    
  	    	     	    

	 print(paste("Saving rasters",Sys.time())) 
  	  downscaled[-theseNA] <- as.integer(round(regressionvalues)) 	    
	  pred.rast <- raster(paste0(landsat.path,landsat.sc.file.names[day])) 
	  values(pred.rast) <- c(t(matrix(downscaled,nr=14752,nc=9712)))
  	    	   writeRaster(pred.rast,filename=paste0("/pl/active/SierraBighorn/downscaledv3/regression/",as.character(train.size),"/SSN.downscaled.", format(mod.date[day],"%Y%m%d"),".v3.tif"),     format="GTiff",option="COMPRESS=LZW",datatype="INT1U",overwrite=TRUE)

  	  
  	  downscaled[-theseNA][classes == 0] <- as.integer(0)
  	  downscaled[-theseNA][classes == 2] <- as.integer(100)
  	  values(pred.rast) <- c(t(matrix(downscaled,nr=14752,nc=9712)))
  	   writeRaster(pred.rast,filename=paste0("/pl/active/SierraBighorn/downscaledv3/downscaled/",as.character(train.size),"/SSN.downscaled.", format(mod.date[day],"%Y%m%d"),".v3.tif"),     format="GTiff",option="COMPRESS=LZW",datatype="INT1U",overwrite=TRUE)
  	   
  	   downscaled[-theseNA] <- prob.btwn
  	    values(pred.rast) <- c(t(matrix(downscaled,nr=14752,nc=9712)))
  	    writeRaster(pred.rast,filename=paste0("/pl/active/SierraBighorn/downscaledv3/prob.btwn/",as.character(train.size), "/SSN.downscaled.", format(mod.date[day],"%Y%m%d"),".v3.tif"),     format="GTiff",option="COMPRESS=LZW",datatype="INT1U",overwrite=TRUE)

  	   downscaled[-theseNA] <- prob.hundred
  	    values(pred.rast) <- c(t(matrix(downscaled,nr=14752,nc=9712))) 	     	  
  	    writeRaster(pred.rast,filename=paste0("/pl/active/SierraBighorn/downscaledv3/prob.hundred/", as.character(train.size),"/SSN.downscaled.", format(mod.date[day],"%Y%m%d"),".v3.tif"),     format="GTiff",option="COMPRESS=LZW",datatype="INT1U",overwrite=TRUE)

  	  print(paste("All rasters assigned",Sys.time())) 
  	   	  
  	   rm(pred.rast,predict.ranger)   	
	
}
