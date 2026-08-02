# Fraud Detection Analytics & Risk Scoring Framework

An end-to-end, explainable fraud risk-scoring framework built on the IEEE-CIS fraud
detection dataset — from raw transaction/identity data through feature engineering,
percentile-based risk scoring, out-of-sample validation, and an interactive Tableau
dashboard.

**[View the live Tableau dashboard →]
https://public.tableau.com/views/FraudDetection_17856955983970/Story1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link**

---

## Project Summary

This project builds a **rules-based, explainable risk-scoring framework** for
transaction fraud — not a black-box ML classifier. Every risk signal (card
identifiers, device/browser fingerprints, transaction behavior, missing-identity
patterns, categorical flags) is quantified by fraud lift, tiered by percentile rank,
weighted by business judgment, and combined into a single 0–100 explainable score
per transaction.

The framework is validated using a **time-based train/validation split** —
risk weights and thresholds are learned exclusively from an earlier time window
and evaluated against a later, genuinely unseen window, avoiding the in-sample
leakage that undermines many portfolio "fraud detection" projects.

**Headline result:** on validation data the framework never saw during weight
calculation, reviewing the top ~13% of transactions by risk score captures
~40% of all fraud — with fraud lift increasing monotonically from 1.0x
(no filtering) to 6.2x (top-scoring transactions), and no reversals across
two independent evaluation views (score bands and risk categories).

---

## Repository Structure

fraud-detection-risk-framework/
│
├── data/ # Raw data samples (see Data Source below)
│
├── python/
│ ├── ingestion.py # Data loading, time-ordered sampling, dedup
│ ├── validation.py # Dataset overview, schema, cardinality checks
│ └── eda.py # Distribution, outlier, skewness, correlation EDA
│
├── notebooks/
│ └── eda_and_time_split.ipynb # Raw-data EDA that informed SQL design choices
│
├── sql/
│ ├── 01_ingestion/
│ │ └── raw_feature_store.sql
│ │
│ ├── 02_cleaning/
│ │ ├── reconciliation_master.sql
│ │ └── feature_store_base.sql
│ │
│ ├── 03_feature_engineering/
│ │ ├── fraud_feature_store.sql
│ │ ├── threshold_analysis_base.sql
│ │ ├── threshold_analysis_engineered.sql
│ │ └── feature_refinement_store.sql
│ │
│ ├── 04_risk_scoring/
│ │ ├── fraud_analysis_results.sql
│ │ ├── entity_risk_score.sql
│ │ ├── context_risk_score.sql
│ │ ├── behavior_risk_score.sql
│ │ ├── identity_missingness_risk_score.sql
│ │ ├── m_risk_score.sql
│ │ ├── transaction_layer_scores.sql
│ │ ├── final_transaction_risk_score.sql
│ │ └── final_risk_classification.sql
│ │
│ └── 05_validation/
│ ├── risk_threshold_analysis.sql
│ ├── validation_risk_category_summary.sql
│ ├── validation_score_band_rate.sql
│ ├── risk_threshold_train_vs_validation_comparison.sql
│ ├── risk_category_train_vs_validation.sql
│ └── score_band_train_vs_validation.sql
│
├── dashboard/
│ └── Fraud_Detection.twbx # Tableau workbook (or link to Tableau Public)
│ └── Dashboard csvs


---

## Pipeline Overview

1. **Ingestion** — join raw transactions + identity data; assign a **time-based**
   train/validation split (75th percentile of `TransactionDT`) at the earliest
   possible stage so it propagates through every downstream table.
2. **Cleaning** — standardize types, impute sentinel values (`-999`/`unknown`),
   quantify identity-field completeness as its own signal.
3. **Feature Engineering** — engineer time, amount, card-velocity, device, and
   M-flag features. All velocity/frequency features are **point-in-time
   cumulative** (`ORDER BY TransactionDT RANGE BETWEEN UNBOUNDED PRECEDING AND
   CURRENT ROW`), so no transaction's features include information from the
   future. Bucket thresholds (percentiles) and normalization constants
   (Z-score mean/stddev) are learned from **train data only**.
4. **Risk Scoring** — compute fraud lift per segment (train-only), tier
   segments into percentile-based risk scores sized to each pillar's actual
   eligible data volume (5 tiers where there's enough data, down to fixed
   thresholds where there isn't), then combine five weighted pillars — Entity
   (30%), Identity (25%), Behavior (20%), Context (15%), M-features (10%) —
   into one 0–100 `final_risk_score`.
5. **Validation** — evaluate the framework exclusively on the **validation**
   window (data never used to learn any weight or threshold), confirming
   monotonic lift and fraud-rate ordering.

---

## Key Design Decisions

- **Time-based split, not random.** Fraud patterns drift over time; a random
  split would let future information leak into training and produce
  inflated, misleading validation numbers.
- **Point-in-time features.** Card/device/email "velocity" features only
  count activity up to each transaction's own timestamp — never future
  transactions — matching what would actually be knowable in production.
- **Percentile-based, self-calibrating risk tiers**, sized to each pillar's
  actual eligible row count (not a fixed tier count copy-pasted across
  pillars) — e.g. Entity (131 eligible segments) uses 5 tiers; Identity
  Missingness (only 6 eligible segments) uses fixed thresholds instead,
  since percentile tiering on 6 data points isn't statistically meaningful.
- **Train-only thresholds and normalization**, applied to all rows — every
  number "learned from data" that later scores a transaction is computed
  exclusively from train-window rows, then applied uniformly to train and
  validation alike.

---

## Known Limitations

- This is a **rules-based explainable scorer**, not a trained ML classifier —
  it prioritizes interpretability over the sharper separation a fitted model
  (e.g. XGBoost) could achieve. Framed as a triage/prioritization tool, not
  a system that isolates fraud into a small, near-complete bucket (more than
  half of validation fraud still falls in Medium/Low risk categories).
- `Distance_1`/`Distance_2` are not banded like the other behavioral
  features (raw values used directly) — a known inconsistency, not yet
  addressed.
- The Identity Missingness pillar has very few underlying signals (6
  eligible segments after filtering) — fixed thresholds are used there
  instead of percentile tiering.
- Absolute fraud rates differ meaningfully between the train and validation
  windows (temporal drift) — relative discrimination (higher score → more
  fraud) holds in both, but this is not evidence the score's *absolute*
  values are stable over time.

---

## Data Source

[IEEE-CIS Fraud Detection dataset](https://www.kaggle.com/c/ieee-fraud-detection)
(Kaggle). A ~100,000-row time-ordered slice of `train_transaction.csv` /
`train_identity.csv` was used, split 75/25 by `TransactionDT` into
train/validation windows.

---

## Dashboard

See `dashboard/` or the https://public.tableau.com/views/FraudDetection_17856955983970/Story1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link for:
- **Executive Summary** — headline validation results (lift curve, risk
  category comparison, score band distribution)
- **Deep Dive** — pillar contribution breakdown, score distribution,
  fraud-rate-over-time, amount-vs-risk scatter
