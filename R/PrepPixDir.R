#' PrepPixDir
#'
#' Creates required output directory structure for plots.
#' If any of the directories don't already exist they will be created.
#' 
#' 5 Mar 2024 L. w. Stephenson  
#' Copyright (C) 2019 Regents of the University of Colorado
#'
#' @param folder string name of directory where new structure will be created
#' @return pix directory for plots
#' 
#' @export PrepPixDir
#'
#'

## Function to create forest directory for classififer and regression models
PrepPixDir <- function(folder, tsize) {
  PixFolder <- file.path(folder, "pix", tsize, "statpix")
  print(paste0("Prepping ", PixFolder, "..."))
  
  ## Check/make output directories if they don't already exist
  if (!(dir.exists(PixFolder))) {
    print(paste0("Making new output directory: ", PixFolder))
    dir.create(PixFolder, showWarnings=FALSE, recursive = TRUE)
  }
  
  print(paste0("...Pix directory OK"))
  
  return(PixFolder)
  
}