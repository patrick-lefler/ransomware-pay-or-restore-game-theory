# Project spec: Pay or Restore? A Ransomware Bargaining Game for the Board

Source outline: `2026-11-18_rQuarto_Pay-or-Restore-Game-Project-Outline.md` (v2). That outline governs the model, its inputs, the figures and the build order. This spec records only the decisions and changes made on top of it.

**Tier: Medium (5 rendered pages)**, plus `license.qmd`, which doesn't count toward the tier.

## Page table

| # | File | Sidebar label | Main prose words | Figures and tables |
|---|---|---|---|---|
| 1 | `index.qmd` | Summary | 650 | `fig-hero`, `tbl-policy` |
| 2 | `game.qmd` | The Game | 800 | `fig-two-paths`, `tbl-inputs`, `fig-drivers` |
| 3 | `map-reputation.qmd` | Map & Reputation | 950 | `fig-map` (slider 1), `fig-demand-path`, `fig-ten-year` (slider 2), `tbl-eta` |
| 4 | `governance.qmd` | Governance | 600 | `tbl-assumptions`, `tbl-sensitivity`, `tbl-diagnostics`, limitations |
| 5 | `reproducibility.qmd` | Reproducibility | template | checksum table, test results, session info |

## Decisions added on top of the outline (2026-11-19)

1. **Reader notes:** every table and plot gets two paragraphs, "How to read" and "What it tells you", of about 75 words each, as the `rquarto-project` skill requires. These paragraphs sit in `.reader-note` divs, matching the series, and are **excluded** from the ~3,000-word prose cap. The outline's short notes (≤ 100 words, at most two per page) became `.side-note` divs, which still count toward the cap.
2. **Reproducibility page:** a separate fifth page built from the `rquarto-reproducibility` template. The Reproduce section and session info move off Governance and onto this page.
3. **Attack-rate diagnostic, replacing the "≈ 10 × p₀ within 10%" rule:** pass if (a) first-attack probability in year 1 equals p₀ exactly; (b) expected 10-year attacks under never pay are ≤ 10 × p₀ (refusals can only lower the rate) and rise with p₀; and (c) 10-year cost rises with p₀ for every firm and policy.
4. **Code visibility:** keep the house default, `echo: true` with code folded and code-tools on.

## House conventions that override the outline's `_quarto.yml` snippet

- I keep the existing `_quarto.yml`, which follows the house template: floating left sidebar, `theme: [sandstone, theme.scss]` instead of `styles.css`, the standard footer, and search off. I update the `render:` list and sidebar to the five pages.
- Logo and favicon go in `assets/images/`, copied from the skill.
- `author:` and `date:` appear on `index.qmd` only. Page 1 opens with an **Introduction** section that holds the pull quote and the three-sentence answer. There's no abstract.
- Environment: `renv` (installs with pak). I commit `.Rprofile`, `renv.lock`, `renv/activate.R` and `renv/settings.json`. `sessioninfo` is added.
- The two OJS sliders count as approved interactivity, as the outline specifies. No plotly.
- Citations: I'll check every URL in the outline before it goes on the site. Any I can't verify get flagged to the owner and are not stated as fact.
- The project folder and repo are the existing `2026-11-19_rQuarto_ransomware-pay-or-restore-game-theory` and `patrick-lefler/ransomware-pay-or-restore-game-theory`, not the names in the outline.
- Commit and push only when the owner asks.
