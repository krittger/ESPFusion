test_that("StudyExtent throws error for unknown extent", {

    expect_error(StudyExtent("BogusExtent"))

})
test_that("StudyExtent contains expected region information", {

    SSN <- StudyExtent("SouthernSierraNevada")
    expect_equal(SSN$shortName, "SSN")
    expect_equal(SSN$highResRows, 14752)

})
