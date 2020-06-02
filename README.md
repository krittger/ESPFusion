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

9. To develop and/or run ESPFusion routines, install them this way:

   ```R
   devtools::install()
   ```

   This will install the ESPFusion package components into the
   currently runnint R installation (which is in the current conda env.)
   
## Notes for emacs users running R remotely

1. On the remote machine set up the conda env with R installed (see the
   section above "Configuring to run R". The rest of this section
   assumes the conda environment is called r_ESPFusion.

2. On the remote machine configure the shells to activate this conda environment
   as the default env when there is a dumb terminal connection (which is how
   emacs will connect):
   * On the remote machine, confirm that your ~/.bashrc only contains a
     call to the system /etc/bashrc, and then calls ~/.my.bashrc. N.B.
     The conda installation may add some conda init stuff to this file. It will
     mess with the currently activated conda env. If it is there, make sure
     it is prior to the execution of ~/.my.bashrc, or just move it into the
     ~/.my.bashrc.
   * On the remote machine: add this to the ~/.my.bashrc, after the conda
     init stuff:
     ```
     if test "$TERM" = "dumb"; then
        source active r_ESPFusion
     fi
     ```
     Apparently when emacs tramp connects to a remote machine, it sets
     $TERM to "dumb".  So this addition to the .my.bashrc will activate
     the conda env called r_ESPFusion.
     
3. Use emacs to start a remote shell: on the local machine, in emacs, do:
   ```
   M-x shell
   ```
   which will open an ssh session and run .bashrc, this will execute
   the .my.bashrc and active the conda env. The shell prompt will include
   the prefix "(r_ESPFusion) <your other prompt stuff here>"

4. Start R in the remote shell: in the emacs shell buffer, cd to the directory
   with your R scripts, and type "R" at the command prompt.
   This is a remote R session.

5. Connect your emacs ESS session to the remote R session: in emacs, do:
   ```
   M-x ess-remote<ret><ret>
   ```
   this connects emacs to your remote R session.
   

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

3. Test/change/make modifications. Use the Wickham and Bryan "R Packages"
   book for good information about code style, automated documentation and
   automated testing:

   https://r-pkgs.org/tests.html

   To run all tests:

   ```R
   devtools::test()
   ```

   To automate document/test/load etc:

   ```R
   devtools::check()
   ```

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

* https://tinyheero.github.io/jekyll/update/2015/07/26/making-your-first-R-package.html
* https://r-pkgs.org/tests.html


## Shalini Edit