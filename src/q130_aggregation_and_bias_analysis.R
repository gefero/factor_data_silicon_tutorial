# Q130 middle-point bias: aggregation + mitigation analysis — R replication
#
# Replicates src/q130_aggregation_and_bias_analysis.ipynb (i.e.
# src/aggregate_q130.py + src/analyze_q130_bias.py) in R / tidyverse.
#
# Part 1 recomputes the aggregated Q130 distributions from the raw
# per-respondent files in output_data/ and asserts they match the committed
# CSVs in outputs_for_analysis/ exactly.
# Part 2 recomputes all metrics and paired tests, asserts the point estimates
# match the Python pipeline's results/metrics.csv to < 1e-9, and writes:
#
#     results_R/metrics.csv
#     results_R/paired_differences.csv
#     figures_R/*.png (300 dpi, ggplot2)
#
# Bootstrap CIs use R's RNG (set.seed(42)) and therefore differ from the
# Python CIs in the third decimal or so; all deterministic quantities match.
#
# Run from the repo root:  Rscript src/q130_aggregation_and_bias_analysis.R

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(purrr)
  library(stringr)
  library(ggplot2)
})

set.seed(42)
N_BOOT <- 2000L
pdf(NULL)  # keep Rscript from writing Rplots.pdf as a side effect

root <- if (dir.exists("output_data")) "." else ".."
stopifnot(dir.exists(file.path(root, "output_data")))
in_dir  <- file.path(root, "outputs_for_analysis")
res_dir <- file.path(root, "results_R")
fig_dir <- file.path(root, "figures_R")
dir.create(res_dir, showWarnings = FALSE)
dir.create(fig_dir, showWarnings = FALSE)

categories <- c(
  "Let anyone come who wants to",
  "Let people come as long as there are jobs available",
  "Place strict limits on the number of foreigners who can come here",
  "Prohibit people coming here from other countries"
)
invalid_label <- "invalid/no answer"
countries_keep <- c("Argentina", "Uruguay", "United States")

# palette (validated; same slots as the Python pipeline)
surface  <- "#fcfcfb"
ink      <- "#0b0b0b"
ink2     <- "#52514e"
muted    <- "#898781"
gridcol  <- "#e1e0d9"
baseline <- "#c3c2b7"
series_cols <- c(
  "WVS"          = "#2a78d6",
  "gpt-4o"       = "#008300",
  "gpt-oss-120B" = "#e87ba4",
  "gpt-oss-20B"  = "#eda100"
)

theme_viz <- theme_minimal(base_size = 10) +
  theme(
    plot.background   = element_rect(fill = surface, colour = NA),
    panel.background  = element_rect(fill = surface, colour = NA),
    panel.grid.major  = element_line(colour = gridcol, linewidth = 0.3),
    panel.grid.minor  = element_blank(),
    text              = element_text(colour = ink2),
    axis.text         = element_text(colour = muted),
    strip.text        = element_text(colour = ink2, face = "plain"),
    plot.title        = element_text(colour = ink, size = 12),
    legend.position   = "top"
  )

# ------------------------------------------------------------ Part 1 -------
# Aggregate raw per-respondent results (replicates src/aggregate_q130.py)

aggregate_file <- function(filename, model, size, answer_col) {
  df <- read_csv(file.path(root, "output_data", filename),
                 show_col_types = FALSE)
  df |>
    mutate(category = coalesce(.data[[answer_col]], invalid_label)) |>
    count(country, category, name = "n") |>
    group_by(country) |>
    mutate(proportion = n / sum(n)) |>
    ungroup() |>
    mutate(model = model, size = size, .before = 1)
}

v1_sources <- list(
  list("gpt-4o_V1_WVS_silicon_empirico_results.csv",       "gpt-4o",  "4o",   "q130_model"),
  list("gpt-oss_20b_V1_WVS_silicon_empirico_results.csv",  "gpt-oss", "20B",  "q130_model"),
  list("gpt-oss_120b_V1_WVS_silicon_empirico_results.csv", "gpt-oss", "120B", "q130_model")
)
# in the v2 files the simulated answer lives in the column named "model"
v2_sources <- list(
  list("gpt-4o_Q130_v2_WVS_silicon_empirico_results.csv",       "gpt-4o",  "4o",   "model"),
  list("gpt-oss_20B_Q130_v2_WVS_silicon_empirico_results.csv",  "gpt-oss", "20B",  "model"),
  list("gpt-oss_120B_Q130_v2_WVS_silicon_empirico_results.csv", "gpt-oss", "120B", "model")
)

