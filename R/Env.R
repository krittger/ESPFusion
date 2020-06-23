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
Env <- function() {

    ## Get the environment for this instance of the function
    thisEnv <- environment()

    ## Path that is common to many others
    topDir <- "/pl/active/SierraBighorn"

    ## path to Landsat region (e.g. SSN) files
    landsatDir = paste0(topDir,
                        "/scag/Landsat/UCSB_v3_processing/SSN/v01/")
        
    ## path to co-located MODIS region (e.g. SSN) files
    modisDir = paste0(topDir,
                      "/scag/MODIS/SSN")
        
    ## path to model regression and classifiers directories
    modelDir = paste0(topDir,
                      "/Rdata/forest/twostep/")
        
    ## top level output directory, is assumed to contain subdirs:
    ## regression/, downscaled/, prob.btwn/ and prob.hundred/
    fusionDir = paste0(topDir,
                       "/downscaledv3_test")
        
    ## file with prepared setup predictor data
    predictorsFile = paste0(topDir,
                            "/Rdata/predictors.setup.v0.RData")
        
    ## default training size
    train.size = 3e+05

    ## study extent data:
    ## shortName (used as prefix for regional filenames)
    ## highResRows/Cols : dimensions of high resolution matrix
    ## lowResRows/Cols : dimensions of low resolution matrix
    ## factor : multiplicative factor that relates high to low resolution
    ##          values must be integer factor,
    ##          e.g. lowResCols * factor = highResCols
    ## FIXME: we need to enforce this 
    extent <- list("shortName" = "SSN",
                   "highResRows" = 14752,
                   "highResCols" = 9712,
                   "lowResRows" = 922,
                   "lowResCols" = 607)
    
    me <- list(

        ## Define the environment where this list is defined so
        ## that I can refer to it in methods below
        thisEnv = thisEnv,

        ## Getters/Setters
        getExtent = function(extentName) {

            return(get("extent", thisEnv))

        },

        getTrain.size = function() {

            return(get("train.size", thisEnv))

        },

        setTrain.size = function(value) {

            return(assign("train.size", value, thisEnv))

        },

        ## Other useful methods
        modisFileFor = function(year, doy, varName, version) {

            modisDir <- file.path(get("modisDir", thisEnv),
                                  sprintf("v%02d", version))

            ## version v01 files are all in same directory, (which is slow)
            ## later version files are in year subdirs
            if (version > 1) {
                modisDir <- file.path(modisDir, "????")
            }

            ## filenames are yyyymmdd, so convert doy
            origin <- sprintf("%04d-01-01", year)
            yyyymmdd <- format(as.Date(doy - 1, origin), "%Y%m%d")

            ## look for date + period + anything + period + varName + period
            ## \\. - matches a period
            ## .* - matches 0 or more of any character
            pattern <- sprintf("%s\\..*\\.%s\\.", yyyymmdd, varName)
            
            return(list.files(Sys.glob(modisDir),
                              pattern=pattern,
                              full.names=TRUE))
            
        }
        
    )

    ## Define the value of the list within the current environment
    assign('this', me, envir=thisEnv)

    ## Set the name for the class
    class(me) <- append(class(me), "Env")
    
    return(me)
}
