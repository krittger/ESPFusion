#
# 2019 Mitchell L. Krock mitchell.krock@colorado.edu 
# Copyright (C) 2019 Regents of the University of Colorado
#

print(paste0("Begin script:", Sys.time()))

proj_path <- paste0("/projects/", Sys.getenv("LOGNAME"), "/ESPFusion")
setwd(proj_path)

#specify the number of points to be randomly sampled from the good indices each day. 
library(fields)
library(raster)
library(ranger)

## Following 3 lines only for live debugging
library(devtools)

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


## List data files and set up region bounds
modis.sc.file.names <- myEnv$allModisFiles("snow_cover_percent", version=opt$modisVersion)

clear.sat.mask.file.names <- myEnv$allLandsatFiles("saturation_mask", version=1, includeCloudy=FALSE)
clear.landsat.sc.file.names <- myEnv$allLandsatFiles("snow_cover_percent", version=1, includeCloudy=FALSE)

cloudy.sat.mask.file.names <- myEnv$allLandsatFiles("saturation_mask.ProbCM", version=1, includeCloudy=TRUE)
cloudy.landsat.sc.file.names <- myEnv$allLandsatFiles("snow_cover_percent.ProbCM", version=1, includeCloudy=TRUE)

landsat.sc.file.names <- c(clear.landsat.sc.file.names, cloudy.landsat.sc.file.names)
sat.mask.file.names <- c(clear.sat.mask.file.names, cloudy.sat.mask.file.names)

rm(cloudy.sat.mask.file.names, clear.sat.mask.file.names)

## Get dates
mod.date <- lst.date <- cloudy.lst.date <- NULL
for(i in 1:length(modis.sc.file.names)){
  mod.date[i] <- regmatches(modis.sc.file.names[i], regexpr("\\d{8}", modis.sc.file.names[i]))
}
for(i in 1:length(landsat.sc.file.names)){
  lst.date[i] <- regmatches(landsat.sc.file.names[i], regexpr("\\d{8}", landsat.sc.file.names[i]))
}

mod.date <- as.integer(mod.date)
lst.date <- as.integer(lst.date)
sort.indices <- sort(lst.date, index.return=TRUE)


landsat.sc.file.names <- landsat.sc.file.names[sort.indices$ix]
sat.mask.file.names <- sat.mask.file.names[sort.indices$ix]
lst.date <- lst.date[sort.indices$ix]

##
## Set up day of year variables and remove leap days
##

mod.date <- strptime(x=as.character(mod.date), format="%Y%m%d")
lst.date <- strptime(x=as.character(lst.date), format="%Y%m%d")

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

## Create SCA directory if needed, return directory
SCADir <- ESPFusion::PrepSCADir(myEnv$getModelDir(), opt$modisVersion, as.character(myEnv$getTrain.size()))

