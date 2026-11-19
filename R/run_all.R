# Runs the whole analysis, then the diagnostics. From the project root:
#   Rscript R/run_all.R
for (f in c("R/00_params.R", "R/01_utils.R", "R/20_walkaway.R", "R/30_mc_drivers.R",
            "R/31_bargaining.R", "R/32_reputation.R", "R/35_sensitivity.R", "R/80_diagnostics.R")) source(f)

t0 <- Sys.time()
main_20(); main_30(); main_32(); main_35()
diag <- main_80()
print(as.data.frame(diag[, c("check", "result")]), right = FALSE)

if (file.exists("R/99_wordcount.R")) system2("Rscript", "R/99_wordcount.R")

cat(sprintf("run_all finished in %.1f s\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
quit(status = if (all(diag$result == "Pass")) 0 else 1)
