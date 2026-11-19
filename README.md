# When Is a Ransom Worth Paying? A Game-Theory Guide for the Board

A 500-person fintech firm (the same firm as the Defender–Attacker study) is hit by ransomware: its platform is encrypted and client data copied. Should it pay or restore from backups, and how should the board decide before it happens? The site derives the firm's **walk-away point** (the largest ransom worth paying), shows that restore time drives it far more than the size of the demand, and simulates a 10-year repeated game in which the crew learns from each payment or refusal.

All values are synthetic and illustrative. Not legal, investment or security advice.

Medium rQuarto project (5 rendered pages: Summary, The Game, Map & Reputation, Governance, and Reproducibility under a "Technical appendix" sidebar section). Specification: `project_spec.md`, on top of the v2 project outline.

## Key results (base case)

| Result | Value |
|---|---|
| Walk-away point at base (10-day restore, backup credibility 0.80) | $2.39M |
| Change in walk-away point per restore day | about $0.31M |
| Cost of refusing vs paying a $2.5M demand on day one vs restoring first and paying only if backups fail | $10.70M vs $10.83M vs $9.23M |
| Share of simulated incidents in which paying $2.5M on day one is cheaper | 64% |
| Walk-away point at input means; without the leak benefit of paying | $3.77M; $1.66M |
| Share of walk-away variation explained by expected outage time | 69% (pay decision: 39% vs 15% for the demand at demand log-sd 0.6; the demand leads at log-sd 1.0 and above) |
| Crew's opening demand | $2.53M |
| 10-year cost at a 15% attack rate, our firm: pay when worth it vs never pay | $15.6M vs $13.2M |
| Credibility test, fragile firm, present value at 8%: pay once then never vs never pay | $16.2M vs $14.0M at η = 1 (credible); $13.5M vs $16.7M at η = 0 (not credible) |
| Break-even targeting response (η) for never pay: our firm / fragile firm | 0.24 / 0.59 |
| Simulated pay share: this firm's ranges vs market-typical restores | 66% vs 9% |

## Reproduce

```sh
Rscript -e 'renv::restore()'           # R >= 4.3, Quarto >= 1.5
Rscript R/run_all.R                    # all analyses + 12 diagnostics (about 14 s)
Rscript -e 'testthat::test_dir("tests/testthat")'
quarto render                          # writes docs/
```

Run `R/run_all.R` from a terminal with `Rscript`, not with `source()` in an R session; it ends with `quit()`. It exits non-zero if any diagnostic fails.

`freeze: auto` re-executes a page only when its own `.qmd` changes. After rerunning `R/run_all.R` or editing a script, delete `_freeze/` or render each page explicitly.

To view the site locally, run `quarto preview`. The sliders need a web server, so they don't work when a page is opened straight from disk; on GitHub Pages they work as is.

## Layout

| Path | Purpose |
|---|---|
| `params.yaml` | Every number: inputs with ranges, seeds, simulation settings, firm profiles |
| `data/inputs.csv` | Labels, units and sources for the inputs table (no numbers) |
| `data/assumptions_register.csv` | Text of the assumptions register (A1–A10, A8b) |
| `R/00_params.R` | Reads `params.yaml` |
| `R/01_utils.R` | Closed-form costs and walk-away point, samplers, formatters |
| `R/20_walkaway.R` | Reference cases, decision-map boundaries, two-paths components |
| `R/30_mc_drivers.R` | 200,000-draw Monte Carlo; first-order variance shares on 5 seeds |
| `R/31_bargaining.R` | Crew belief grid, best demand, Bayesian update, memoised belief tree |
| `R/32_reputation.R` | 10-year repeated game over the attack-rate grid; η sweep |
| `R/35_sensitivity.R` | One-at-a-time swings; market-calibration run |
| `R/80_diagnostics.R` | Ten diagnostics (`diagnostics.rds`) |
| `R/90_theme.R` | Colors, labels, `theme_board()`, `gt_board()`, decision-map helper |
| `R/99_wordcount.R` | Internal prose word counter (terminal only) |
| `assets/js/walkaway.js` | Walk-away formula used by slider 1, and run by the parity check through `V8` |
| `tests/testthat/` | Unit tests against the outline's reference values |
| `data/results/` | Cached results read by the pages |

