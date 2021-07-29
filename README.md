# ESPFusion
Data fusion for downscaling Earth Surface Properties

## Configuring to run R

This system use the R programming language.  You will need to
create an R environment with the required packages.

1. Download and install conda from Anaconda (or Miniconda). For
   Miniconda, at the Summit command prompt, get the latest Miniconda:

   ```
   wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
   ```

   Then install Miniconda like this:

   ```
   bash Miniconda3-latest-Linux-x86_64.sh
   ```

   Follow the prompts for all the default, but when prompted for the installation
   directory, change it from the default in /home/$USER/miniconda3 to your
   projects directory:  /projects/$USER/miniconda3
   At the end of the installation, answer yes to the prompt to put this miniconda
   at the front of your PATH.

   After successful installation, log out and log back in and do

   ```
   which conda
   ```

   which should return to the path to the newly installed conda in your /projects/
   directory.

2. Set up your conda channels to look on the conda-forge online channel for the
   packages we will need.  Create a new file in your home directory named ".condarc" and
   put the following commands in it:

   ```
   channels:
    - https://conda.anaconda.org/conda-forge/channel/main
    - defaults
   always_yes: true
   show_channel_urls: true
   ```
   
3. Create a new conda environment with r-essentials built from
   CRAN:

   ```
   conda create -n r_ESPFusion r-essentials r-base r-optparse
   ```

   (For developer tools and to build the package, you should use:

   ```
   conda create -n r_ESPFusion r-essentials r-base r-optparse r-devtools r-roxygen2 r-testthat
   ```
   
4. Activate the environment with:

   ```
   conda activate r_ESPFusion
   ```
   
5. List the packages in the environment:

   ```
   conda list
   ```

   This should indicate that the r-base package is installed, and
   will also include r-matrix
   
6. The ESPFusion system requires 5 additional packages. Install
   them with this command:

   ```
   conda activate r_ESPFusion
   conda install r-fields r-raster r-ranger r-proj4 r-rgdal
   ```
   
7. Open the R interactive interface:

   ```
   R
   ```
   
8. Load the required packages:

   In R:

   ```
   library(fields)
   library(raster)
   library(ranger)
   library(proj4)
   library(rgdal))
   ```
   
9. See what is currently loaded:

   In R:

   ```
   (.packages())
   ```
   
   The list of loaded packages should include fields, raster,
   ranger, proj4 and rgdal (and will include their dependencies)

10. Clone the ESPFusion package from github to your /projects/$USER directory:

   In a terminal:
   
   ```
   cd /projects/$USER
   git clone https://github.com/mjbrodzik/ESPFusion.git
   ```

11. To develop and/or run ESPFusion routines, install them this way:

   In R:
   
   ```
   devtools::install()
   ```

   This will install the ESPFusion package components into the
   currently running R installation (which is in the current conda env.)
   
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


## Licensing

The ESPFusion software has been developed at the University of
Colorado, with contributions from multiple authors. To cite the
use of ESPFusion, please use:

Krock, M. L., W. Kleiber, M. J. Brodzik, B. Rajagopalan,
K. Rittger. 2019. ESPFusion: Data fusion for downscaling Earth
Surface Properties [Source code]. https://github.com/mjbrodzik/ESPFusion.

ESPFusion is Copyright (C) 2019 Regents of the University of Colorado.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.



