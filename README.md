# ESPFusion
Data fusion for downscaling Earth Surface Properties

## Configuring to run R

This system use the R programming language.  You will need to
create an R environment with the required packages.

1. Download and install conda from Anaconda (or Miniconda).

2. Create a new conda environment with r-essentials built from
   CRAN:
   
   conda create -n r_ESPFusion r-essentials r-base r-optparse

   (For developer tools and to build the package, also needs:
   
   conda create -n r_ESPFusion r-essentials r-base r-optparse r-devtools r-roxygen2
   
3. Activate the environment with:

   conda activate r_ESPFusion
   
4. List the packages in the environment:

   conda list
   
   This should indicate that the r-base package is installed, and
   will also include r-matrix
   
5. The ESPFusion system requires 3 additional packages. Install
   them with this command:

   ```
   conda activate r_ESPFusion
   conda install r-fields r-raster r-ranger r-proj4 r-rgdal
   ```
   
6. Open the R interactive interface:

   R
   
7. Load the required packages:

   ```R
   library(fields)
   library(raster)
   library(ranger)
   library(proj4)
   library(rgdal))
   ```
   
8. See what is currently loaded:

   ```R
   (.packages())
   ```
   
   The list of loaded packages should include fields, raster,
   ranger, proj4 and rgdal (and will include their dependencies)
   
## Running the ESPFusion system

Details here TBD.  See documentation in man/ folder.  R package
components go in R/ folder. R top-level control scripts
(Rscripts) go in exec/ folder. Slurm sbatch control scripts go in
scripts/ folder.

1. Make the new model:

   ```TBD```

2. Prepare downscaling input files and setup metadata:

   ```TBD```

3. Do downscaling: the main function for running downscaling is
   twostep.downscaling.R, which works on 1 day of data.

   ```TBD```

## Development Cycle for ESPFusion system

To work on a new feature or bug fix:

1. Check out the project from github.com

2. Make a new branch

3. Test/change/make modifications.

4. Make sure inline documentation is updated with your changes.
   Use roxygen2 to update documentation with:

   ```R
   devtools::document()
   ```

   This will generate/update the *.Rd files in the man/ folder.
   
5. Install the modified package into the current R system library
   (presumably this is the conda env R installation you are currently
   running):

   ```R
   devtools::install()
   ```

6. Commit/push all your changes to the branch in Github, and
   merge with master branch, or make a pull request to review
   changes with others.
   
For additional details and other package features, see:

https://tinyheero.github.io/jekyll/update/2015/07/26/making-your-first-R-package.html


