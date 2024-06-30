#' PrepModelDir
#'
#' Creates required output directory structure for classifier and regression models.
#' If any of the directories don't already exist they will be created.
#' 
#' #' 18 Mar 2020 M. J. Brodzik brodzik@colorado.edu 
#' Copyright (C) 2019 Regents of the University of Colorado
#'
#' @param folder string name of directory where new structure will be created
#' @return no return
#' 
#' @export
#'
#'

## Function to create forest directory for classififer and regression models
PrepModelDir <- function(folder) {
  modelFolder <- file.path(folder, "forest")
  print(paste0("Prepping ", modelFolder, "..."))
  
  ## Check/make output directories if they don't already exist
  if (!(dir.exists(modelFolder))) {
    print(paste0("Making new output directory: ", modelFolder))
    dir.create(modelFolder, showWarnings=FALSE, recursive = TRUE)
  }
  
  print(paste0("...model directory OK"))
}


