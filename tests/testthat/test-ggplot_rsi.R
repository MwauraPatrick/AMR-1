context("ggplot_rsi.R")

test_that("ggplot_rsi works", {

  skip_if_not("ggplot2" %in% rownames(installed.packages()))

  library(dplyr)
  library(ggplot2)

  # data should be equal
  expect_equal(
    (septic_patients %>% select(amcl, cipr) %>% ggplot_rsi())$data %>%
      summarise_all(portion_IR) %>% as.double(),
    septic_patients %>% select(amcl, cipr) %>%
      summarise_all(portion_IR) %>% as.double()
  )

  expect_equal(
    (septic_patients %>% select(amcl, cipr) %>% ggplot_rsi(x = "Interpretation", facet = "Antibiotic"))$data %>%
      summarise_all(portion_IR) %>% as.double(),
    septic_patients %>% select(amcl, cipr) %>%
      summarise_all(portion_IR) %>% as.double()
  )

  expect_equal(
    (septic_patients %>% select(amcl, cipr) %>% ggplot_rsi(x = "Antibiotic", facet = "Interpretation"))$data %>%
      summarise_all(portion_IR) %>% as.double(),
    septic_patients %>% select(amcl, cipr) %>%
      summarise_all(portion_IR) %>% as.double()
  )

})