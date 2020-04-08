#specify the number of points to be randomly sampled from the good indices each day. 
train.size <- 3e5

library(fields)
library(raster)
library(ranger)
# .libPaths() on Blanca
#"/home/pakl4363/R/x86_64-pc-linux-gnu-library/3.5"
#"/curc/sw/R/3.5.0/lib64/R/library" 


## List data files and set up region bounds
modis.path <- "/pl/active/SierraBighorn/scag/MODIS/SSN/v01/"
clear.landsat.path <- "/pl/active/SierraBighorn/scag/Landsat/UCSB_v3_processing/SSN/v01/"
cloudy.landsat.path <- "/pl/active/SierraBighorn/scag/Landsat/UCSB_v3_processing/SSN_cloudy/v01/"
Rdata_path <- "/pl/active/SierraBighorn/Rdata/"

source(paste0(Rdata_path,"SCAcompare.R"))

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
rm(these,mod.yr)

mod.da <- mod.da + 1
nday <- length(mod.da)




for(day in 1:nday){ 
	
	print(day)
		
	if(cloudy.days[day]) {
		landsat.path <- cloudy.landsat.path
	} else {
		landsat.path <- clear.landsat.path
	}
	

	pred.rast <- raster(paste0("/pl/active/SierraBighorn/downscaledv3/downscaled/",as.character(train.size),"/SSN.downscaled.",     format(mod.date[day],"%Y%m%d"),".v3.tif"))
	pred.mat <- t(matrix(values(pred.rast),nc=14752,nr=9712))
	
	mod.rast <- raster(paste0(modis.path, modis.sc.file.names[day]))

	LST.rast <- raster(paste0(landsat.path,landsat.sc.file.names[day]))
	vLST <- values(LST.rast)
	vLST[vLST==255] <- NA
	LST.mat  <- t(matrix(vLST,nc= 14752,nr= 9712))
	values(LST.rast) <- LST.mat
	
		
	sat.mask <- t(matrix(values(raster(paste0(landsat.path,sat.mask.file.names[day]))),nc= 14752,nr= 9712))
	

	# prob.btwn.rast <- raster(paste0("/pl/active/SierraBighorn/downscaledv3/prob.btwn/",as.character(train.size),"/SSN.downscaled.",     format(mod.date[day],"%Y%m%d"),".v3.tif"))
	# prob.btwn.mat <- t(matrix(values(prob.btwn.rast),nc=14752,nr=9712))
	
	# prob.hundred.rast <- raster(paste0("/pl/active/SierraBighorn/downscaledv3/prob.hundred/",as.character(train.size),"/SSN.downscaled.",     format(mod.date[day],"%Y%m%d"),".v3.tif"))
	# prob.hundred.mat <- t(matrix(values(prob.btwn.rast),nc=14752,nr=9712))
	
		
	# regression.rast <- raster(paste0("/pl/active/SierraBighorn/downscaledv3/regression/",as.character(train.size),"/SSN.downscaled.",     format(mod.date[day],"%Y%m%d"),".v3.tif"))
	# regression.mat <- t(matrix(values(regression.rast),nc=14752,nr=9712))
	
	# png(paste0("/pl/active/SierraBighorn/downscaledv3/pix/",as.character(train.size),"/rasterpix/SSN.downscaled.",     format(mod.date[day],"%Y%m%d"),".png"),width=700,height=600)
	# par(mfrow=c(2,3))
	# plot(mod.rast, main=paste0("MODIS fSCA ",format(mod.date[day],"%Y%m%d")))
	# plot(pred.rast, main=paste0("Downscaled fSCA ",format(mod.date[day],"%Y%m%d")))
	# plot(LST.rast, main=paste0("Landsat fSCA ",format(mod.date[day],"%Y%m%d")))
	# plot(prob.btwn.rast, main=paste0("Probability (0,100)% fSCA ",format(mod.date[day],"%Y%m%d")))
	# plot(prob.hundred.rast, main=paste0("Probability 100% fSCA ",format(mod.date[day],"%Y%m%d")))
	# plot(regression.rast, main=paste0("Regression fSCA ",format(mod.date[day],"%Y%m%d")))
	# dev.off()
	
	
	myC <- pred.mat/100
	myT <- LST.mat/100
	rm(pred.mat,LST.mat)
	
	subset.these <- (!is.na(myC) & !is.na(myT) & sat.mask!=1)
	myC <- myC[subset.these]
	myT <- myT[subset.these]
	
	scastats0<- unlist(SCAcompare(myC,myT,thresh=0))
	scastats15 <- unlist(SCAcompare(myC,myT,thresh=.15))
	
	write.table(scastats0,file=paste0(Rdata_path,"SCA/",as.character(train.size),"/0thresh.",format(mod.date[day],"%Y%m%d"),".csv"),row.names=FALSE,col.names=TRUE)	
	write.table(scastats15,file=paste0(Rdata_path,"SCA/",as.character(train.size),"/15thresh.",format(mod.date[day],"%Y%m%d"),".csv"),row.names=FALSE,col.names=TRUE)

		
}