## Decisions and deviations from the outline

- **Five pages, not four.** Reproducibility is a separate page (house convention); session info and rebuild steps moved there from Governance.
- **Reader notes.** Every table and plot has "How to read" and "What it tells you" paragraphs (`.reader-note` divs, about 75 words each). They are excluded from the 3,000-word prose cap. The outline's short context notes are `.side-note` divs and count toward the cap.
- **Code visibility.** Code is shown folded (house default), not hidden.
- **Diagnostic 1 (closed form vs simulation).** The outline's rule, gap within 0.5% of (1+sκ)(R* − D) = −$0.125M, is below Monte Carlo noise at any feasible draw count. The check instead requires each path's simulated mean cost to be within 0.5% of its closed form (2 million event draws, common random numbers), and the gap to be within 3 standard errors.
- **Diagnostic 5 (attack-rate grid).** Replaced the "≈ 10 × p₀ within 10%" rule, which the outline's own prototype numbers fail: year-1 attack probability equals p₀; never-pay attacks ≤ 10 × p₀ (plus 3 standard errors); cost and attacks rise with p₀.
- **Firm's per-incident walk-away point.** R*_t = R* × exp(0.4 z), matching the crew's incident-noise model; a firm with R* ≤ 0 never pays. Paying saves (1+sκ)(R*_t − D) against the refusal cost.
- **Market calibration.** The base restore-time triangle (3, 10, 30) has a median of 13.6 days, not 10. The market row rescales it so the median is 5 days (range 1.1–11.1), with b ~ Beta(9, 1).
- **Policy label.** "Rational" is shown as "Pay when worth it" for board readers. The "typical" profile is shown as "Our firm" (internal key `typical` unchanged).
- **Static fallbacks.** Shown inside `<noscript>`, not `.content-hidden`. In HTML output, `.content-hidden` would hide them from non-JS readers too.
- **Citations corrected after verification (2026-11-19).** Re-extortion figure is 37% (The Register, Proofpoint data), not "over a third". The Cybereason figures (78%, 63%) are dated February 2024. The Coveware Q2 2026 page does not state 19% in its text, so the site says "a new record low" and cites the verified 23% for Q3 2025. The NYDFS 24-hour and 30-day deadlines are cited to 23 NYCRR 500.17(c), not to the DFS filing instructions.

## Review revisions (2026-11-19)

Implemented the independent review's fix list (P1–P3), with these owner decisions and deviations:

- **Staged path (P1-2, option A).** `cost_staged()` adds "restore first, pay only if backups fail" with `t_detect` (base 2 days, triangular 1–7). The decision maps and the walk-away point remain the day-one choice.
- **Credibility (P1-5).** New `deviate_once` policy and present-value costs at an 8% discount rate. Result: the fragile firm's no-pay policy is credible at η = 1, not "unlikely to survive" as the first draft said; it is not credible at η = 0. The slider grid stays undiscounted.
- **Reader notes (P3-1).** Kept at about 75 words per paragraph (owner decision), not cut to 100 per note; sentences that restated tables were removed.
- **Calibration (P2-1).** The Q2 2026 Coveware page states no overall payment rate in its text (only "a new record low"), so the site does not quote 19%. It cites 23% (Q3 2025) and "nearly 80% resolved without payment" (Q3 2026).
- **Regulatory status (P2-4).** The firm is a privately held, NYDFS-licensed company with listed clients.
- **Related work (P2-6).** No URL was available for the fund-operations study, so the reference was removed.
- **Sidebar (P3-6).** Reproducibility sits under a "Technical appendix" section (owner approved, overriding the flat-sidebar convention).
- **New diagnostics.** Discounting (present value ≤ undiscounted) and deviate-once at η = 0 (never costs more than never paying). New unit tests cover the staged reference values and the base-demand pay share.

## Open items

- **Prototype differences.** At a 25% attack rate, the fragile firm's 10-year cost under "pay when worth it" is $53.0M against $58.7M in the outline's prototype; every other figure is within Monte Carlo error, and all directional findings hold.