build <- function(sources) {
  map(sources, \(s) aggregate_file(s[[1]], s[[2]], s[[3]], s[[4]])) |>
    list_rbind() |>
    arrange(model, size, country, category)
}

build_empirical <- function() {
  read_csv(file.path(root, "input_data", "WVS_wave7_migracion_prompts.csv"),
           show_col_types = FALSE) |>
    filter(B_COUNTRY_LABEL %in% countries_keep, Q130 %in% categories) |>
    count(country = B_COUNTRY_LABEL, category = Q130, name = "n") |>
    group_by(country) |>
    mutate(proportion = n / sum(n)) |>
    ungroup() |>
    mutate(model = "empirical", size = "-", .before = 1) |>
    arrange(country, category)
}

check_against_committed <- function(agg, file) {
  ref <- read_csv(file.path(in_dir, file), show_col_types = FALSE)
  stopifnot(
    nrow(agg) == nrow(ref),
    all(agg$model == ref$model), all(agg$country == ref$country),
    all(agg$category == ref$category), all(agg$n == ref$n),
    max(abs(agg$proportion - ref$proportion)) < 1e-12
  )
  message("Part 1 check OK: recomputed aggregation matches ", file)
}

check_against_committed(build(v1_sources), "Q130_distributions_prompt_1.csv")
check_against_committed(build(v2_sources), "Q130_distributions_prompt_2.csv")
check_against_committed(build_empirical(), "Q130_distributions_empirical.csv")

# ------------------------------------------------------------ Part 2 -------
# Load, validate, renormalize (replicates analyze_q130_bias.py)

load_distributions <- function(file, prompt) {
  raw <- read_csv(file.path(in_dir, file), show_col_types = FALSE) |>
    mutate(model_key = if_else(
      size == "-" | str_detect(model, fixed(size)), model,
      paste(model, size, sep = "-")
    ))
  discarded <- raw |>
    filter(!category %in% categories) |>
    group_by(model = model_key, country) |>
    summarise(discarded_n = sum(n), discarded_mass = sum(proportion),
              .groups = "drop") |>
    mutate(prompt = prompt)
  tidy <- raw |>
    filter(category %in% categories) |>
    group_by(model = model_key, country) |>
    complete(category = categories, fill = list(n = 0)) |>
    mutate(p = n / sum(n)) |>
    ungroup() |>
    mutate(prompt = prompt,
           category = factor(category, levels = categories)) |>
    arrange(country, model, category)
  stopifnot(
    tidy |> summarise(s = sum(p), .by = c(country, model)) |>
      pull(s) |> (\(s) all(abs(s - 1) < 1e-6))()
  )
  list(tidy = tidy, discarded = discarded)
}

emp <- load_distributions("Q130_distributions_empirical.csv", "empirical")
p1  <- load_distributions("Q130_distributions_prompt_1.csv",  "prompt 1")
p2  <- load_distributions("Q130_distributions_prompt_2.csv",  "prompt 2")
tidy <- bind_rows(p1$tidy, p2$tidy)
discarded <- bind_rows(emp$discarded, p1$discarded, p2$discarded)

m_both <- intersect(unique(p1$tidy$model), unique(p2$tidy$model)) |> sort()
message("M_both = ", paste(m_both, collapse = ", "))

wvs <- emp$tidy |>
  select(country, category, wvs_n = n, wvs_p = p)

# ------------------------------------------------------------ metrics ------

entropy_norm <- function(p) {
  p <- p[p > 0]
  -sum(p * log2(p)) / log2(length(categories))
}
jsd <- function(p, q) {
  m <- (p + q) / 2
  kl <- function(a, b) { i <- a > 0; sum(a[i] * log2(a[i] / b[i])) }
  0.5 * kl(p, m) + 0.5 * kl(q, m)
}
w1 <- function(p, q) sum(abs(cumsum(p) - cumsum(q)))
interior_mass <- function(p) p[2] + p[3]
mean_position <- function(p) sum(seq_along(p) * p)

