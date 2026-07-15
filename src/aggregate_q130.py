"""Aggregate Q130 simulation results into long-format summary CSVs.

Reads the raw per-respondent result files in output_data/ and produces,
for each experiment version (V1 and Q130_v2), one long-format CSV with
the distribution of simulated Q130 answers per model, size and country:

    model | size | country | category | n | proportion

Invalid or missing model answers are kept under the category
"invalid/no answer" so proportions are computed over all respondents.

Also produces the empirical baseline: the distribution of real WVS
respondents' Q130 answers (valid answers only) in the three countries,
computed from input_data/WVS_wave7_migracion_prompts.csv.

Run from the repo root:  python src/aggregate_q130.py
"""

from pathlib import Path

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parent.parent
INPUT_CSV = REPO_ROOT / "input_data" / "WVS_wave7_migracion_prompts.csv"
RESULTS_DIR = REPO_ROOT / "output_data"
OUTPUT_DIR = REPO_ROOT / "outputs_for_analys"

INVALID_LABEL = "invalid/no answer"

COUNTRIES = ["Argentina", "Uruguay", "United States"]

Q130_VALID = {
    "Let anyone come who wants to",
    "Let people come as long as there are jobs available",
    "Place strict limits on the number of foreigners who can come here",
    "Prohibit people coming here from other countries",
}

# (filename, model, size, column holding the simulated Q130 answer)
V1_SOURCES = [
    ("gpt-4o_V1_WVS_silicon_empirico_results.csv", "gpt-4o", "4o", "q130_model"),
    ("gpt-oss_20b_V1_WVS_silicon_empirico_results.csv", "gpt-oss", "20B", "q130_model"),
    ("gpt-oss_120b_V1_WVS_silicon_empirico_results.csv", "gpt-oss", "120B", "q130_model"),
]

# In the v2 files the answer lives in the column named "model"
# (the model name is in "model_name").
V2_SOURCES = [
    ("gpt-4o_Q130_v2_WVS_silicon_empirico_results.csv", "gpt-4o", "4o", "model"),
    ("gpt-oss_20B_Q130_v2_WVS_silicon_empirico_results.csv", "gpt-oss", "20B", "model"),
    ("gpt-oss_120B_Q130_v2_WVS_silicon_empirico_results.csv", "gpt-oss", "120B", "model"),
]


def aggregate_file(filename: str, model: str, size: str, answer_col: str) -> pd.DataFrame:
    df = pd.read_csv(RESULTS_DIR / filename)
    answers = df[answer_col].fillna(INVALID_LABEL)
    agg = (
        answers.groupby(df["country"])
        .value_counts()
        .rename("n")
        .reset_index()
        .rename(columns={answer_col: "category"})
    )
    agg["proportion"] = agg["n"] / agg.groupby("country")["n"].transform("sum")
    agg.insert(0, "size", size)
    agg.insert(0, "model", model)
    return agg


def build(sources: list[tuple[str, str, str, str]], out_name: str) -> pd.DataFrame:
    result = pd.concat(
        [aggregate_file(*src) for src in sources], ignore_index=True
    ).sort_values(["model", "size", "country", "category"], ignore_index=True)
    out_path = OUTPUT_DIR / out_name
    result.to_csv(out_path, index=False)
    print(f"Wrote {out_path.relative_to(REPO_ROOT)} ({len(result)} rows)")
    return result


def build_empirical(out_name: str) -> pd.DataFrame:
    df = pd.read_csv(INPUT_CSV)
    df = df[df["B_COUNTRY_LABEL"].isin(COUNTRIES) & df["Q130"].isin(Q130_VALID)]
    agg = (
        df["Q130"]
        .groupby(df["B_COUNTRY_LABEL"])
        .value_counts()
        .rename("n")
        .reset_index()
        .rename(columns={"B_COUNTRY_LABEL": "country", "Q130": "category"})
    )
    agg["proportion"] = agg["n"] / agg.groupby("country")["n"].transform("sum")
    agg.insert(0, "size", "-")
    agg.insert(0, "model", "empirical")
    agg = agg.sort_values(["country", "category"], ignore_index=True)
    out_path = OUTPUT_DIR / out_name
    agg.to_csv(out_path, index=False)
    print(f"Wrote {out_path.relative_to(REPO_ROOT)} ({len(agg)} rows)")
    return agg


if __name__ == "__main__":
    OUTPUT_DIR.mkdir(exist_ok=True)
    build(V1_SOURCES, "Q130_distributions_prompt_1.csv")
    build(V2_SOURCES, "Q130_distributions_prompt_2.csv")
    build_empirical("Q130_distributions_empirical.csv")