for(day in 1:nday){ 
	
	print(day)
		
	#if(cloudy.days[day]) {
	#	landsat.path <- cloudy.landsat.path
	#} else {
	#	landsat.path <- clear.landsat.path
	#}
	
  #downscaledFile <- paste0(opt$outDir, "/downscaled/", as.character(myEnv$getTrain.size()), "/", 
  #                         format(mod.date[day],"%Y"), "/SSN.downscaled.", format(mod.date[day],"%Y%m%d"),
  #                         ".v", opt$modisVersion, ".", as.character(myEnv$getTrain.size()),".tif")

  ### Get output directories
  outDirs <- ESPFusion::PrepOutDirs(opt$outDir, myEnv$getTrain.size(), format(mod.date[day],"%Y"))
  
  downscaledFile <- myEnv$getDownscaledFilenameFor(outDirs$downscaled,
                                                   "downscaled",
                                                   studyExtent$shortName,
                                                   format(mod.date[day],"%Y%m%d"),
                                                   version=opt$modelVersion)
  pred.rast <- raster(downscaledFile)
	#pred.rast <- raster(paste0("/scratch/alpine/lost1845/active/SierraBighorn/downscaledv3/downscaled/",as.character(train.size),"/SSN.downscaled.",     format(mod.date[day],"%Y%m%d"),".v3.tif"))
	pred.mat <- t(matrix(values(pred.rast),nc=studyExtent$highResRows,nr=studyExtent$highResCols))
	
	mod.rast <- raster(modis.sc.file.names[day])

	LST.rast <- raster(landsat.sc.file.names[day])
	vLST <- values(LST.rast)
	vLST[vLST==255] <- NA
	LST.mat  <- t(matrix(vLST,nc= studyExtent$highResRows,nr= studyExtent$highResCols))
	values(LST.rast) <- LST.mat
	
		
	sat.mask <- t(matrix(values(raster(sat.mask.file.names[day])),nc= studyExtent$highResRows,nr= studyExtent$highResCols))
	

	# prob.btwn.rast <- raster(paste0("/scratch/alpine/lost1845/active/SierraBighorn/downscaledv3/prob.btwn/",as.character(train.size),"/SSN.downscaled.",     format(mod.date[day],"%Y%m%d"),".v3.tif"))
	# prob.btwn.mat <- t(matrix(values(prob.btwn.rast),nc=14752,nr=9712))
	
	# prob.hundred.rast <- raster(paste0("/scratch/alpine/lost1845/active/SierraBighorn/downscaledv3/prob.hundred/",as.character(train.size),"/SSN.downscaled.",     format(mod.date[day],"%Y%m%d"),".v3.tif"))
	# prob.hundred.mat <- t(matrix(values(prob.btwn.rast),nc=14752,nr=9712))
	
		
	# regression.rast <- raster(paste0("/scratch/alpine/lost1845/active/SierraBighorn/downscaledv3/regression/",as.character(train.size),"/SSN.downscaled.",     format(mod.date[day],"%Y%m%d"),".v3.tif"))
	# regression.mat <- t(matrix(values(regression.rast),nc=14752,nr=9712))
	
	# png(paste0("/scratch/alpine/lost1845/active/SierraBighorn/downscaledv3/pix/",as.character(train.size),"/rasterpix/SSN.downscaled.",     format(mod.date[day],"%Y%m%d"),".png"),width=700,height=600)
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
	
	print(downscaledFile)
	print(scastats0)
	print(scastats15)
	print(as.data.frame(c(length(subset.these), length(myC), length(myT))))
	

	#write.table(scastats0,file=paste0(myEnv$getModelDir(),"/SCA/v", opt$modisVersion,"/", as.character(myEnv$getTrain.size()),"/0thresh.",format(mod.date[day],"%Y%m%d"),".csv"),row.names=FALSE,col.names=TRUE)	
	#write.table(scastats15,file=paste0(myEnv$getModelDir(),"/SCA/v",opt$modisVersion,"/", as.character(myEnv$getTrain.size()),"/15thresh.",format(mod.date[day],"%Y%m%d"),".csv"),row.names=FALSE,col.names=TRUE)
  write.table(scastats0, 
              file = myEnv$getSCAFilenameFor(SCADir, "0thresh", format(mod.date[day],"%Y%m%d")),
              row.names=FALSE,col.names=TRUE)
  write.table(scastats15, 
              file = myEnv$getSCAFilenameFor(SCADir, "15thresh", format(mod.date[day],"%Y%m%d")),
              row.names=FALSE,col.names=TRUE)
		
}



sumstatnames <- c("precision", "recall", "specificity","F statistic","accuracy","mean difference","median difference","RMSE",
"mean difference (conditional)", "median difference (conditional)", "RMSE (conditional)",
"mean difference (conditional)", "median difference (conditional)", "RMSE (conditional)"  )


#to be run after all tables are saved

all_files <- list.files(SCADir, 
                        pattern = "*.csv",full.names = TRUE,recursive=TRUE)

files.thresh0 <-  all_files[grepl("0thresh", all_files)]
files.thresh15 <- all_files[grepl("15thresh", all_files)]

#scastats0 <- matrix(NA,ncol=170,nrow=14)
#scastats15 <- matrix(NA,ncol=170,nrow=14)
## change ncol to number of days
scastats0 <- matrix(NA,ncol=nday,nrow=14)
scastats15 <- matrix(NA,ncol=nday,nrow=14)


for(day in 1:nday){	
	
	
	scastats0[,day] <- unlist(read.table(files.thresh0[day],header=TRUE))
	scastats15[,day] <- unlist(read.table(files.thresh15[day],header=TRUE))
	
}