bootstrap_cis <- function(counts, wvs_counts) {
  n_m <- sum(counts); n_w <- sum(wvs_counts)
  bm <- t(rmultinom(N_BOOT, n_m, counts / n_m)) / n_m
  bw <- t(rmultinom(N_BOOT, n_w, wvs_counts / n_w)) / n_w
  im <- bm[, 2] + bm[, 3]
  hn <- apply(bm, 1, entropy_norm)
  js <- vapply(seq_len(N_BOOT), \(i) jsd(bm[i, ], bw[i, ]), numeric(1))
  c(IM_lo = unname(quantile(im, 0.025)), IM_hi = unname(quantile(im, 0.975)),
    H_norm_lo = unname(quantile(hn, 0.025)), H_norm_hi = unname(quantile(hn, 0.975)),
    JSD_lo = unname(quantile(js, 0.025)), JSD_hi = unname(quantile(js, 0.975)))
}

cell_metrics <- function(cell) {
  p <- cell$p; q <- cell$wvs_p
  hn <- entropy_norm(p); hw <- entropy_norm(q)
  errs <- setNames(as.list(p - q), paste0("err_", 1:4))
  tibble(
    N_valid = sum(cell$n),
    H_norm = hn, H_norm_wvs = hw, entropy_ratio = hn / hw,
    IM = interior_mass(p), IM_wvs = interior_mass(q),
    dIM = interior_mass(p) - interior_mass(q),
    EM = p[1] + p[4],
    JSD = jsd(p, q), W1 = w1(p, q),
    mu = mean_position(p), dmu = mean_position(p) - mean_position(q),
    !!!errs,
    !!!as.list(bootstrap_cis(cell$n, cell$wvs_n))
  )
}

metrics <- tidy |>
  left_join(wvs, by = c("country", "category")) |>
  arrange(prompt, country, model, category) |>
  group_by(prompt, country, model) |>
  group_modify(~ cell_metrics(.x)) |>
  ungroup() |>
  left_join(discarded |> select(prompt, country, model, discarded_mass),
            by = c("prompt", "country", "model")) |>
  mutate(discarded_mass = coalesce(discarded_mass, 0)) |>
  arrange(prompt, country, model)

write_csv(metrics, file.path(res_dir, "metrics.csv"))

# cross-check point estimates against the Python pipeline
py <- read_csv(file.path(root, "results", "metrics.csv"),
               show_col_types = FALSE) |> arrange(prompt, country, model)
det_cols <- c("H_norm", "entropy_ratio", "IM", "dIM", "EM", "JSD", "W1",
              "mu", "dmu", paste0("err_", 1:4), "discarded_mass")
max_diff <- max(abs(as.matrix(metrics[det_cols]) - as.matrix(py[det_cols])))
stopifnot(max_diff < 1e-9)
message(sprintf(
  "Part 2 check OK: all deterministic metrics match results/metrics.csv (max |diff| = %.1e)",
  max_diff))

# ------------------------------------------------------ hypotheses ---------

h_counts <- metrics |>
  summarise(h1 = sum(entropy_ratio < 1), h2 = sum(dIM > 0), n = n(),
            .by = prompt)
message(paste(sprintf(
  "%s: entropy ratio < 1 in %d/%d cells; dIM > 0 in %d/%d cells",
  h_counts$prompt, h_counts$h1, h_counts$n, h_counts$h2, h_counts$n
), collapse = "\n"))

paired <- metrics |>
  filter(model %in% m_both) |>
  select(model, country, prompt, IM, dIM, H_norm, entropy_ratio, JSD, W1) |>
  pivot_wider(names_from = prompt,
              values_from = c(IM, dIM, H_norm, entropy_ratio, JSD, W1)) |>
  transmute(
    model, country,
    d_IM     = `IM_prompt 2` - `IM_prompt 1`,
    d_H_norm = `H_norm_prompt 2` - `H_norm_prompt 1`,
    d_JSD    = `JSD_prompt 2` - `JSD_prompt 1`,
    d_W1     = `W1_prompt 2` - `W1_prompt 1`,
    dIM_p1   = `dIM_prompt 1`, dIM_p2 = `dIM_prompt 2`,
    ratio_p1 = `entropy_ratio_prompt 1`, ratio_p2 = `entropy_ratio_prompt 2`,
    overshoot_flag = (dIM_p1 > 0 & dIM_p2 < 0) | ratio_p2 > 1
  )

