# Fusion-MODIS-Landsat
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

2. Update conda to latest release

   ```
   conda update conda
   ```
   
3. Set up your conda channels to look on the conda-forge online channel for the
   packages we will need.  Create a new file in your home directory named ".condarc" and
   put the following commands in it:

   ```
   channels:
    - conda-forge
    - defaults
   always_yes: true
   show_channel_urls: true
   ```
   
4. Add mamba to your base conda env

   ```
   conda install mamba
   ```
   
5. Create a new conda environment with all required packagess

   ```
   mamba create -n r_ESPFusion r-essentials r-base r-optparse r-devtools
   ```

   Alternatively, for development/testing tools and to build the package, you will need a few more:

   ```
   mamba create -n r_ESPFusion r-essentials r-base r-optparse r-devtools r-roxygen2 r-testthat r-fields r-raster r-ranger r-proj4 r-rgdal rstudio-desktop
   ```
   
6. Activate the environment with:

   ```
   conda activate r_ESPFusion
   ```
   
7. List the packages in the environment:

   ```
   conda list
   ```

   This should indicate that the r-base package is installed, and
   will also include r-matrix
   
8. Open the R interactive interface:

   ```
   R
   ```
   
9. Load the required packages:

   In R:

   ```
   library(fields)
   library(optparse)
   library(raster)
   library(ranger)
   library(proj4)
   library(devtools)
   library(rgdal)
   ```
   
10. See what is currently loaded:

   In R:

   ```
   (.packages())
   ```
   
   The list of loaded packages should include fields, raster,
   ranger, proj4 and rgdal (and will include their dependencies)

11. Clone the ESPFusion package from github to your /projects/$USER directory:

   In a terminal:
   
   ```
   cd /projects/$USER
   git clone https://github.cokm/krittger/Fusion-MODIS-Landsat.git
   ```

12. To develop and/or run ESPFusion routines, install them this way:

   In R:
   
   ```
   devtools::install()
   ```

   This will install the Fusion-MODIS-Landsat package components into the
   currently running R installation (which is in the current conda env.)
   
## How to use RStudio

RStudio (installed with rstudio-desktop) is an interactive development
environment that you may find useful for debugging. Here is a tutorial you may find useful:

https://www.datacamp.com/tutorial/r-studio-tutorial

I recommend setting a couple of environment variables for some of RStudio default housekeeping files:

Add these lines to your ~/.bashrc:

# Added for RStudio                                                                                                                         # These will tell RStudio to make temporary files in                                                                                        # locations other than our very small home directories                                                                                      # This directory needs to have permissions 0700, otherwise RStudio complains                                                                export XDG_RUNTIME_DIR=/scratch/alpine/$USER/rstudio-runtime

# See https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html                                                          # This directory controls where the default logging goes, default is ~/.local/share                                                         # Make it something that's not your home directory:                                                                                         export XDG_DATA_HOME=/projects/$USER/.local/share

To use it, open an interactive desktop with ondemand

On the desktop, open a Terminal, activate our conda env and run rstudio:

```
conda activate r_ESPFusion
rstudio
```

See the tutorial above for debugging a specific R file. In RStudio, you can run
the script with debugSource:

```
> setwd('/path/to/Fusion-MODIS-Landsat'
> debugSource('exec/twostep.downscaling.R');
```

but this will only run the twostep.downscaling.R script with the default
arguments.  To change the defaults, I have not figured how how to do it directly
in the debugSource call. I have successfully created a breakpoint after the parse_args call,
and then manually set the opt argument value to something other than the default:

In RStudio, set a breakpoint in twostep.downscaling.R at line 52, then:

```
> debugSource('exec/twostop.downscaling.R')
Browse[2]> opt$year
[1] 2000
Browse[2]> opt$year <- 2002
```

Here's a pretty good tutorial on debugging in RStudio:

https://support.posit.co/hc/en-us/articles/205612627-Debugging-with-the-RStudio-IDE

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
        source activate r_ESPFusion
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

   When you are running the devtools commands, you must have the current
   workin directory set to the top level of the ESPFusion clone location.
   
   To run all tests:

   ```R
   devtools::test()
   ```

   To automate document/test/load etc:

   ```R
   devtools::check()
n   ```

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

6. Edit any of the .R files, and reload them to see the results with

   ```R
   devtools::load_all()
   ```

   Keep making changes and evaluating the results until you are happy
   with your changes.
   
7. When you have completed your changes, commit/push all your changes to the
   branch in Github, and merge with master branch, or make a pull request to
   review changes with others.
   
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



