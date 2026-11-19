# Closed-form cost model, samplers, formatters and result I/O.
# Every model function takes a list (or data frame) `p` with the inputs named as in params.yaml,
# so it works on one case or vectorized over Monte Carlo draws.

expected_T <- function(p) p$b * p$T_r + (1 - p$b) * p$T_fail

cost_refuse_parts <- function(p) {
  list(outage = p$c * expected_T(p), leak = p$p_np * p$K_leak)
}
cost_refuse <- function(p) purrr::reduce(cost_refuse_parts(p), `+`)

# If the decryptor fails (prob 1 - q) we fall back to restoring from backups.
cost_pay_parts <- function(p, D) {
  list(
    ransom = D,
    sanctions = D * p$s * p$kappa,
    fixed = p$K_pay,
    outage = p$c * (p$d_pay + p$q * p$T_d + (1 - p$q) * expected_T(p)),
    leak = p$p_p * p$K_leak
  )
}
cost_pay <- function(p, D) purrr::reduce(cost_pay_parts(p, D), `+`)

walk_away <- function(p) {
  (p$c * (p$q * (expected_T(p) - p$T_d) - p$d_pay) + (p$p_np - p$p_p) * p$K_leak - p$K_pay) /
    (1 + p$s * p$kappa)
}

# dR*/dT_r
walk_away_slope <- function(p) p$c * p$q * p$b / (1 + p$s * p$kappa)

# Restore time at which R* = 0 (below it, never pay)
never_pay_restore <- function(p) {
  num <- ((p$K_pay - (p$p_np - p$p_p) * p$K_leak) / p$c + p$d_pay) / p$q + p$T_d - (1 - p$b) * p$T_fail
  num / p$b
}

# Triangular inverse CDF
qtri <- function(u, a, m, b) {
  fc <- (m - a) / (b - a)
  ifelse(u < fc, a + sqrt(u * (b - a) * (m - a)), b - sqrt((1 - u) * (b - a) * (b - m)))
}
mtri <- function(a, m, b) qtri(0.5, a, m, b)

# Quantile function for one input spec from params.yaml
q_input <- function(spec, u) {
  par <- unlist(spec$par)
  switch(spec$dist,
    tri = qtri(u, par[1], par[2], par[3]),
    beta = stats::qbeta(u, par[1], par[2]),
    fixed = rep(par[1], length(u)),
    ratio_of_p_np = qtri(u, par[1], par[2], par[3])
  )
}

# Draw n input sets. p_p = p_np x ratio. Optional overrides replace whole columns.
draw_inputs <- function(n, seed, spec = INPUT_SPEC) {
  set.seed(seed)
  u <- matrix(stats::runif(n * length(spec)), ncol = length(spec), dimnames = list(NULL, names(spec)))
  d <- purrr::imap(spec, \(s, nm) q_input(s, u[, nm])) |> tibble::as_tibble()
  d |> dplyr::mutate(p_p = p_np * p_p)
}

# ---- formatting -----------------------------------------------------------
fmt_m <- function(x, digits = 1) {
  s <- formatC(abs(x), format = "f", digits = digits, big.mark = ",")
  paste0(ifelse(x < 0, "−", ""), "$", s, "M")
}
fmt_pct <- function(x, digits = 0) paste0(formatC(100 * x, format = "f", digits = digits), "%")
fmt_num <- function(x, digits = 1) formatC(x, format = "f", digits = digits, big.mark = ",")

# ---- results --------------------------------------------------------------
save_result <- function(x, name) {
  dir.create(RESULTS_DIR, showWarnings = FALSE, recursive = TRUE)
  saveRDS(x, file.path(RESULTS_DIR, paste0(name, ".rds")))
}
read_result <- function(name) readRDS(file.path(RESULTS_DIR, paste0(name, ".rds")))