rank_biserial <- function(d) {
  d <- d[d != 0]
  if (!length(d)) return(0)
  r <- rank(abs(d))
  (sum(r[d > 0]) - sum(r[d < 0])) / sum(r)
}

paired_tests <- function(d, alternative) {
  nz <- d[d != 0]
  w <- wilcox.test(nz, alternative = alternative, exact = TRUE)
  favor <- if (alternative == "less") sum(nz < 0) else sum(nz > 0)
  s <- binom.test(favor, length(nz), alternative = "greater")
  tibble(wilcoxon_p = w$p.value, rank_biserial = rank_biserial(d),
         n_favor = favor, n_against = length(nz) - favor,
         sign_p = s$p.value)
}

specs <- tribble(
  ~col,       ~alt,      ~label,
  "d_IM",     "less",    "H3a: D(IM) < 0",
  "d_H_norm", "greater", "H3b: D(H_norm) > 0",
  "d_JSD",    "less",    "H3c: D(JSD) < 0",
  "d_W1",     "less",    "D(W1) < 0"
)

pooled <- paired |>
  summarise(across(c(d_IM, d_H_norm, d_JSD, d_W1), mean), .by = model)

tests_df <- specs |>
  pmap(\(col, alt, label) bind_rows(
    paired_tests(pooled[[col]], alt) |>
      mutate(metric = label,
             scope = sprintf("pooled (1 value/model, n=%d)", nrow(pooled)),
             .before = 1),
    map(sort(unique(paired$country)), \(cty)
        paired_tests(paired[[col]][paired$country == cty], alt) |>
          mutate(metric = label,
                 scope = sprintf("%s (n=%d)", cty, length(m_both)),
                 .before = 1)) |> list_rbind()
  )) |>
  list_rbind()

writeLines(
  c("# M_both paired deltas (prompt 2 - prompt 1)",
    sub("\n$", "", format_csv(paired)),
    "",
    "# Paired tests (Wilcoxon signed-rank / sign test)",
    sub("\n$", "", format_csv(tests_df))),
  file.path(res_dir, "paired_differences.csv")
)

h3 <- paired |>
  summarise(h3a = sum(d_IM < 0), h3b = sum(d_H_norm > 0),
            h3c = sum(d_JSD < 0), n = n())
message(sprintf("H3a: %d/%d, H3b: %d/%d, H3c: %d/%d cells favor mitigation",
                h3$h3a, h3$n, h3$h3b, h3$n, h3$h3c, h3$n))
message(sprintf("H4 overshoot flags: %d", sum(paired$overshoot_flag)))

# --------------------------------------------------------- figures ---------

wrap15 <- \(x) str_wrap(x, 15)
model_levels <- c("WVS", m_both)

# 1 — grouped bars: WVS vs models, per country x prompt
bars <- bind_rows(
  tidy |> filter(model %in% m_both) |>
    select(country, prompt, series = model, category, p),
  emp$tidy |>
    select(country, category, p) |>
    crossing(prompt = c("prompt 1", "prompt 2")) |>
    mutate(series = "WVS")
) |>
  mutate(series = factor(series, levels = model_levels))

ggplot(bars, aes(category, p, fill = series)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.74) +
  facet_grid(country ~ prompt) +
  scale_fill_manual(values = series_cols, name = NULL) +
  scale_x_discrete(labels = wrap15) +
  labs(title = "Q130 response distributions: WVS vs silicon samples",
       x = NULL, y = "proportion") +
  theme_viz +
  theme(axis.text.x = element_text(size = 6.5))
ggsave(file.path(fig_dir, "fig1_distributions.png"),
       width = 11, height = 10, dpi = 300, bg = surface)

# 2 — dumbbell: interior mass prompt 1 -> prompt 2, WVS reference
im_wvs <- emp$tidy |>
  summarise(IM = interior_mass(p), .by = country)
