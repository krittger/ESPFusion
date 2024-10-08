% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PrepOutDirs.R
\name{PrepOutDirs}
\alias{PrepOutDirs}
\title{PrepOutDirs}
\usage{
PrepOutDirs(folder, tsize)
}
\arguments{
\item{folder}{string name of directory where new structure will be created}

\item{tsize}{num value of training size, used in new subdirectories}
}
\value{
list of output directories, for
        outputs of downscaled, prob.btwn, prob.hundred, regression
}
\description{
Creates required output directory structure for downscaling.
If any of the directories don't already exist they will be created.
}
\examples{
dirs = PrepOutDirs("/my/path/", 3e+05)

}
