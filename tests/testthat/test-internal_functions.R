test_that(".modifyArray works correctly", {
    # Test basic merging
    x <- c(a = 1, b = 2)
    val <- c(b = 3, c = 4)
    result <- insetplot:::.modifyArray(x, val)

    expected <- c(a = 1, b = 3, c = 4)
    expect_equal(result, expected)

    # Test with NULL values
    x <- c(a = 1, b = 2)
    val <- c(b = NA, c = 4)
    result <- insetplot:::.modifyArray(x, val)

    expected <- c(a = 1, b = NA, c = 4)
    expect_equal(result, expected)

    # Test empty inputs
    expect_equal(insetplot:::.modifyArray(c(), c(a = 1)), c(a = 1))
    expect_equal(insetplot:::.modifyArray(c(a = 1), c()), c(a = 1))
})

test_that(".widest_bbox calculates union correctly", {
    # Test with multiple bounding boxes
    bbox1 <- c(ymin = 0, xmin = 0, xmax = 2, ymax = 2)
    bbox2 <- c(ymin = 1, xmin = 1, xmax = 3, ymax = 3)
    bbox3 <- c(ymin = -1, xmin = -1, xmax = 1, ymax = 1)

    bbox_list <- list(bbox1, bbox2, bbox3)
    result <- insetplot:::.widest_bbox(bbox_list)

    expected <- c(ymin = -1, xmin = -1, xmax = 3, ymax = 3)
    expect_equal(result, expected)

    # Test with single bounding box
    result_single <- insetplot:::.widest_bbox(list(bbox1))
    expect_equal(result_single, bbox1)

    # Test with identical bounding boxes
    result_identical <- insetplot:::.widest_bbox(list(bbox1, bbox1))
    expect_equal(result_identical, bbox1)
})
