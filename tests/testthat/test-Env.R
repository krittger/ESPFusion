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

