[🇪🇸 Español](README_ES.md) | **🇬🇧 English**

# Introduction
**Silicon sampling** refers to the use of large language models (LLMs) to simulate the responses that human participants would give in surveys, experiments, or interviews. By conditioning a model on socio-demographic profiles (age, gender, education, ideology, country, etc.), researchers generate "silicon samples": synthetic respondents whose answers are meant to approximate those of specific human subpopulations. The approach has been proposed as a fast, low-cost complement to traditional data collection —for piloting instruments, exploring hypotheses, or approximating hard-to-reach groups— but its reliability is still under active debate: models can reproduce social biases, flatten within-group variability, and align unevenly across cultures and languages.

This repository contains materials for the Silicon Sampling workshop. To date, the workshop has been taught at
- Max Planck Institute for Demographic Research - Summer Data Science Incubator Program
- SICSS 2026 - Buenos Aires

# Folder structure
```
factor_data_silicon_tutorial/
├── form/
├── imgs/
├── input_data/
├── output_data/
├── outputs_for_analysis/
├── results/
├── results_R/
├── figures/
├── figures_R/
└── src/
```

- `src` — the tutorial notebooks and the analysis code: those for analysis 1 (English and Spanish versions), the one for analysis 2 (`ES_tutorial_expresiones_silicon.ipynb`, Spanish only), the aggregation and bias-analysis Python scripts, the notebook that unifies them, and the R replication
- `form` — the web form used to collect the human baseline for analysis 2 (see below), plus its deployment guide and test suite
- `input_data` — raw data: the WVS Wave 7 respondent profiles used to build the prompts
- `output_data` — per-respondent simulation results, one CSV per model (gpt-4o, gpt-oss-20B, gpt-oss-120B) and prompt version (V1, V2)
- `outputs_for_analysis` — aggregated Q130 distributions per model × country (simulated V1/V2 and the empirical WVS baseline), plus the full text of both prompts
- `results` — outputs of the middle-point bias analysis (see below): metrics and paired-difference tables, and the full report
- `figures` — the analysis figures (300-dpi PNG)
- `results_R` / `figures_R` — the same tables and figures produced by the R replication
- `imgs` — logos and images used by the site

The repo root also holds the licence, this README and its Spanish version (`README_ES.md`), the GitHub Pages configuration (`_config.yml`, `_layouts/`), and `CLAUDE.md` (the specification of the bias analysis).

# Analyses

Beyond the tutorial itself, the repo includes two reproducible analyses of **middle-point bias** in silicon samples. They differ in the response scale they probe — an ordinal scale with no midpoint, and a continuous scale with one — and in whether the human baseline comes from an existing survey or is collected in the workshop.

# 1. Middle-point bias analysis (Q130, prompt V1 vs V2)

Beyond the tutorial, the repo includes a reproducible analysis of **middle-point bias** in the silicon samples for WVS Q130 ("What should the government do about people from other countries coming here to work?", a 4-point ordinal scale with no neutral midpoint). Since the scale has no midpoint, the bias is operationalized as **interior-category concentration**: excess probability mass on the two interior options relative to the empirical WVS distributions in Argentina, Uruguay and the United States. Prompt V2 (first-person narrative + anti-moderation instructions) is evaluated as a mitigation of the V1 baseline.

Pipeline:

1. `src/aggregate_q130.py` — aggregates the raw per-respondent results in `output_data/` into the long-format distribution summaries in `outputs_for_analysis/`.
2. `src/analyze_q130_bias.py` — computes per model × country × prompt metrics (normalized entropy, entropy ratio vs WVS, interior/extreme mass, Jensen–Shannon divergence, ordinal Wasserstein-1, per-category signed errors, mean scale position) with multinomial bootstrap CIs, and runs paired within-model tests of the mitigation hypotheses (Wilcoxon signed-rank, rank-biserial effect sizes, sign test). Outputs: `results/metrics.csv`, `results/paired_differences.csv`, the full write-up in [`results/report.md`](results/report.md), and four 300-dpi figures in `figures/`.

