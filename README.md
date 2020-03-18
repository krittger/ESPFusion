# ESPFusion
Data fusion for downscaling Earth Surface Properties

## Configuring to run R

This system use the R programming language.  You will need to
create an R environment with the required packages.

1. Download and install conda from Anaconda (or Miniconda).

2. Create a new conda environment with r-essentials built from
   CRAN:
   
   conda create -n r_ESPFusion r-essentials r-base
   
3. Activate the environment with:

   conda activate r_ESPFusion
   
4. List the packages in the environment:

   conda list
   
   This should indicate that the r-base package is installed, and
   will also include r-matrix
   
5. The ESPFusion system requires 3 additional packages. Install
   them with this command:

   conda activate r_ESPFusion
   conda install r-fields r-raster r-ranger
   
6. Open the R interactive interface:

   R
   
7. Load the required packages:

   ```R
   library(fields)
   library(raster)
   library(ranger)
   ```
   
8. See what is currently loaded:

   ```R
   (.packages())
   ```
   
   The list of loaded packages should include fields, raster and
   ranger (and will include their dependencies)
   
## Running the ESPFusion system

Details here TBD.
