test_that("Env returns expected region information", {

    myEnv <- Env()
    expect_equal(myEnv$getRegionShortName(), "SSN")

})
test_that("Env returns good v01 MODIS filenames", {

    myEnv <- Env()
    fileName <- myEnv$modisFileFor(1, 2004, 32, "snow_cover_percent")
    print(fileName)
    expect_equal(fileName,
                 paste0("/pl/active/SierraBighorn/scag/MODIS/SSN/v01/",
                        "SSN.SN_WY2004_20040201.Terra-MODIS.snow_cover_percent.v01.tif"))
    
})
