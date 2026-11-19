# 10-year repeated game. Each year the crew attacks with probability
#   p_t = min(p_cap, p0 * (EV_t / EV_0)^eta),
# where EV_t is the crew's expected take at its current belief. When attacked, the firm's
# walk-away point for that incident is R*_t = R* x exp(sd_inc * z) (never positive if R* <= 0).
# Rational firms pay when D <= R*_t; never-pay firms always refuse; deviate-once firms pay at the
# first incident if D <= R*_t and refuse every incident after it.
# Present-value cost discounts a year-t incident by (1 + r)^-t.
# Incident cost: refuse = C_refuse; pay = C_refuse - (1 + s kappa)(R*_t - D).
# Common random numbers: the same uniforms U and normals Z are used for every p0, eta, firm and policy.

rep_draws <- function(seed = SEED_REP, n = P$reputation$n_paths, years = P$reputation$years) {
  set.seed(seed)
  list(U = matrix(stats::runif(n * years), n, years), Z = matrix(stats::rnorm(n * years), n, years))
}

simulate_reputation <- function(profile, policy, p0, eta, draws, tree) {
  rp <- P$reputation
  n <- nrow(draws$U)
  sd_inc <- P$bargaining$incident_sdlog
  R <- walk_away(profile)
  C_ref <- cost_refuse(profile)
  mult <- 1 + profile$s * profile$kappa
  ev0 <- tree$get("")$ev
  hist <- rep("", n)
  n_att <- integer(n)
  cost <- numeric(n)
  cost_pv <- numeric(n)
  r <- rp$discount_rate
  dem <- matrix(NA_real_, n, 4)
  p_first <- NA_real_
  for (t in seq_len(rp$years)) {
    uk <- unique(hist)
    nodes <- lapply(uk, tree$get)
    idx <- match(hist, uk)
    D <- vapply(nodes, `[[`, 0, "D")[idx]
    ev <- vapply(nodes, `[[`, 0, "ev")[idx]
    p_t <- pmin(rp$p_cap, p0 * (ev / ev0)^eta)
    if (t == 1) p_first <- p_t[1]
    hit <- draws$U[, t] < p_t
    R_t <- if (R > 0) R * exp(sd_inc * draws$Z[, t]) else rep(-Inf, n)
    willing <- policy == "rational" | (policy == "deviate_once" & n_att == 0)
    pay <- hit & willing & D <= R_t
    inc <- ifelse(hit, C_ref - ifelse(pay, mult * (R_t - D), 0), 0)
    cost <- cost + inc
    cost_pv <- cost_pv + inc / (1 + r)^t
    k <- n_att + 1
    rec <- hit & k <= 4
    dem[cbind(which(rec), k[rec])] <- D[rec]
    n_att <- n_att + hit
    hist[hit] <- paste0(hist[hit], ifelse(pay[hit], "P", "R"))
  }
  tibble::tibble(
    cost_10y = mean(cost), cost_10y_pv = mean(cost_pv), attacks_10y = mean(n_att), p_first = p_first,
    demand_1 = mean(dem[, 1], na.rm = TRUE), demand_2 = mean(dem[, 2], na.rm = TRUE),
    demand_3 = mean(dem[, 3], na.rm = TRUE), demand_4 = mean(dem[, 4], na.rm = TRUE),
    n_reach_4 = sum(!is.na(dem[, 4]))
  )
}

run_grid <- function(grid, draws, tree) {
  grid |>
    dplyr::mutate(res = purrr::pmap(list(firm, policy, p0, eta), \(f, pol, p, e)
      simulate_reputation(PROFILES[[f]], pol, p, e, draws, tree))) |>
    tidyr::unnest(res)
}

main_32 <- function() {
  draws <- rep_draws()
  tree <- make_belief_tree()
  rp <- P$reputation
  policies <- c("rational", "never")

  grid <- run_grid(tidyr::expand_grid(p0 = P0_GRID, firm = PROFILE_ORDER, policy = policies,
                                      eta = rp$eta_base), draws, tree)
  eta <- run_grid(tidyr::expand_grid(eta = ETA_FINE, firm = c("typical", "fragile"), policy = policies,
                                     p0 = rp$p0_base), draws, tree)

  break_even <- eta |>
    dplyr::select(eta, firm, policy, cost_10y) |>
    tidyr::pivot_wider(names_from = policy, values_from = cost_10y) |>
    dplyr::mutate(gap = rational - never) |>
    dplyr::summarise(eta_star = {
      i <- which(diff(sign(gap)) != 0)[1]
      if (is.na(i)) NA_real_ else eta[i] - gap[i] * (eta[i + 1] - eta[i]) / (gap[i + 1] - gap[i])
    }, .by = firm)

  # Credibility test: never pay vs pay once then never, at base p0, at base eta and at eta = 0
  deviation <- run_grid(tidyr::expand_grid(eta = c(rp$eta_base, 0), firm = c("typical", "fragile"),
                                           policy = c("never", "deviate_once", "rational"), p0 = rp$p0_base),
                        draws, tree) |>
    dplyr::select(eta, firm, policy, cost_10y, cost_10y_pv, attacks_10y)

  # Deterministic demand sequences along all-refuse and all-pay histories
  seqs <- purrr::map(c(R = "R", P = "P"), \(ch) purrr::map_dbl(0:3, \(k) tree$get(strrep(ch, k))$D))

  nodes <- ls(tree$env, all.names = TRUE)
  wsum <- vapply(nodes, \(k) sum(tree$env[[k]]$belief$w), 0)

  out <- list(grid = grid, eta = eta, break_even = break_even, demand_seqs = seqs, deviation = deviation,
              belief_sum_err = max(abs(wsum - 1)), n_nodes = length(nodes), opening = tree$get("")$D)
  save_result(out, "reputation")
  save_result(grid |> dplyr::select(p0, firm, policy, cost_10y, attacks_10y, demand_1:demand_4),
              "reputation_grid")
  invisible(out)
}
