# Site theme: colors, labels, ggplot theme and gt style.
COL_PAY <- "#F2C46D"      # pay region (35% alpha)
COL_NOPAY <- "#0166CC"    # don't-pay region (15% alpha)
COL_LINE <- "#3A3A3A"
COL_REF <- "#9A9A9A"
POLICY_COLS <- c(never = "#0166CC", rational = "#C2571A")     # validated: CVD ΔE 26
POLICY_LABELS <- c(never = "Never pay", rational = "Pay when worth it")
FIRM_LABELS <- c(resilient = "Resilient", typical = "Typical", fragile = "Fragile")
COMPONENT_LABELS <- c(outage = "Outage", leak = "Data leak", ransom = "Ransom",
                      sanctions = "Sanctions exposure", fixed = "Payment costs")
COMPONENT_COLS <- c(Outage = "#2a78d6", `Data leak` = "#eb6834", Ransom = "#1baf7a",
                    `Sanctions exposure` = "#eda100", `Payment costs` = "#e87ba4")
DRIVER_LABELS <- c(E_T = "Expected outage time", T_r = "Restore time", b = "Backup credibility",
                   T_fail = "Rebuild time if backups fail", c = "Outage cost per day",
                   q = "Decryptor works", T_d = "Decrypt and validate time", d_pay = "Payment delay",
                   s = "Sanctions nexus", K_pay = "Fixed cost of paying", K_leak = "Leak cost",
                   p_np = "Leak probability, refuse", p_p = "Leak probability, pay", D = "Ransom demand")

theme_board <- function(base_size = 13) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", hjust = 0),
      plot.title.position = "plot",
      plot.subtitle = ggplot2::element_text(color = "gray35", hjust = 0),
      plot.caption = ggplot2::element_text(color = "gray45", hjust = 0),
      plot.caption.position = "plot",
      panel.grid.minor = ggplot2::element_blank(),
      axis.title = ggplot2::element_text(color = "gray30"),
      legend.position = "top",
      legend.justification = "left"
    )
}
ggplot2::theme_set(theme_board())

gt_board <- function(tbl) {
  tbl |>
    gt::tab_options(
      table.font.size = gt::px(14),
      container.overflow.x = TRUE,
      column_labels.background.color = "#F2F2F2",
      column_labels.font.weight = "bold",
      table.border.top.style = "none",
      heading.align = "left",
      data_row.padding = gt::px(5)
    )
}

# Decision-map base: pay region below the boundary, don't-pay above, clipped to the plotting window.
decision_map <- function(boundaries, b_focus, D_max = P$map$D_range[[2]]) {
  focus <- boundaries |> dplyr::filter(abs(b - b_focus) < 1e-9) |>
    dplyr::mutate(ymax = pmin(pmax(R_star, 0), D_max))
  ggplot2::ggplot() +
    ggplot2::geom_ribbon(data = focus, ggplot2::aes(T_r, ymin = 0, ymax = ymax), fill = COL_PAY, alpha = 0.35) +
    ggplot2::geom_ribbon(data = focus, ggplot2::aes(T_r, ymin = ymax, ymax = D_max), fill = COL_NOPAY, alpha = 0.15) +
    ggplot2::scale_x_continuous("Restore time from backups (days)", expand = c(0, 0), breaks = c(1, 5, 10, 15, 20, 25, 30)) +
    ggplot2::scale_y_continuous("Ransom demand", labels = \(x) paste0("$", x, "M"), expand = c(0, 0)) +
    ggplot2::coord_cartesian(xlim = unlist(P$map$T_r_range), ylim = c(0, D_max), clip = "on")
}
