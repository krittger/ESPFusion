test_that("Env returns expected region information", {

    myEnv <- Env()
    extent <- myEnv$getExtent("SouthernSierraNevada")
    expect_equal(extent$shortName, "SSN")

})
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
