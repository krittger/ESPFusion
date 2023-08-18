#' Directory locations for ESPFusion files
#'
#' This class stores required directory locations for the ESPFusion
#' processing system.
#'
#' Thanks to Fong Chun Chan for help with building/using packages
#' https://tinyheero.github.io/jekyll/update/2015/07/26/making-your-first-R-package.html
#'
#' following method examples from here:
#' https://www.cyclismo.org/tutorial/R/s3Classes.html
#' 
#' @return A list of directory locations used by the downscaling system
#' @export
#'
#' 18 Mar 2020 M. J. Brodzik brodzik@colorado.edu 
#' Copyright (C) 2019 Regents of the University of Colorado
#'
Env <- function() {

    ## Get the environment for this instance of the function
    thisEnv <- environment()

    ## Path that is common to many others
   # topDir <- "/pl/active/SierraBighorn"

    ## path to non-cloudy Landsat region (e.g. SSN) files
    ## (this path does not include the version level,
    ## assumes it is 'vXX')
    landsatDir = "/pl/active/rittger_esp/scag/Landsat/UCSB_v3_processing/SSN"
        
    ## path to cloudy Landsat region (e.g. SSN) files
    ## that have been masked for probable clouds
    ## (this path does not include the version level,
    ## assumes it is 'vXX')
    cloudyLandsatDir = "/pl/active/rittger_esp/scag/Landsat/UCSB_v3_processing/SSN_cloudy"
        
    ## path to co-located MODIS region (e.g. SSN) files
    ## (this path does not include the version level,
    ## assumes it is 'vXX')
    modisDir = "/pl/active/rittger_esp/scag/MODIS/SSN"
        
    ## path to model information:
    ## predictors file lives in this directory
    ## regression and classifiers directories are here
    ## processing assumes one more levels down from here with 'modelName'

    ## Use this directory for new models 	
    modelDir = "/scratch/alpine/lost1845/active/SierraBighorn/Rdata"
    ## Use this directory for models previously developed by Mary Jo
    
    #modelDir = "/pl/active/rittger_esp/SierraBighorn/Rdata"      

    ## default output path to fusion files
    #fusionDir = "/scratch/alpine/lost1845/active/SierraBighorn/downscaledv3"
    ## v04_production has images generated until 2020.06.18
    fusionDir = "/scratch/alpine/lost1845/active/SierraBighorn/downscaledv4_production"
        
    ## default training size
    train.size = 3e+05

    me <- list(

        ## Define the environment where this list is defined so
        ## that I can refer to it in methods below
        thisEnv = thisEnv,

        ## Getters/Setters
        ## topDir
        getTopDir = function() {

            return(get("topDir", thisEnv))

        },

        setTopDir = function(value) {

            return(assign("topDir", value, thisEnv))

        },

        ## landsatDir
        getLandsatDir = function() {

            return(get("landsatDir", thisEnv))

        },

        setLandsatDir = function(value) {

            return(assign("landsatDir", value, thisEnv))

        },

        ## cloudyLandsatDir
        getCloudyLandsatDir = function() {

            return(get("cloudyLandsatDir", thisEnv))

        },

        setCloudyLandsatDir = function(value) {

            return(assign("cloudLandsatDir", value, thisEnv))

        },

        ## modelDir
        getModelDir = function() {

            return(get("modelDir", thisEnv))

        },

        setModelDir = function(value) {

            return(assign("modelDir", value, thisEnv))

        },

        ## fusionDir
        getFusionDir = function() {

            return(get("fusionDir", thisEnv))

        },

        setFusionDir = function(value) {

            return(assign("fusionDir", value, thisEnv))

        },

        ## train.size
        getTrain.size = function() {

            return(get("train.size", thisEnv))

        },

        setTrain.size = function(value) {

            return(assign("train.size", value, thisEnv))

        },

        ## Other useful methods
        modisFileFor = function(year, doy, varName, version) {

            dir <- file.path(get("modisDir", thisEnv),
                             sprintf("v%02d", version))

            ## version v01 files are all in same directory, (which is slow)
            ## later version files are in year subdirs
            if (version > 1) {
                dir <- file.path(dir, "????")
            }

            ## filenames are yyyymmdd, so convert doy
            origin <- sprintf("%04d-01-01", year)
            yyyymmdd <- format(as.Date(doy - 1, origin), "%Y%m%d")

            ## look for date + period + anything + period + varName + period
            ## \\. - matches a period
            ## .* - matches 0 or more of any character
            pattern <- sprintf("%s\\..*\\.%s\\.", yyyymmdd, varName)
            
            return(list.files(Sys.glob(dir),
                              pattern=pattern,
                              full.names=TRUE))
            
        },
        
        parseDateFrom = function(fileName) {

            baseName <- basename(fileName)
            dateStr <- regmatches(baseName,
                              regexpr("[0-9]{8}", baseName))
            if (length(dateStr) == 0) {
                dateStr <- 'noDate'
            }
            return(dateStr)
            
        },
        
        isPostLeapDay = function(year, doy) {

            ## Return TRUE iff this doy is in a leap year and strictly
            ## later than the leap day
            ## This logic only works for dates from 1901 - 2099
            out <- FALSE
            leapDoy <- 59
            if (1900 < year && year < 2100) {
                if (0 == (year %% 4) && doy > leapDoy) {
                    out <- TRUE
                }
            } else {
                stop("Year out of expected range")
            }
            
            return(out)
            
        },
        
        allModisFiles = function(varName, version) {

            dir <- file.path(get("modisDir", thisEnv),
                             sprintf("v%02d", version))

            ## version v01 files are all in same directory, (which is slow)
            ## later version files are in year subdirs
            ## do this so that any other sibling directories are ignored
            if (version > 1) {
                dir <- file.path(dir, "????")
                recursive <- TRUE
            } else {
                recursive <- FALSE
            }

            ## look recursively for period + varName + period
            ## \\. - matches a period
            pattern <- sprintf("\\.%s\\.", varName)
            
            return(list.files(Sys.glob(dir),
                              pattern=pattern,
                              recursive=recursive,
                              full.names=TRUE))
            
        },
        
        allLandsatFiles = function(varName, version=1, includeCloudy=FALSE) {

            dir <- file.path(get("landsatDir", thisEnv),
                             sprintf("v%02d", version))

            ## look for period + varName + period
            ## \\. - matches a period
            pattern <- sprintf("\\.%s\\.", varName)
            
            out <- list.files(Sys.glob(dir),
                              pattern=pattern,
                              full.names=TRUE)

            if (includeCloudy) {

                message("Including cloudy-masked Landsat files...")

                dir <- file.path(get("cloudyLandsatDir", thisEnv),
                                 sprintf("v%02d", version))

                cloudyList <- list.files(Sys.glob(dir),
                                         pattern=pattern,
                                         full.names=TRUE)

                out <- c(out, cloudyList)

            }

            return(out)
            
        },
        
        getModelFilenameFor = function(fileType,
                                       modelName='forest',
                                       varName='SCA',
                                       version=3) {

            validFileTypes <- c("regression", "classifier")
            if ( !(fileType %in% validFileTypes) ) {
                stop(sprintf("Unrecognized fileType=%s", fileType))
            }

            dir <- get("modelDir", thisEnv)

            ## Early versions of these files are in a different
            ## location
            ## FIXME:  will we ever want to use the other train.sizes?
            if (version < 3) {
                if (identical(fileType, "classifier")) {
                    out <- file.path(dir, modelName, "twostep", "classification",
                                     sprintf("ranger.%s.prob3e+05.Rda",
                                             fileType))
                } else {
                    out <- file.path(dir, modelName, "twostep", fileType,
                                     sprintf("ranger.%s.prob3e+05.Rda",
                                             fileType))
                }
            } else {
                                 
                out <- file.path(dir, modelName,
                                 sprintf("ranger.%s.%s.v%02d.Rda",
                                         fileType, varName, version))
            }

            return(out)
            
        },
        
        getPredictorFilenameFor = function(varName='SCA',
                                           version=0) {

            dir <- get("modelDir", thisEnv)

            ## build the filename from this location
            return(file.path(dir, 
                             sprintf("predictors.%s.v%02d.RData",
                                     varName, version)))
            
        },
        
        getDownscaledFilenameFor = function(dir,
                                            fileType,
                                            extentShortName,
                                            yyyymmddStr,
                                            version=3) {

            validFileTypes <- c("regression",
                                "downscaled",
                                "prob.btwn",
                                "prob.hundred")
            if ( !(fileType %in% validFileTypes) ) {
                stop(sprintf("Unrecognized fileType=%s", fileType))
            }

            if (identical(fileType, "regression")) {
                out <- file.path(dir,
                                 sprintf("%s.downscaled.regression.%s.v%d.%s.tif",
                                         extentShortName,
                                         yyyymmddStr,
                                         version,
                                         as.character(get("train.size", thisEnv))))
            } else if (identical(fileType, "downscaled")) {
                out <- file.path(dir,
                                 sprintf("%s.downscaled.%s.v%d.%s.tif",
                                         extentShortName,
                                         yyyymmddStr,
                                         version,
                                         as.character(get("train.size", thisEnv))))
            } else if (identical(fileType, "prob.btwn")) {
                out <- file.path(dir,
                                 sprintf("%s.downscaled.prob.0.100.%s.v%d.%s.tif",
                                         extentShortName,
                                         yyyymmddStr,
                                         version,
                                         as.character(get("train.size", thisEnv))))
            } else {
                ## fileType == prob.hundred
                out <- file.path(dir,
                                 sprintf("%s.downscaled.prob.100.%s.v%d.%s.tif",
                                         extentShortName,
                                         yyyymmddStr,
                                         version,
                                         as.character(get("train.size", thisEnv))))
            }

            return(out)
            
        }
        
    )

    ## Define the value of the list within the current environment
    assign('this', me, envir=thisEnv)

    ## Set the name for the class
    class(me) <- append(class(me), "Env")
    
    return(me)
}
