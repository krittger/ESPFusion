#' PrepSCADir
#'
#' Creates required output directory structure for SCA compare days tables.
#' If any of the directories don't already exist they will be created.
#' 
#' 27 Feb 2024 L. w. Stephenson  
#' Copyright (C) 2019 Regents of the University of Colorado
#'
#' @param folder string name of directory where new structure will be created
#' @return SCA directory
#' 
#' @export
#'
#'

## Function to create forest directory for classififer and regression models
PrepSCADir <- function(folder, modis_version, tsize) {
  SCAFolder <- file.path(folder, "SCA", paste0("v", modis_version),
                         tsize)
  print(paste0("Prepping ", SCAFolder, "..."))
  
  ## Check/make output directories if they don't already exist
  if (!(dir.exists(SCAFolder))) {
    print(paste0("Making new output directory: ", SCAFolder))
    dir.create(SCAFolder, showWarnings=FALSE, recursive = TRUE)
  }
  
  print(paste0("...SCA directory OK"))
  
  return(SCAFolder)
}