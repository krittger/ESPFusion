test_that("PrepOutDirs returns expected directories", {

    ## test output will be created in the directory
    ## that includes this file
    dir <- './testOut'
    tsize <- 3e+05
    outDirs <- PrepOutDirs(dir, tsize)

    dlist <- c("downscaled", "prob.btwn", "prob.hundred", "regression")
    expect_equal(length(outDirs), length(dlist))
    for (d in dlist) {
        expect_equal(outDirs[[d]],
                     sprintf("%s/%s/%s",
                             dir, d, as.character(tsize)))
    }

    # Cleanup
    unlink(dir, recursive=TRUE)

})
