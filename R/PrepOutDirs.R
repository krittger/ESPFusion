#' PrepOutDirs
#'
#' Creates required output directory structure for downscaling.
#' If any of the directories don't already exist they will be created.
#'
#' @param folder string name of directory where new structure will be created
#' @param tsize num value of training size, used in new subdirectories
#' @param year 4-digit year of output data to be written
#' 
#' @return list of output directories, for
#'         outputs of downscaled, prob.btwn, prob.hundred, regression
#' 
#' @examples
#' dirs = PrepOutDirs("/my/path/", 3e+05, 2001)
#' 
#' @export
PrepOutDirs <- function(folder, tsize, year) {
    print(paste0("Prepping ", folder, "..."))

    ## Check/make output directories if they don't already exist
    if (!(dir.exists(folder))) {
        print(paste0("Making new output directory: ", folder))
        dir.create(folder, showWarnings=FALSE)
    }

    dlist <- c("downscaled", "prob.btwn", "prob.hundred", "regression")
    outDirs <- list()
    for (d in dlist) {
        thisDir <- file.path(folder, d, as.character(tsize), year)
        if (!(dir.exists(thisDir))) {
            print(paste0("Making new output directory: ",thisDir))
            dir.create(thisDir, recursive=TRUE, showWarnings=FALSE)
        }
        outDirs[d] <- thisDir
    }

    print(paste0("...output directories OK"))

    return(outDirs)
    
}
