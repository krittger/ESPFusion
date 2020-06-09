#' Directory locations for ESPFusion files
#'
#' This class stores required directory locations for the ESPFusion
#' processing system.
#'
#' Thanks to Fong Chun Chan for help with building/using packages
#' https://tinyheero.github.io/jekyll/update/2015/07/26/making-your-first-R-package.html
#'
#' @return A list of directory locations used by the downscaling system
#' @export
Env <- function() {

    ## Get the environment for this instance of the function
    thisObjEnv <- environment()

    ## Path that is common to many others
    topDir <- "/pl/active/SierraBighorn"

    ## regionShortName (used as prefix for regional filenames)
    regionShortName = "SSN"
        
    ## path to Landsat region (e.g. SSN) files
    landsatDir = paste0(topDir,
                        "/scag/Landsat/UCSB_v3_processing/SSN/v01/")
        
    ## path to co-located MODIS region (e.g. SSN) files
    modisDir = paste0(topDir,
                      "/scag/MODIS/SSN/v01/")
        
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
        
    ## co-located region dimensions, at Landsat and MODIS resolutions
    HiResRows = 14752
    HiResCols = 9712
    LowResRows = 922
    LowResCols = 607
    
    me <- list(

        ## Define the environment where this list is defined so
        ## that I can refer to it in methods below
        thisObjEnv = thisObjEnv,

        train.size = function() {

            return(get("train.size", thisObjEnv))

        },

        modisFileFor = function(year, doy) {
            
            return(get("modisDir", thisObjEnv))
            
        }
        
    )

    ## Define the value of the list within the current environment
    assign('this', me, envir=thisObjEnv)

    ## Set the name for the class
    class(me) <- append(class(me), "Env")
    
    return(me)
}
