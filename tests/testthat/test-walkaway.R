root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
old_wd <- setwd(root)
for (f in c("R/00_params.R", "R/01_utils.R", "R/31_bargaining.R")) source(f)
setwd(old_wd)

case <- function(T_r, b) modifyList(BASE, list(T_r = T_r, b = b))

test_that("walk-away point matches the outline's reference cases", {
  ref <- tibble::tribble(
    ~T_r, ~b,   ~R,
    10,   0.80,  2.39,
    5,    0.80,  0.84,
    14,   0.80,  3.62,
    21,   0.60,  6.87,
    4,    0.90, -0.67,
    10,   0.60,  4.32,
    10,   0.95,  0.94
  )
  got <- purrr::map2_dbl(ref$T_r, ref$b, \(t, b) walk_away(case(t, b)))
  expect_true(all(abs(got - ref$R) < 0.01))
})

test_that("worked example costs match at D = 2.5", {
  expect_equal(cost_refuse(BASE), 10.70, tolerance = 0.005, scale = 1)
  expect_equal(cost_pay(BASE, 2.5), 10.83, tolerance = 0.005, scale = 1)
  parts <- cost_pay_parts(BASE, 2.5)
  expect_equal(parts$outage, 5.17, tolerance = 0.005, scale = 1)
  expect_equal(parts$sanctions, 0.25)
})

test_that("indifference holds at the walk-away point", {
  R <- walk_away(BASE)
  expect_lt(abs(cost_pay(BASE, R) - cost_refuse(BASE)), 1e-9)
})

test_that("slope is about $0.31M per restore day and zero-crossing is consistent", {
  expect_equal(walk_away_slope(BASE), 0.309, tolerance = 0.001, scale = 1)
  t0 <- never_pay_restore(BASE)
  expect_lt(abs(walk_away(case(t0, BASE$b))), 1e-9)
})

test_that("triangular sampler has the right mean", {
  set.seed(1)
  x <- qtri(runif(2e5), 3, 10, 30)
  expect_equal(mean(x), (3 + 10 + 30) / 3, tolerance = 0.01)
})

test_that("crew's opening demand is about $2.5M and beliefs stay normalized", {
  b0 <- crew_prior()
  expect_equal(sum(b0$w), 1, tolerance = 1e-12)
  expect_equal(best_demand(b0)$D, 2.52, tolerance = 0.01, scale = 1)
  b1 <- update_belief(b0, best_demand(b0)$D, paid = FALSE)
  expect_equal(sum(b1$w), 1, tolerance = 1e-12)
  expect_lt(best_demand(b1)$D, best_demand(b0)$D)
})
