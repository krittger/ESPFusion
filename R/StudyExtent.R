#' Descriptive characteristics of ESPFusion study extents
#'
#' This class stores descriptive information for ESPFusion study extents
#'
#' @return List with descriptive characteristics for the requested study extent
#' 
#' @export
StudyExtent <- function(extentName) {

    ## study extent data:
    ## shortName (used as prefix for regional filenames)
    ## highResRows/Cols : dimensions of high resolution matrix
    ## lowResRows/Cols : dimensions of low resolution matrix
    ## factor : multiplicative factor that relates high to low resolution
    ##          values must be integer factor,
    ##          e.g. lowResCols * factor = highResCols
    ## FIXME: we need to enforce this
    if (identical(extentName, "SouthernSierraNevada")) {
        me <- list(
            "extentName" = extentName,
            "shortName" = "SSN",
            "highResRows" = 14752,
            "highResCols" = 9712,
            "lowResRows" = 922,
            "lowResCols" = 607
        )
    } else {

        stop("Unknown extentName")
        
    }

    ## Define the value of the list within the current environment
    assign('this', me)

    ## Set the name for the class
    class(me) <- append(class(me), "StudyExtent")
    
    return(me)
}
