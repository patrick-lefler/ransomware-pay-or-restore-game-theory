# Monte Carlo over the uncertain inputs: first-order variance shares for the walk-away point R*
# and for the pay decision 1{D <= R*}. Shares use a binned conditional-mean estimator.

first_order_share <- function(x, y, n_bins = P$monte_carlo$n_bins) {
  if (stats::var(x) == 0) return(0)
  bins <- dplyr::ntile(x, n_bins)
  cm <- stats::ave(y, bins)
  stats::var(cm) / stats::var(y)
}

DRIVER_VARS <- c("E_T", "T_r", "b", "T_fail", "c", "q", "T_d", "d_pay", "s", "K_pay", "K_leak", "p_np", "p_p")

simulate_mc <- function(seed, n = N_MC, spec = INPUT_SPEC) {
  d <- draw_inputs(n, seed, spec)
  set.seed(seed + 1e6)
  d |>
    dplyr::mutate(
      E_T = expected_T(d),
      R_star = walk_away(d),
      D = stats::rlnorm(n, log(P$monte_carlo$demand_median), P$monte_carlo$demand_sdlog),
      pay = as.numeric(D <= R_star)
    )
}

driver_shares <- function(sim) {
  vars <- intersect(DRIVER_VARS, names(sim))
  dplyr::bind_rows(
    tibble::tibble(target = "R_star", input = vars,
                   share = purrr::map_dbl(vars, \(v) first_order_share(sim[[v]], sim$R_star))),
    tibble::tibble(target = "pay", input = c(vars, "D"),
                   share = purrr::map_dbl(c(vars, "D"), \(v) first_order_share(sim[[v]], sim$pay)))
  )
}

main_30 <- function() {
  sim <- simulate_mc(SEED_MC)
  shares <- driver_shares(sim)
  stability <- purrr::map(seq_len(P$monte_carlo$stability_seeds) - 1, \(k) {
    driver_shares(simulate_mc(SEED_MC + k)) |> dplyr::mutate(seed = SEED_MC + k)
  }) |> purrr::list_rbind()
  summary <- list(
    pay_share = mean(sim$pay), R_median = stats::median(sim$R_star),
    R_q = stats::quantile(sim$R_star, c(0.05, 0.25, 0.5, 0.75, 0.95)),
    never_pay_share = mean(sim$R_star <= 0)
  )
  out <- list(shares = shares, stability = stability, summary = summary)
  save_result(out, "mc_drivers")
  invisible(out)
}