Run from the repo root (requires `pandas`, `scipy`, `matplotlib`):

```bash
python src/aggregate_q130.py
python src/analyze_q130_bias.py
```

The notebook [`src/q130_aggregation_and_bias_analysis.ipynb`](src/q130_aggregation_and_bias_analysis.ipynb) unifies both steps into a single executable document (same code, same outputs), with the figures and tables rendered inline.

An independent **R / tidyverse replication**, [`src/q130_aggregation_and_bias_analysis.R`](src/q130_aggregation_and_bias_analysis.R) (requires `dplyr`, `tidyr`, `readr`, `purrr`, `stringr`, `ggplot2`), re-derives the whole pipeline and cross-checks it against the Python outputs: the recomputed aggregations match `outputs_for_analysis/` exactly and all deterministic metrics match `results/metrics.csv` to < 1e-9 (asserted in the script; only the bootstrap CIs differ, since R and NumPy use different random generators). It writes its outputs to `results_R/` and `figures_R/` (ggplot2 versions of the same four figures):

```bash
Rscript src/q130_aggregation_and_bias_analysis.R
```

Headline findings (details and caveats in [`results/report.md`](results/report.md)): under prompt V1 all three models (gpt-4o, gpt-oss-20B, gpt-oss-120B) place 99–100% of their mass on the two interior categories and are strongly compressed relative to WVS in all 9 model × country cells; prompt V2 reduces interior concentration in 9/9 cells and increases entropy and improves fidelity to WVS (lower JSD) in 8/9, with no overcorrection detected.

# 2. Verbal probability expressions (human baseline vs silicon sample)

Q130 uses an ordinal scale **without** a midpoint, so the bias has to be measured indirectly. This second analysis uses a **continuous 0–100 scale that does have one**, and compares the models against a human baseline collected by the workshop participants themselves.