dumb <- paired |>
  left_join(metrics |> filter(prompt == "prompt 1") |>
              select(model, country, IM_p1 = IM), by = c("model", "country")) |>
  mutate(IM_p2 = IM_p1 + d_IM,
         model = factor(model, levels = rev(m_both)))

ggplot(dumb) +
  geom_segment(aes(x = IM_p1, xend = IM_p2, y = model, yend = model),
               colour = baseline, linewidth = 1.4) +
  geom_point(aes(IM_p1, model, colour = "prompt 1"), size = 3) +
  geom_point(aes(IM_p2, model, colour = "prompt 2"), size = 3) +
  geom_vline(data = im_wvs, aes(xintercept = IM), colour = ink2,
             linetype = "42") +
  facet_wrap(~country) +
  scale_colour_manual(values = c("prompt 1" = muted, "prompt 2" = "#2a78d6"),
                      name = NULL) +
  labs(title = "Interior-category concentration: prompt 1 -> prompt 2",
       subtitle = "dashed line: WVS interior mass",
       x = "interior mass (p2 + p3)", y = NULL) +
  theme_viz
ggsave(file.path(fig_dir, "fig2_dumbbell_interior_mass.png"),
       width = 11, height = 3.6, dpi = 300, bg = surface)

# 3 — mitigation quadrants: d(H_norm) vs d(JSD)
lims <- with(paired, c(max(abs(d_H_norm)), max(abs(d_JSD)))) * 1.2
ggplot(paired, aes(d_H_norm, d_JSD, colour = model, shape = country)) +
  geom_hline(yintercept = 0, colour = baseline) +
  geom_vline(xintercept = 0, colour = baseline) +
  geom_point(size = 3.2, stroke = 1) +
  annotate("text", x = lims[1] * 0.45, y = -lims[2] * 0.92, hjust = 0.5,
           size = 2.9, colour = "#006300",
           label = "more spread,\ncloser to WVS\n(true mitigation)") +
  annotate("text", x = lims[1] * 0.95, y = lims[2] * 0.88, hjust = 1,
           vjust = 1, size = 2.9, colour = "#d03b3b",
           label = "more spread,\nfarther from WVS\n(overshoot)") +
  xlim(-lims[1], lims[1]) + ylim(-lims[2], lims[2]) +
  scale_colour_manual(values = series_cols[m_both], name = NULL) +
  labs(title = "Mitigation quality: spread gain vs fidelity change",
       x = "Delta H_norm (prompt 2 - prompt 1)",
       y = "Delta JSD vs WVS (prompt 2 - prompt 1)", shape = NULL) +
  theme_viz
ggsave(file.path(fig_dir, "fig3_mitigation_quadrants.png"),
       width = 6.8, height = 6, dpi = 300, bg = surface)

# 4 — per-category signed-error heatmap
errs <- metrics |>
  select(prompt, country, model, starts_with("err_")) |>
  pivot_longer(starts_with("err_"), names_to = "k", values_to = "err") |>
  mutate(category = factor(categories[as.integer(str_sub(k, 5))],
                           levels = categories),
         model = factor(model, levels = rev(m_both)))
vmax <- max(abs(errs$err))

ggplot(errs, aes(category, model, fill = err)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%+.2f", err),
                colour = abs(err) > 0.35), size = 2.7) +
  facet_grid(country ~ prompt) +
  scale_fill_gradient2(low = "#2a78d6", mid = "#f0efec", high = "#e34948",
                       limits = c(-vmax, vmax),
                       name = "p(model) - p(WVS)") +
  scale_colour_manual(values = c("FALSE" = ink, "TRUE" = surface),
                      guide = "none") +
  scale_x_discrete(labels = wrap15) +
  labs(title = "Per-category signed error vs WVS", x = NULL, y = NULL) +
  theme_viz +
  theme(axis.text.x = element_text(size = 6.5), panel.grid = element_blank())
ggsave(file.path(fig_dir, "fig4_signed_error_heatmap.png"),
       width = 10.5, height = 8.5, dpi = 300, bg = surface)

message("Wrote results_R/metrics.csv, results_R/paired_differences.csv and 4 figures in figures_R/")
