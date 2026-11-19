# The crew's belief about the firm's typical walk-away point, its posted demand, and the
# Bayesian update after the firm pays or refuses.
# Belief: discrete grid over g = log(Rbar) with weights w. Incident noise: log R*_t = g + eps.

crew_prior <- function(bp = P$bargaining) {
  mu <- log(bp$prior_median)
  g <- seq(mu - bp$grid_sd_span * bp$prior_sdlog, mu + bp$grid_sd_span * bp$prior_sdlog,
           length.out = bp$grid_n)
  w <- stats::dnorm(g, mu, bp$prior_sdlog)
  list(g = g, w = w / sum(w))
}

# P(R*_t >= D | g) for each grid point
accept_lik <- function(belief, D, sd_inc = P$bargaining$incident_sdlog) {
  stats::pnorm((belief$g - log(D)) / sd_inc)
}

p_accept <- function(belief, D) sum(belief$w * accept_lik(belief, D))

# Demand that maximizes the crew's expected take D * P(pay)
best_demand <- function(belief) {
  ld <- seq(log(0.02), log(200), length.out = 1500)
  take <- purrr::map_dbl(ld, \(x) exp(x) * p_accept(belief, exp(x)))
  i <- which.max(take)
  opt <- stats::optimize(\(x) -exp(x) * p_accept(belief, exp(x)),
                         c(ld[max(1, i - 1)], ld[min(length(ld), i + 1)]), tol = 1e-10)
  D <- exp(opt$minimum)
  list(D = D, p_pay = p_accept(belief, D), ev = D * p_accept(belief, D))
}

update_belief <- function(belief, D, paid) {
  lik <- accept_lik(belief, D)
  w <- belief$w * if (paid) lik else 1 - lik
  belief$w <- w / sum(w)
  belief
}

# Memoised belief tree keyed by pay/refuse history, e.g. "" (no incidents), "R", "RP", ...
make_belief_tree <- function() {
  env <- new.env()
  env[[".root"]] <- local({
    b <- crew_prior()
    c(list(belief = b), best_demand(b))
  })
  get_node <- function(h) {
    key <- if (h == "") ".root" else h
    if (!is.null(env[[key]])) return(env[[key]])
    parent <- get_node(substr(h, 1, nchar(h) - 1))
    b <- update_belief(parent$belief, parent$D, paid = substr(h, nchar(h), nchar(h)) == "P")
    node <- c(list(belief = b), best_demand(b))
    env[[key]] <- node
    node
  }
  list(get = get_node, env = env)
}
