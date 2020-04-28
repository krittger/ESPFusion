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
    me <- list(
        ## path to Landsat SSN files
        landsatDir = "/pl/active/SierraBighorn/scag/Landsat/UCSB_v3_processing/SSN/v01/",
        ## top level output directory, is assumed to contain subdirs:
        ## regression/, downscaled/, prob.btwn/ and prob.hundred/
        fusionDir = "/pl/active/SierraBighorn/downscaledv3_test",
        ## file with prepared setup information
        setupFile = "/pl/active/SierraBighorn/Rdata/decade.setup.RData",
        ## 
        ## other shared information
        SSN30mRows = 14752,
        SSN30mCols = 9712,
        SSN500mRows = 922,
        SSN500mCols = 607
    )

    class(me) <- append(class(me), "Env")
    return(me)
}

#' PrepOutDirs - creates required output directory structure
#' 
#' @export
PrepOutDirs <- function(dirName, train.size) {
    print(paste0("Prepping ", dirName, "..."))

    ## Check/make output directories if they don't already exist
    if (!(dir.exists(dirName))) {
        print(paste0("Making new output directory: ", dirName))
        dir.create(dirName, showWarnings=FALSE)
    }

    dlist <- c("downscaled", "prob.btwn", "prob.hundred", "regression")
    outDirs <- list()
    for (d in dlist) {
        thisDir <- file.path(dirName, d, as.character(train.size))
        if (!(dir.exists(thisDir))) {
            print(paste0("Making new output directory: ",thisDir))
            dir.create(thisDir, recursive=TRUE, showWarnings=FALSE)
        }
        outDirs[d] <- thisDir
    }

    print(paste0("...output directories OK"))

    return(outDirs)
    
}    


