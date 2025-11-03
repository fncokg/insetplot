# Test suite for inset_spec function

test_that("inset_spec creates valid main plot specification", {
    main_spec <- inset_spec(main = TRUE)
    expect_is(main_spec, "list")
    expect_true(main_spec$main)
    expect_true(all(is.na(main_spec$bbox)))
})

test_that("inset_spec creates valid inset with explicit bbox", {
    spec <- inset_spec(
        xmin = -120, xmax = -100, ymin = 30, ymax = 50,
        loc = "right bottom", width = 0.3
    )
    expect_is(spec, "list")
    expect_false(spec$main)
    expect_equal(unname(spec$bbox["xmin"]), -120)
    expect_equal(spec$width, 0.3)
})

test_that("inset_spec creates valid inset with scale_factor", {
    spec <- inset_spec(
        xmin = -120, xmax = -100, ymin = 30, ymax = 50,
        scale_factor = 0.5
    )
    expect_is(spec, "list")
    expect_equal(spec$scale_factor, 0.5)
})

test_that("inset_spec validates bbox constraints", {
    # xmin >= xmax
    expect_error(
        inset_spec(xmin = -100, xmax = -120, ymin = 30, ymax = 50),
        "xmin must be less than xmax"
    )
    # ymin >= ymax
    expect_error(
        inset_spec(xmin = -120, xmax = -100, ymin = 50, ymax = 30),
        "ymin must be less than ymax"
    )
})

test_that("inset_spec validates location strings", {
    expect_error(
        inset_spec(xmin = -120, xmax = -100, ymin = 30, ymax = 50, loc = "invalid"),
        "is not TRUE"
    )
})

test_that("inset_spec validates width and height ranges", {
    expect_error(
        inset_spec(xmin = -120, xmax = -100, ymin = 30, ymax = 50, width = -0.5),
        "width must be between 0 and 1"
    )
})