sumstatnames <- c("precision", "recall", "specificity","F statistic","accuracy","mean difference","median difference","RMSE",
"mean difference (conditional)", "median difference (conditional)", "RMSE (conditional)",
"mean difference (conditional)", "median difference (conditional)", "RMSE (conditional)"  )


#to be run after all tables are saved

all_files <- list.files(paste0(Rdata_path,"SCA/",as.character(train.size)), pattern = "*.csv",full.names = TRUE,recursive=TRUE)

files.thresh0 <-  all_files[grepl("0thresh", all_files)]
files.thresh15 <- all_files[grepl("15thresh", all_files)]

scastats0 <- matrix(NA,ncol=170,nrow=14)
scastats15 <- matrix(NA,ncol=170,nrow=14)


for(day in 1:170){
	
	
	
	scastats0[,day] <- unlist(read.table(files.thresh0[day],header=TRUE))
	scastats15[,day] <- unlist(read.table(files.thresh15[day],header=TRUE))
	
}





mean.summary.0vs15 <- cbind(apply(scastats0,1,mean), apply(scastats15,1,mean))
colnames(mean.summary.0vs15) <- c("0 thresh", "15 thresh")
rownames(mean.summary.0vs15) <- sumstatnames
print(mean.summary.0vs15)


png(paste0("/pl/active/SierraBighorn/downscaledv3/pix/",as.character(train.size),"/statpix/SSN.downscaled.", as.character(train.size),".png"),width=1300,height=600)
par(mfrow=c(2,4))
plot(mod.da,scastats0[1,],main=paste0(sumstatnames[1]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[2,],main=paste0(sumstatnames[2]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[3,],main=paste0(sumstatnames[3]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[4,],main=paste0(sumstatnames[4]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[5,],main=paste0(sumstatnames[5]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[6,],main=paste0(sumstatnames[6]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[7,],main=paste0(sumstatnames[7]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[8,],main=paste0(sumstatnames[8]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
dev.off()




png(paste0("/pl/active/SierraBighorn/downscaledv3/pix/",as.character(train.size),"/statpix/SSN.downscaled.condTsnow", as.character(train.size),".png"),width=1300,height=400)
par(mfrow=c(1,3))
plot(mod.da,scastats0[9,],main=paste0(sumstatnames[9]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[10,],main=paste0(sumstatnames[10]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[11,],main=paste0(sumstatnames[11]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
dev.off()

png(paste0("/pl/active/SierraBighorn/downscaledv3/pix/",as.character(train.size),"/statpix/SSN.downscaled.condCTsnow", as.character(train.size),".png"),width=1300,height=400)
par(mfrow=c(1,3))
plot(mod.da,scastats0[12,],main=paste0(sumstatnames[12]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[13,],main=paste0(sumstatnames[13]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da,scastats0[14,],main=paste0(sumstatnames[14]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
dev.off()






#variable importtance


class.imp <- importance(ranger.classifier)
reg.imp <- importance(ranger.regression)

names.imp <- names(class.imp)
names.imp[1] <- "day"
names.imp[2] <- "elevation"
names.imp[4] <- "aspect"
names.imp[5] <- "land type"
names.imp[6] <- "MODIS"
names.imp[7] <- "longitude"
names.imp[8] <- "latitude"
names.imp[9] <- "forest height"
names.imp[10] <- "NW barrier distance"
names.imp[11] <- "SW barrier distance"
names.imp[12] <- "W barrier distance"
names.imp[13] <- "SW water distance"
names.imp[14] <- "W water distance"
names.imp[15] <- "wind speed"


names(class.imp) <- names.imp
names(reg.imp) <- names.imp

class.imp <- sort(class.imp)
reg.imp <- sort(reg.imp)


png(paste0("/pl/active/SierraBighorn/downscaledv3/pix/",as.character(train.size),"/importance.png"),width=2000,height=800)
par(mfrow=c(1,2),mai=c(1,4,1,1))
barplot(class.imp/1e6,xlab='Importance (scaled)',las=1,cex.lab=2.5, cex.axis=2, cex.names=2.5,horiz=TRUE)
barplot(reg.imp/1e8,xlab='Importance (scaled)',las=1,cex.lab=2.5, cex.axis=2, cex.names=2.5,horiz=TRUE)
dev.off()



