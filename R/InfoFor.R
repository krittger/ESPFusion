#' InfoForList
#'
#' Lists size and contents information for each object in list
#'
#' @param list list to investigate
#'
#' @return summary information for each object in list
#'
#' @examples
#' InfoFor(ls())
#'
#' @export
#'
#' 18 Mar 2020 M. J. Brodzik brodzik@colorado.edu 
#' Copyright (C) 2019 Regents of the University of Colorado
#'
InfoFor <- function(list) {

    for (obj in list) {
        cat(sprintf("\n=============> %s contains:\n", obj))
        str(get(obj))
    }

}
