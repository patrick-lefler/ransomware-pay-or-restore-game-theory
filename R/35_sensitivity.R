# One-at-a-time swings in R* (each input at its 10th and 90th percentile, others at base),
# plus a market-calibration Monte Carlo with faster restores and stronger backups.

INPUT_NAMES <- c(c = "Outage cost per day", T_r = "Restore time", b = "Backup credibility",
                 T_fail = "Rebuild time if backups fail", q = "Decryptor works",
                 T_d = "Decrypt and validate time", d_pay = "Payment delay",
                 s = "Sanctions nexus", K_pay = "Fixed cost of paying", K_leak = "Leak cost",
                 p_np = "Leak probability, refuse", p_p = "Leak probability, pay")

main_35 <- function() {
  vars <- setdiff(names(INPUT_SPEC), "kappa")
  oat <- purrr::map(vars, \(v) {
    val <- q_input(INPUT_SPEC[[v]], c(0.1, 0.9))
    if (v == "p_p") val <- BASE$p_np * val
    tibble::tibble(
      input = v, label = INPUT_NAMES[[v]], low = val[1], high = val[2],
      R_low = walk_away(modifyList(BASE, setNames(list(val[1]), v))),
      R_high = walk_away(modifyList(BASE, setNames(list(val[2]), v)))
    )
  }) |>
    purrr::list_rbind() |>
    dplyr::mutate(swing = abs(R_high - R_low)) |>
    dplyr::arrange(dplyr::desc(swing))

  mc <- P$monte_carlo
  tr <- unlist(INPUT_SPEC$T_r$par)
  k <- mc$market_T_r_median / mtri(tr[1], tr[2], tr[3])
  spec_mkt <- INPUT_SPEC
  spec_mkt$T_r$par <- as.list(tr * k)
  spec_mkt$b$par <- mc$market_b_par
  base_sim <- simulate_mc(SEED_MC)
  mkt_sim <- simulate_mc(SEED_MC, spec = spec_mkt)

  calib <- tibble::tibble(
    case = c("This firm's ranges", "Market calibration"),
    T_r_median = c(mtri(tr[1], tr[2], tr[3]), mc$market_T_r_median),
    T_r_range = c(paste(tr[c(1, 3)], collapse = "–"), paste(round(tr[c(1, 3)] * k, 1), collapse = "–")),
    b_mean = c(mean(base_sim$b), mean(mkt_sim$b)),
    R_median = c(stats::median(base_sim$R_star), stats::median(mkt_sim$R_star)),
    pay_share = c(mean(base_sim$pay), mean(mkt_sim$pay))
  )
  out <- list(oat = oat, calib = calib, T_r_scale = k)
  save_result(out, "sensitivity")
  invisible(out)
}