The instrument replicates **Stage 1 of the "Quizás, quizás, quizás" experiment** ([El Gato y La Caja](https://elgatoylacaja.com/notas/quizas-quizas-quizas), with the Decision-making Lab, University of Rochester; n > 8,000 in the original run): participants are shown verbal expressions of uncertainty and asked what probability each one conveys — 16 expressions on a 0–100 slider, a min–max range for 10 of them, and the usual regressors. The original data collection closed in October 2025, so this replication generates its own data.

**Exercise materials**

1. [**Fill in the form**](https://gefero.github.io/factor_data_silicon_tutorial/form/) — do this before opening the notebook: the human baseline is the class's own responses.
2. [**Class responses**](https://docs.google.com/spreadsheets/d/1V_3baEk7XSe36Mdlvn47bVgDBBcbMaYE8NmguHS9Zn8/edit?usp=sharing) — public sheet, updated live. The notebook reads straight from it.
3. [**Notebook on Google Colab**](https://colab.research.google.com/drive/1T4h5dJ_ALvIjDQUBzEJWoz9wHDW5dU7l?usp=sharing) — the simulation and the comparative analysis. Spanish only.

The same instrument is then put to the models, conditioned on the profiles collected from the human sample, and the two are compared on: mass at the midpoint (`[45, 55]`), excess of responses at exactly 50, between-participant dispersion, range width, and internal coherence (`min ≤ point ≤ max`, 81% in the original study).

The [notebook](https://colab.research.google.com/drive/1T4h5dJ_ALvIjDQUBzEJWoz9wHDW5dU7l?usp=sharing) walks through it: it reads the human response sheet, builds a first-person profile from each participant's demographics, and issues **26 independent calls per participant** — one per expression, with no context from the others, so that the model faces the same condition as the humans, who saw the items one at a time in randomised order. As in analysis 1 there are two prompt versions: a neutral `v1` baseline and a `v2` with an explicit anti-midpoint instruction, since measuring the bias with a prompt that already says "don't use 50" measures nothing.


# Google Colab version
You can open the tutorial notebooks directly in Google Colab:

**Analysis 1 — WVS Wave 7 (Q121, Q122, Q128, Q130)**
- [Spanish notebook](https://drive.google.com/file/d/1qRC_q_Uvr7tfBVVV3N-Leu9MtYmwbXkB/view?usp=sharing)
- [English notebook](https://drive.google.com/file/d/1vzEvTgfsQWd_qJAqDqYysa5yl6O3FTvK/view?usp=sharing)

**Analysis 2 — Verbal probability expressions**
- [Spanish notebook](https://colab.research.google.com/drive/1T4h5dJ_ALvIjDQUBzEJWoz9wHDW5dU7l?usp=sharing) — Spanish only: the stimulus *is* the set of Spanish expressions, so translating the prompts would change the object of study

# Slides
- [Presentation — MPIDR Summer Data Science Incubator Program](https://docs.google.com/presentation/d/1NYN-YYr1fLNvnJ9whPko7_ZYv6M9Wp5eVbb4zZ98Xj4/edit?usp=sharing)
- [Presentation — SICSS Buenos Aires 2026](https://docs.google.com/presentation/d/1Rr-rDShb2XzDm-_ThhWuQKi0TcTA9aA5Aw-wpzt8-yU/edit?usp=sharing)

# Stack
The tutorial runs entirely in **Python 3** on **Jupyter / Google Colab** notebooks. The main components are:

- **Runtime & infrastructure**
  - [Jupyter](https://jupyter.org/) notebooks executed on [Google Colab](https://colab.research.google.com/) — `google.colab` is used to manage API keys as secrets (`userdata`) and to mount Google Drive.
- **LLM backends**
  - [OpenAI Python SDK](https://github.com/openai/openai-python) (`openai`) to query proprietary models through the Chat Completions API — e.g. `gpt-4o`.
  - [Ollama](https://ollama.com/) (`ollama`) to run open-weight models on the Colab runtime — e.g. `gpt-oss:20b` and `gpt-oss:120b`.
- **Data handling & analysis**
  - [pandas](https://pandas.pydata.org/) for reading, transforming and aggregating the survey and simulation data.
  - [SciPy](https://scipy.org/) for the statistical tests in the middle-point bias analysis (Wilcoxon signed-rank, sign test).
- **Visualization**
  - [matplotlib](https://matplotlib.org/) and [seaborn](https://seaborn.pydata.org/) for the figures and tables.
- **Utilities**
  - [tqdm](https://tqdm.github.io/) for progress bars, plus Python standard-library modules (`json`, `os`, `re`, `time`, `datetime`, `pathlib`).

# Data sources
The tutorial uses data from the 2017-2022 wave of the [World Values Survey](https://www.worldvaluessurvey.org/WVSDocumentationWV7.jsp)

That said, there are many other data sources that could be used. We mention just a few
- [Latinobarometro](https://www.latinobarometro.org/lat.jsp)
- [LAPOP](https://www.vanderbilt.edu/lapop/)

# Bibliography
Despite being a new field, there is a large body of literature on the subject. As expected, no consensus has been reached regarding the reliability and viability of these tools.
We present a (non-exhaustive) list of several relevant studies.

- Ahuja, K., Diddee, H., Hada, R., Ochieng, M., Ramesh, K., Jain, P., Nambi, A., Ganu, T., Segal, S., Axmed, M., Bali, K., & Sitaram, S. (2023). *MEGA: Multilingual evaluation of generative AI* [Preprint]. arXiv. https://arxiv.org/abs/2303.12528
- Amirova, A., Fteropoulli, T., Ahmed, N., Cowie, M. R., & Leibo, J. Z. (2024). Framework-based qualitative analysis of free responses of large language models: Algorithmic fidelity. *PLOS ONE, 19*(3), e0300024. https://doi.org/10.1371/journal.pone.0300024
- Argyle, L. P., Busby, E. C., Fulda, N., Gubler, J. R., Rytting, C., & Wingate, D. (2023). Out of one, many: Using language models to simulate human samples. *Political Analysis, 31*(3), 337–351. https://doi.org/10.1017/pan.2023.2
- Atari, M., Xue, M. J., Park, P. S., Blasi, D. E., & Henrich, J. (2023). *Which humans?* [Preprint]. PsyArXiv. https://doi.org/10.31234/osf.io/5b26t
- Bisbee, J., Clinton, J. D., Dorff, C., Kenkel, B., & Larson, J. M. (2024). Synthetic replacements for human survey data? The perils of large language models. *Political Analysis, 32*(4), 401–416. https://doi.org/10.1017/pan.2024.5
- Boelaert, J., Coavoux, S., Ollion, É., Petev, I., & Präg, P. (2024). *Machine bias: How do generative language models answer opinion polls?* [Preprint]. OSF Preprints. https://doi.org/10.31235/osf.io/r2pnb
- Chen, Q., Kaza, V. S., Zinn, A. K., Portmann, M., & Dolnicar, S. (2025). Can large language models substitute participant-based survey studies? *Advances in Methods and Practices in Psychological Science*. Advance online publication. https://doi.org/10.1177/25152459251354844
- Cheng, M., Durmus, E., & Jurafsky, D. (2023). Marked personas: Using natural language prompts to measure stereotypes in language models. In *Proceedings of the 61st Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers)* (pp. 1504–1532). https://aclanthology.org/2023.acl-long.84.pdf
- Dominguez-Olmedo, R., Hardt, M., & Mendler-Dünner, C. (2024). Questioning the survey responses of large language models. In *Advances in Neural Information Processing Systems 37*. https://proceedings.neurips.cc/paper_files/paper/2024/file/515c62809e0a29729d7eec26e2916fc0-Paper-Conference.pdf
- Geng, M., He, S., & Trotta, R. (2024). *Are large language models chameleons?* [Preprint]. arXiv. https://arxiv.org/abs/2405.19323
- Kotek, H., Dockum, R., & Sun, D. Q. (2023). Gender bias and stereotypes in large language models. In *Proceedings of the 2023 ACM Conference on Collective Intelligence* (pp. 12–24). https://doi.org/10.1145/3582269.3615599
- Lin, Z. (2025). Six fallacies in substituting large language models for human participants. *Advances in Methods and Practices in Psychological Science, 8*(3), 1–19. https://doi.org/10.1177/25152459251357566
- Qu, Y., & Wang, J. (2024). Performance and biases of large language models in public opinion simulation. *Humanities and Social Sciences Communications, 11*(1), Article 1162. https://doi.org/10.1057/s41599-024-03609-x
- Santurkar, S., Durmus, E., Ladhak, F., Lee, C., Liang, P., & Hashimoto, T. (2023). Whose opinions do language models reflect? In *Proceedings of the 40th International Conference on Machine Learning* (pp. 29971–30004). https://arxiv.org/abs/2303.17548
- Sarstedt, M., Adler, S. J., Rau, L., & Schmitt, B. (2024). Using large language models to generate silicon samples in consumer and marketing research: Challenges, opportunities, and guidelines. *Psychology & Marketing, 41*(6), 1254–1270. https://doi.org/10.1002/mar.21982
- Sun, S., Lee, E., Nan, D., Zhao, X., Lee, W., Jansen, B. J., & Kim, J. H. (2024). *Random silicon sampling: Simulating human sub-population opinion using a large language model based on group-level demographic information* [Preprint]. arXiv. https://arxiv.org/abs/2402.18144
- Yan, T., Viberg, O., Baker, R. S., & Kizilcec, R. F. (2024). Cultural bias and cultural alignment of large language models. *PNAS Nexus, 3*(9), pgae346. https://doi.org/10.1093/pnasnexus/pgae346
