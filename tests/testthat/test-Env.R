test_that("Env returns good v01 MODIS filename", {

    myEnv <- Env()
    fileName <- myEnv$modisFileFor(2004, 32, "snow_cover_percent", version=1)
    expect_equal(fileName,
                 paste0("/pl/active/SierraBighorn/scag/MODIS/SSN/v01/",
                        "SSN.SN_WY2004_20040201.Terra-MODIS.snow_cover_percent.v01.tif"))
    
})

test_that("Env returns good v02 MODIS filename", {

    myEnv <- Env()
    fileName <- myEnv$modisFileFor(2004, 32, "snow_cover_percent", version=2)
    expect_equal(fileName,
                 paste0("/pl/active/SierraBighorn/scag/MODIS/SSN/v02/2004/",
                        "SSN.20040201.Terra-MODIS.snow_cover_percent.v02.tif"))
    
})

test_that("Env parses the correct date from a filename", {

    myEnv <- Env()
    fileName <- myEnv$modisFileFor(2004, 32, "snow_cover_percent", version=2)
    dateStr <- myEnv$parseDateFrom(fileName)
    expect_equal(dateStr, "20040201")
    
})

test_that("Env recognizes dates in a leap year that follow the leap day", {

    myEnv <- Env()

    expect_error(myEnv$isPostLeapDay(1900, 59))
    expect_error(myEnv$isPostLeapDay(2100, 59))

    isPostLeapDay <- myEnv$isPostLeapDay(2003, 59)
    expect_equal(isPostLeapDay, FALSE)
    isPostLeapDay <- myEnv$isPostLeapDay(2003, 60)
    expect_equal(isPostLeapDay, FALSE)
    isPostLeapDay <- myEnv$isPostLeapDay(2004, 59)
    expect_equal(isPostLeapDay, FALSE)
    isPostLeapDay <- myEnv$isPostLeapDay(2004, 60)
    expect_equal(isPostLeapDay, TRUE)
    
})

test_that("Env returns expected list of v01 MODIS filenames", {

    myEnv <- Env()
    files <- myEnv$allModisFiles("snow_cover_percent", version=1)
    expect_equal(length(files), 4657)
    
})

test_that("Env returns expected list of v02 MODIS filenames", {

    myEnv <- Env()
    files <- myEnv$allModisFiles("snow_cover_percent", version=2)
    expect_equal(length(files), 7398)
    
})

test_that("Env returns expected list of v01 clear Landsat filenames", {

    myEnv <- Env()
    files <- myEnv$allLandsatFiles("snow_cover_percent", version=1)
    expect_equal(length(files), 134)
    
})

test_that("Env returns expected list of v01 clear+cloudy Landsat filenames", {

    myEnv <- Env()
    files <- myEnv$allLandsatFiles("snow_cover_percent", version=1,
                                   includeCloudy=TRUE)
    expect_equal(length(files), 305)
    
})

test_that("Env returns error for unknown fileType", {

    myEnv <- Env()
    expect_error(myEnv$getModelFilenameFor("BOGUSregression", version=2))

})

test_that("Env returns expected old model filenames", {

    myEnv <- Env()
    regressionFile <- myEnv$getModelFilenameFor("regression", version=2)
    expect_equal(regressionFile,
                 paste0("/pl/active/SierraBighorn/Rdata/forest/twostep/regression/",
                        "ranger.regression.prob3e+05.Rda"))

    classifierFile <- myEnv$getModelFilenameFor("classifier", version=2)
    expect_equal(classifierFile,
                 paste0("/pl/active/SierraBighorn/Rdata/forest/twostep/classification/",
                        "ranger.classifier.prob3e+05.Rda"))

})

test_that("Env returns expected model filenames", {

    myEnv <- Env()
    regressionFile <- myEnv$getModelFilenameFor("regression")
    expect_equal(regressionFile,
                 paste0("/pl/active/SierraBighorn/Rdata/forest/",
                        "ranger.regression.SCA.v03.Rda"))

    classifierFile <- myEnv$getModelFilenameFor("classifier")
    expect_equal(classifierFile,
                 paste0("/pl/active/SierraBighorn/Rdata/forest/",
                        "ranger.classifier.SCA.v03.Rda"))

    predictorFile <- myEnv$getPredictorFilenameFor()
    expect_equal(predictorFile,
                 paste0("/pl/active/SierraBighorn/Rdata/",
                        "predictors.SCA.v00.RData"))
    
})

test_that("Env returns expected downscaled filenames", {

    myEnv <- Env()
    dir <- "/test/out"

    ## Error case
    expect_error(myEnv$getDownscaledFilenameFor(dir,
                                                "bogus",
                                                "SSN",
                                                "20010328"))

    ## Legit cases
    outFile <- myEnv$getDownscaledFilenameFor(dir,
                                              "regression",
                                              "SSN",
                                              "20010328")
    expect_equal(outFile,
                 paste0(dir, "/SSN.downscaled.regression.20010328.v3.3e+05.tif"))

    outFile <- myEnv$getDownscaledFilenameFor(dir,
                                              "downscaled",
                                              "SSN",
                                              "20010328")
    expect_equal(outFile,
                 paste0(dir, "/SSN.downscaled.20010328.v3.3e+05.tif"))

    outFile <- myEnv$getDownscaledFilenameFor(dir,
                                              "prob.btwn",
                                              "SSN",
                                              "20010328")
    expect_equal(outFile,
                 paste0(dir, "/SSN.downscaled.prob.0.100.20010328.v3.3e+05.tif"))

    outFile <- myEnv$getDownscaledFilenameFor(dir,
                                              "prob.hundred",
                                              "SSN",
                                              "20010328")
    expect_equal(outFile,
                 paste0(dir, "/SSN.downscaled.prob.100.20010328.v3.3e+05.tif"))

})

test_that("Env getters are working", {

    myEnv <- Env()
    expect_equal(myEnv$getTopDir(), "/pl/active/SierraBighorn")
    expect_equal(myEnv$getFusionDir(), "/pl/active/SierraBighorn/downscaled")
    expect_equal(myEnv$getLandsatDir(),
                 "/pl/active/SierraBighorn/scag/Landsat/UCSB_v3_processing/SSN")
    expect_equal(myEnv$getCloudyLandsatDir(),
                 paste0("/pl/active/SierraBighorn/scag/Landsat/",
                        "UCSB_v3_processing/SSN_cloudy"))
    expect_equal(myEnv$getModelDir(), "/pl/active/SierraBighorn/Rdata")
    expect_equal(myEnv$getTrain.size(), 3e+05)
    
})

test_that("Env setters are working", {

    myEnv <- Env()

    myEnv$setTopDir("/some/other/directory")
    expect_equal(myEnv$getTopDir(), "/some/other/directory")

    myEnv$setTrain.size(1e+05)
    expect_equal(myEnv$getTrain.size(), 1e+05)
    
})

