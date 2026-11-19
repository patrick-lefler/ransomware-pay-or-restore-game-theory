# Diagnostics reported on the Governance page. Reads cached results; run after main_20..main_35.

chk <- function(check, ok, detail) tibble::tibble(check = check, result = if (isTRUE(ok)) "Pass" else "FAIL", detail = detail)

# Event-level simulation of one incident at base: backups, decryptor, sanctions and leak drawn as events.
# Common random numbers: the leak uniform and backup outcome are shared by both paths.
simulate_incident <- function(p, D, n, seed) {
  set.seed(seed)
  backup_ok <- stats::runif(n) < p$b
  decrypt_ok <- stats::runif(n) < p$q
  sanction <- stats::runif(n) < p$s
  u_leak <- stats::runif(n)
  T_restore <- ifelse(backup_ok, p$T_r, p$T_fail)
  refuse <- p$c * T_restore + (u_leak < p$p_np) * p$K_leak
  pay <- D + sanction * p$kappa * D + p$K_pay + p$c * (p$d_pay + ifelse(decrypt_ok, p$T_d, T_restore)) +
    (u_leak < p$p_p) * p$K_leak
  list(refuse = refuse, pay = pay)
}

js_walkaway <- function(cases) {
  ctx <- V8::v8()
  ctx$eval(gsub("export ", "", readLines(file.path(PROJECT_ROOT, "assets", "js", "walkaway.js")), fixed = TRUE))
  purrr::map_dbl(cases, \(p) ctx$call("walkAway", p))
}

