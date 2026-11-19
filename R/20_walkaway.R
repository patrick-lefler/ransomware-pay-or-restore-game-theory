# Reference cases, decision-map boundaries, and the two-paths cost components.

main_20 <- function() {
  ref <- tibble::tribble(
    ~case,                  ~T_r, ~b,
    "Base",                 10,   0.80,
    "Fast restore",         5,    0.80,
    "Slow restore",         14,   0.80,
    "Fragile",              21,   0.60,
    "Resilient",            4,    0.90,
    "Base, weak backups",   10,   0.60,
    "Base, strong backups", 10,   0.95
  ) |>
    dplyr::mutate(R_star = purrr::map2_dbl(T_r, b, \(t, bb) walk_away(modifyList(BASE, list(T_r = t, b = bb)))))

  T_grid <- seq(P$map$T_r_range[[1]], P$map$T_r_range[[2]], by = 0.25)
  boundaries <- tidyr::expand_grid(b = unlist(P$map$b_levels), T_r = T_grid) |>
    dplyr::mutate(R_star = walk_away(modifyList(BASE, list(T_r = T_r, b = b))))

  refuse <- cost_refuse_parts(BASE)
  pay <- cost_pay_parts(BASE, D_BASE)
  two_paths <- dplyr::bind_rows(
    tibble::tibble(path = "Restore", component = names(refuse), cost = unlist(refuse)),
    tibble::tibble(path = paste0("Pay ", fmt_m(D_BASE)), component = names(pay), cost = unlist(pay))
  )

  profiles <- purrr::imap(PROFILES, \(p, nm) tibble::tibble(
    profile = nm, T_r = p$T_r, b = p$b, E_T = expected_T(p), R_star = walk_away(p),
    C_refuse = cost_refuse(p), in_moment_saving = (1 + p$s * p$kappa) * (walk_away(p) - D_BASE)
  )) |> purrr::list_rbind()

  out <- list(
    ref = ref, boundaries = boundaries, two_paths = two_paths, profiles = profiles,
    R_base = walk_away(BASE), slope = walk_away_slope(BASE), T0 = never_pay_restore(BASE),
    C_refuse = cost_refuse(BASE), C_pay = cost_pay(BASE, D_BASE), base = BASE
  )
  save_result(out, "walkaway")
  invisible(out)
}
