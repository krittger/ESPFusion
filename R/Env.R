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
        HiResRows = 14752,
        HiResCols = 9712,
        LowResRows = 922,
        LowResCols = 607
    )

    class(me) <- append(class(me), "Env")
    return(me)
}