main_80 <- function() {
  wa <- read_result("walkaway")
  mc <- read_result("mc_drivers")
  rep <- read_result("reputation")
  R0 <- wa$R_base
  mult <- 1 + BASE$s * BASE$kappa

  # 1 Closed form vs event simulation
  n_sim <- 2e6
  sim <- simulate_incident(BASE, D_BASE, n_sim, SEED_MC + 2)
  diff <- sim$refuse - sim$pay
  se <- stats::sd(diff) / sqrt(n_sim)
  target <- mult * (R0 - D_BASE)
  rel_ref <- abs(mean(sim$refuse) / cost_refuse(BASE) - 1)
  rel_pay <- abs(mean(sim$pay) / cost_pay(BASE, D_BASE) - 1)
  d1 <- chk("Closed form vs simulation",
            rel_ref < 0.005 && rel_pay < 0.005 && abs(mean(diff) - target) < 3 * se,
            sprintf("%s event draws: refuse cost within %.2f%%, pay cost within %.2f%%; mean gap %.3f vs closed form %.3f (3 s.e. = %.3f)",
                    fmt_num(n_sim, 0), 100 * rel_ref, 100 * rel_pay, mean(diff), target, 3 * se))

  # 2 Indifference
  ind <- abs(cost_pay(BASE, R0) - cost_refuse(BASE))
  d2 <- chk("Indifference at the walk-away point", ind < 1e-9, sprintf("|C_pay(R*) − C_refuse| = %.1e", ind))

  # 3 Monotonicity (central differences at base)
  grad <- purrr::map_dbl(c(T_r = "T_r", T_fail = "T_fail", c = "c", q = "q", b = "b", d_pay = "d_pay",
                           K_pay = "K_pay", s = "s"), \(v) {
    h <- 1e-4 * max(1, abs(BASE[[v]]))
    (walk_away(modifyList(BASE, setNames(list(BASE[[v]] + h), v))) -
       walk_away(modifyList(BASE, setNames(list(BASE[[v]] - h), v)))) / (2 * h)
  })
  up <- c("T_r", "T_fail", "c", "q"); down <- c("b", "d_pay", "K_pay", "s")
  d3 <- chk("Monotonicity", all(grad[up] > 0) && all(grad[down] < 0),
            "R* rises with restore time, rebuild time, outage cost and decryptor reliability; falls with backup credibility, payment delay, fixed cost of paying and sanctions risk")

  # 4 JS-R parity
  bs <- c(0.6, 0.8, 0.95)
  cases <- purrr::map(bs, \(b) modifyList(BASE, list(b = b)))
  js <- js_walkaway(cases)
  r <- purrr::map_dbl(cases, walk_away)
  d4 <- chk("JavaScript–R parity (slider 1)", max(abs(js - r)) < 0.005,
            sprintf("b = 0.60, 0.80, 0.95: max difference %.1e", max(abs(js - r))))

  # 5 Attack-rate grid (bounded rule)
  g <- rep$grid
  n_paths <- P$reputation$n_paths
  never <- g |> dplyr::filter(policy == "never")
  bound <- 10 * never$p0 + 3 * sqrt(10 * never$p0 * (1 - never$p0) / n_paths)
  rises <- g |> dplyr::arrange(p0) |>
    dplyr::summarise(cost_up = all(diff(cost_10y) > 0), att_up = all(diff(attacks_10y) >= 0), .by = c(firm, policy))
  d5 <- chk("Attack-rate grid",
            all(abs(g$p_first - g$p0) < 1e-12) && all(never$attacks_10y <= bound) && all(rises$cost_up) && all(rises$att_up),
            sprintf("Year-1 attack probability equals p0 in all %d runs; never-pay attacks at or below 10 × p0 (largest ratio %.2f); cost and attacks rise with p0 for all six firm–policy pairs",
                    nrow(g), max(never$attacks_10y / (10 * never$p0))))

  # 6 Smoothness
  steps <- g |> dplyr::arrange(p0) |>
    dplyr::summarise(ratio = max(diff(cost_10y)) / stats::median(diff(cost_10y)), .by = c(firm, policy))
  d6 <- chk("Smoothness across p0", all(steps$ratio <= 3),
            sprintf("Largest step is %.2f × the median step (limit 3)", max(steps$ratio)))

  # 7 Seed stability, 8 Driver ranking
  st <- mc$stability
  spread <- st |> dplyr::summarise(rng = diff(range(share)), .by = c(target, input))
  d7 <- chk("Seed stability", max(spread$rng) < 0.02,
            sprintf("Variance shares differ by at most %.3f across %d seeds", max(spread$rng), dplyr::n_distinct(st$seed)))
  top <- st |> dplyr::filter(target == "R_star") |> dplyr::slice_max(share, n = 1, by = seed)
  d8 <- chk("Driver ranking", all(top$input == "E_T"),
            sprintf("Expected outage time ranks first for R* in %d of %d seeds", sum(top$input == "E_T"), nrow(top)))

  # 9 Reputation direction
  sq <- rep$demand_seqs
  fr <- g |> dplyr::filter(firm == "fragile", policy == "rational", abs(p0 - P$reputation$p0_base) < 1e-9)
  fr_d <- unlist(fr[, paste0("demand_", 1:4)])
  d9 <- chk("Reputation direction", all(diff(sq$R) < 0) && all(diff(sq$P) > 0) && all(diff(fr_d) > 0),
            sprintf("Demand after successive refusals: %s; fragile firm, rational: %s",
                    paste(fmt_num(sq$R, 2), collapse = " → "), paste(fmt_num(fr_d, 2), collapse = " → ")))

  # 10 Belief normalization
  d10 <- chk("Belief normalization", rep$belief_sum_err < 1e-12,
             sprintf("Max |sum of weights − 1| = %.1e over %d belief states", rep$belief_sum_err, rep$n_nodes))

  # 11 Discounting
  dv <- rep$deviation
  d11 <- chk("Discounting", all(dv$cost_10y_pv <= dv$cost_10y + 1e-12),
             sprintf("Present-value cost at or below the undiscounted cost for all %d policy runs (discount rate %s)",
                     nrow(dv), fmt_pct(P$reputation$discount_rate)))

  # 12 Deviate-once at eta = 0
  e0 <- dv |> dplyr::filter(eta == 0) |>
    dplyr::summarise(gap = cost_10y[policy == "deviate_once"] - cost_10y[policy == "never"], .by = firm)
  d12 <- chk("Deviate once with no targeting response", all(e0$gap <= 1e-9),
             sprintf("With η = 0, paying once costs no more than never paying: %s",
                     paste(sprintf("%s %s", e0$firm, fmt_m(e0$gap, 2)), collapse = "; ")))

  diag <- dplyr::bind_rows(d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12)
  save_result(diag, "diagnostics")
  invisible(diag)
}
