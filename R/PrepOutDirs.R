#' PrepOutDirs
#'
#' Creates required output directory structure for downscaling.
#' If any of the directories don't already exist they will be created.
#'
#' @param dirName string name of directory where new structure will be created
#' @param tsize num value of training size, used in new subdirectories
#' 
#' @return list of output directories, for
#'         outputs of downscaled, prob.btwn, prob.hundred, regression
#' 
#' @examples
#' dirs = PrepOutDirs("/my/path/", 3e+05)
#' 
#' @export
PrepOutDirs <- function(dirName, tsize) {
    print(paste0("Prepping ", dirName, "..."))

    ## Check/make output directories if they don't already exist
    if (!(dir.exists(dirName))) {
        print(paste0("Making new output directory: ", dirName))
        dir.create(dirName, showWarnings=FALSE)
    }

    dlist <- c("downscaled", "prob.btwn", "prob.hundred", "regression")
    outDirs <- list()
    for (d in dlist) {
        thisDir <- file.path(dirName, d, as.character(tsize))
        if (!(dir.exists(thisDir))) {
            print(paste0("Making new output directory: ",thisDir))
            dir.create(thisDir, recursive=TRUE, showWarnings=FALSE)
        }
        outDirs[d] <- thisDir
    }

    print(paste0("...output directories OK"))

    return(outDirs)
    
}
