# CLAUDE.md — Middle-Point Bias Mitigation Analysis (WVS Q130, Prompt 1 vs Prompt 2)

## Project context

Silicon-sampling experiment on WVS Wave 7 **Q130** ("How about people from other countries coming here to work. Which one of the following do you think the
government should do?"). LLMs were prompted with sociodemographic profiles (country, age, sex, education, occupation, self-perceived class) and asked to answer Q130. Aggregated response distributions per country and model are compared against the empirical WVS distributions (ground truth).

**Countries:** Argentina (ARG), Uruguay (URY), United States (USA).

**Response scale (4-point ordinal, no true neutral midpoint):**

1. Let anyone come who wants to
2. Let people come as long as there are jobs available
3. Place strict limits on the number of foreigners who can come here
4. Prohibit people coming here from other countries

Because the scale has no midpoint, "middle-point bias" is operationalized as **interior-category concentration**: excess probability mass on the two interior categories (Let people come as long as there are jobs available + Place strict limits on the number of foreigners who can come here) relative to WVS, equivalently avoidance of the extremes (Let anyone come who wants to / Prohibit people coming here from other countries).

Prompt 2 was designed to mitigate this bias (first-person narrative + anti-moderation instructions). Prompt 1 is the baseline. **The model sets under prompt 1 and prompt 2 do not fully overlap** — this must be handled explicitly (see "Paired design" below).

## Inputs

All files are provided in the working directory:

1. `./outputs_for_analysis/Q130_distributions_empirical.csv` — WVS empirical Q130 distribution per country (ground truth).
2. `./outputs_for_analysis/Q130_distributions_prompt_1.csv` — aggregated Q130 distribution per country × model, prompt 1.
3. `./outputs_for_analysis/Q130_distributions_prompt_2.csv` — aggregated Q130 distribution per country × model, prompt 2.
4. `./outputs_for_analysis/prompts_examples.md` — one example of each prompt (for documentation; quote in the report appendix).


## Preprocessing rules

- WVS distributions may include `Don't know`, `No answer` or similar categories. Drop them and **renormalize** over the 4 substantive categories. Do the same for any model output categories outside the 4-point scale (refusals, malformed answers); report the discarded mass per model × country.
- All distributions must sum to 1 (tolerance 1e-6) after renormalization; assert this.
- Fix category order as the ordinal vector `[Anyone who wants, As long as jobs available, Strict limits, Prohibit]` (positions 1–4) everywhere.

## Paired design (non-overlapping model sets)

Derive this set:

- `M_both` — models tested under both prompts → used for the **paired mitigation test** (H3).

Every prompt 1 vs prompt 2 comparison must be **within-model** (same model, same country, prompt 2 − prompt 1) and restricted to `M_both`. Prompt-level summaries over all models may be shown, but flagged as compositionally non-comparable.

## Hypotheses (reshaped)

- **H1 — Compression:** LLM distributions are more concentrated than WVS: normalized entropy ratio `H(model)/H(WVS) < 1` for most model × country cells (both prompts).
- **H2 — Interior concentration:** LLM interior mass `IM = p(As long as jobs available) + p(Strict limits)` exceeds WVS interior mass: `ΔIM = IM_model − IM_WVS > 0` for most cells under prompt 1.
- **H3 — Mitigation:** For models in `M_both`, prompt 2 reduces interior concentration and compression relative to prompt 1:
  - H3a: `ΔIM(prompt2) < ΔIM(prompt1)` (paired, per model × country).
  - H3b: `H_norm(prompt2) > H_norm(prompt1)` (paired).
  - H3c: `JSD(model, WVS)` under prompt 2 < under prompt 1 (mitigation improves fidelity, not just spread).
- **H4 — Overshoot check (secondary):** Prompt 2 may overcorrect (entropy ratio > 1 or extreme-category mass above WVS). Flag cells where mitigation flips the sign of `ΔIM` or pushes entropy ratio above 1.

H3c matters: an anti-moderation prompt can raise entropy while moving *away* from WVS. Mitigation is only successful if divergence from ground truth also drops.

## Metrics

Compute per model × country × prompt (and for WVS per country):

1. **Shannon entropy**, normalized: `H_norm = −Σ p_i log2 p_i / log2 4` ∈ [0,1]. Use `0·log 0 = 0`.
2. **Entropy ratio:** `H_norm(model) / H_norm(WVS)`.
3. **Interior mass:** `IM = p2 + p3`; **ΔIM = IM_model − IM_WVS**.
4. **Extreme mass:** `EM = p1 + p4` (redundant with IM but convenient for plots).
5. **Jensen–Shannon divergence** (base 2) between model and WVS distribution.
6. **Wasserstein-1 / Earth Mover's Distance on the ordinal scale** (categories at positions 1–4): `W1 = Σ_k |CDF_model(k) − CDF_WVS(k)|`. This captures directional shift along the scale that JSD misses.
7. **Per-category signed error:** `p_model(k) − p_WVS(k)` for each of the 4 categories.
8. **Mean scale position** `μ = Σ k·p_k` and its deviation from WVS `Δμ` (detects lean toward "interested" vs "not interested" side, separate from compression).

Paired mitigation effects, for `M_both` only, per model × country:

- `Δ(IM) = IM_p2 − IM_p1`
- `Δ(H_norm) = H_p2 − H_p1`
- `Δ(JSD) = JSD_p2 − JSD_p1` (negative = fidelity improvement)
- `Δ(W1) = W1_p2 − W1_p1`

## Statistical tests

Cells are model × country aggregates (small N of cells, distributions not independent across countries within a model). Use:

- **Wilcoxon signed-rank test** on paired differences (`Δ(IM)`, `Δ(H_norm)`, `Δ(JSD)`), pooled across countries and also per country. Report effect size (matched-pairs rank-biserial correlation) alongside p-values.
- **Sign test** as robustness check (count of models improving vs worsening).
- Do not run tests that assume independence across the 3 country cells of the same model when pooling; if pooling, aggregate to one value per model first (mean across countries), n = |M_both|.
- Given small n, emphasize effect sizes and per-model tables over p-values.

## Analysis steps

1. Load and validate all inputs; build tidy long table: `country, model, prompt, category, p`. Derive `M_both`.
2. Compute all metrics (section above) into a metrics table: one row per model × country × prompt.
3. Baseline bias characterization (H1, H2): tables + summary of how many cells show `entropy ratio < 1` and `ΔIM > 0`, per prompt.
4. Paired mitigation analysis (H3) on `M_both`: paired-difference table, Wilcoxon/sign tests, per-country breakdown.
5. Overshoot check (H4): list flagged cells.
6. Figures (save to `figures/`):
   - Grouped bar: WVS vs model distributions per country (one panel per country; prompt 1 and prompt 2 side by side for `M_both` models).
   - Dumbbell/slope plot: `IM` prompt 1 → prompt 2 per model, per country, with WVS `IM` as reference line.
   - Scatter: `Δ(H_norm)` vs `Δ(JSD)` per model × country — quadrants distinguish "more spread + closer to WVS" (true mitigation) from "more spread + farther from WVS" (overshoot).
   - Heatmap of per-category signed errors, model × category, faceted by country × prompt.
8. Write `results/report.md`: methods, tables (markdown), figure references, explicit verdicts per hypothesis, limitations (non-overlapping model sets, single question, aggregate-level analysis without per-response counts if raw N unavailable).

## Output layout

```
results/
  metrics.csv            # model × country × prompt metrics
  paired_differences.csv # M_both paired deltas + tests
  report.md
figures/
  *.png (300 dpi)
```

## Conventions

- Language: R (tidyverse) preferred; Python (pandas/scipy) acceptable if R unavailable. One reproducible script or Quarto/notebook, no manual steps.
- No hard-coded distributions: everything read from input files.
- Seed any stochastic step (none expected).
- If per-cell sample sizes (number of LLM responses per distribution) are available in the inputs, use them for multinomial-based uncertainty (bootstrap CIs on IM, entropy, JSD); if not, state in the report that inference is over models as units, not responses.
- Keep category labels exactly as in WVS wording in all outputs.