mean.summary.0vs15 <- cbind(apply(scastats0,1,mean), apply(scastats15,1,mean))
colnames(mean.summary.0vs15) <- c("0 thresh", "15 thresh")
rownames(mean.summary.0vs15) <- sumstatnames
print(mean.summary.0vs15)

## Create pix directory if needed, return directory
pixDir <- ESPFusion::PrepPixDir(opt$outDir, as.character(myEnv$getTrain.size()))

#png(paste0(opt$outDir, "/pix/",as.character(myEnv$getTrain.size()),
#           "/statpix/SSN.downscaled.", as.character(myEnv$getTrain.size()),".png"),
#    width=1300,height=600)
png(myEnv$getPixFilenameFor(pixDir, "downscaled"), 
    width=1300,height=600)
par(mfrow=c(2,4))
plot(mod.da[1:nday],scastats0[1,],main=paste0(sumstatnames[1]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[2,],main=paste0(sumstatnames[2]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[3,],main=paste0(sumstatnames[3]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[4,],main=paste0(sumstatnames[4]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[5,],main=paste0(sumstatnames[5]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[6,],main=paste0(sumstatnames[6]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[7,],main=paste0(sumstatnames[7]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[8,],main=paste0(sumstatnames[8]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
dev.off()




#png(paste0(opt$outDir, "/pix/",as.character(myEnv$getTrain.size()),"/statpix/SSN.downscaled.condTsnow", as.character(myEnv$getTrain.size()),".png"),width=1300,height=400)
png(myEnv$getPixFilenameFor(pixDir, "downscaled.condTsnow"), 
    width=1300,height=400)
par(mfrow=c(1,3))
plot(mod.da[1:nday],scastats0[9,],main=paste0(sumstatnames[9]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[10,],main=paste0(sumstatnames[10]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[11,],main=paste0(sumstatnames[11]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
dev.off()

#png(paste0(opt$outDir, "/pix/",as.character(myEnv$getTrain.size()),"/statpix/SSN.downscaled.condCTsnow", as.character(myEnv$getTrain.size()),".png"),width=1300,height=400)
png(myEnv$getPixFilenameFor(pixDir, "downscaled.condCTsnow"), 
    width=1300,height=400)
par(mfrow=c(1,3))
plot(mod.da[1:nday],scastats0[12,],main=paste0(sumstatnames[12]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[13,],main=paste0(sumstatnames[13]),ylim=c(-1,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
plot(mod.da[1:nday],scastats0[14,],main=paste0(sumstatnames[14]),ylim=c(0,1),xlab='day of year',ylab='',las=1,cex.lab=1.5, cex.axis=1.5, cex.main=2)
dev.off()






#variable importtance
# commented out importance

#class.imp <- importance(ranger.classifier)
#reg.imp <- importance(ranger.regression)

#names.imp <- names(class.imp)
#names.imp[1] <- "day"
#names.imp[2] <- "elevation"
#names.imp[4] <- "aspect"
#names.imp[5] <- "land type"
#names.imp[6] <- "MODIS"
#names.imp[7] <- "longitude"
#names.imp[8] <- "latitude"
#names.imp[9] <- "forest height"
#names.imp[10] <- "NW barrier distance"
#names.imp[11] <- "SW barrier distance"
#names.imp[12] <- "W barrier distance"
#names.imp[13] <- "SW water distance"
#names.imp[14] <- "W water distance"
#names.imp[15] <- "wind speed"


#names(class.imp) <- names.imp
#names(reg.imp) <- names.imp

#class.imp <- sort(class.imp)
#reg.imp <- sort(reg.imp)


#png(paste0("/scratch/alpine/lost1845/active/SierraBighorn/downscaledv3/pix/",as.character(train.size),"/importance.png"),width=2000,height=800)
#par(mfrow=c(1,2),mai=c(1,4,1,1))
#barplot(class.imp/1e6,xlab='Importance (scaled)',las=1,cex.lab=2.5, cex.axis=2, cex.names=2.5,horiz=TRUE)
#barplot(reg.imp/1e8,xlab='Importance (scaled)',las=1,cex.lab=2.5, cex.axis=2, cex.names=2.5,horiz=TRUE)
#dev.off()



