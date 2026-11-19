# Reads params.yaml into constants. Run with the project root (or a direct child) as working directory.
.root <- if (file.exists("params.yaml")) "." else if (file.exists("../params.yaml")) ".." else
  if (file.exists("../../params.yaml")) "../.." else stop("Run from the project root (params.yaml not found).")
PROJECT_ROOT <- normalizePath(.root)
RESULTS_DIR <- file.path(PROJECT_ROOT, "data", "results")
P <- yaml::read_yaml(file.path(PROJECT_ROOT, "params.yaml"))

INPUT_SPEC <- P$inputs
BASE <- purrr::map(INPUT_SPEC, "base")
BASE$p_p <- BASE$p_np * INPUT_SPEC$p_p$par[[2]]

D_BASE <- P$worked_example$demand
SEED_MC <- P$monte_carlo$seed
N_MC <- P$monte_carlo$n_draws
SEED_REP <- P$reputation$seed

seq_spec <- function(s) round(seq(s$from, s$to, by = s$by), 10)
P0_GRID <- seq_spec(P$reputation$p0_grid)
ETA_FINE <- seq_spec(P$reputation$eta_fine)

PROFILES <- purrr::imap(P$profiles, \(x, nm) modifyList(BASE, x))
PROFILE_ORDER <- c("resilient", "typical", "fragile")
