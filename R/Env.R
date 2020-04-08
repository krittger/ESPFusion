#' Directory locations for ESPFusion files
#'
#' This class stores required directory locations for the ESPFusion
#' processing system.
#'
#' @return A list of directory locations used by the downscaling system
#' @export
Env <- function()
{
    me <- list(
        modisDir = "/path/to/modis/here",
        landsatDir = "/path/to/landsat/here"
    )

    class(me) <- append(class(me), "Env")
    return(me)
}

