-- =========================================================
-- FRAUD DETECTION PROJECT
-- RISK CATEGORY SUMMARY — TRAIN vs VALIDATION COMPARISON
--
-- Purpose:
--     Side-by-side comparison of fraud rate and fraud capture
--     per risk category, train vs. validation. Train is shown
--     ONLY as a reference/contrast point (risk weights were
--     learned from train, so its numbers aren't evidence of
--     generalization) — VALIDATION is the genuine out-of-sample
--     proof.
--
-- Source:
--     final_risk_classification
--     feature_refinement_store (for dataset_split, isFraud)
--
-- Notes:
--     - Uses conditional aggregation (CASE WHEN inside SUM/COUNT)
--       rather than two separate WHERE-filtered queries, so both
--       windows appear in one row per category.
--     - Fraud_Capture_Percent for each window is calculated
--       relative to that window's OWN total fraud count (i.e.
--       train capture % sums to 100 across train rows; validation
--       capture % sums to 100 across validation rows) — the two
--       capture columns are not directly comparable in absolute
--       terms, only in shape/pattern.
--     - Expect train's fraud rates to run higher than validation's
--       at every category (train window has a higher overall
--       baseline fraud rate — see earlier finding: train ~3.5%
--       vs. this 100K sample's ~2.56% overall). This is temporal
--       drift, not an error.
--     - What matters: does the RELATIVE ordering (Critical > High
--       > Medium > Low) hold in BOTH columns? If yes, that's
--       strong evidence the framework's discrimination
--       generalizes even though the absolute baseline shifts.
-- =========================================================

SELECT
    risk_category,

    -- TRAIN WINDOW
    COUNTIF(dataset_split = 'train') AS train_transactions,
    SUM(CASE WHEN dataset_split = 'train' THEN isFraud ELSE 0 END) AS train_fraud_transactions,
    ROUND(
        SAFE_DIVIDE(
            SUM(CASE WHEN dataset_split = 'train' THEN isFraud ELSE 0 END),
            COUNTIF(dataset_split = 'train')
        ) * 100, 2
    ) AS train_fraud_rate_percent,
    ROUND(
        SAFE_DIVIDE(
            SUM(CASE WHEN dataset_split = 'train' THEN isFraud ELSE 0 END),
            SUM(SUM(CASE WHEN dataset_split = 'train' THEN isFraud ELSE 0 END)) OVER()
        ) * 100, 2
    ) AS train_fraud_capture_percent,

    -- VALIDATION WINDOW
    COUNTIF(dataset_split = 'validation') AS validation_transactions,
    SUM(CASE WHEN dataset_split = 'validation' THEN isFraud ELSE 0 END) AS validation_fraud_transactions,
    ROUND(
        SAFE_DIVIDE(
            SUM(CASE WHEN dataset_split = 'validation' THEN isFraud ELSE 0 END),
            COUNTIF(dataset_split = 'validation')
        ) * 100, 2
    ) AS validation_fraud_rate_percent,
    ROUND(
        SAFE_DIVIDE(
            SUM(CASE WHEN dataset_split = 'validation' THEN isFraud ELSE 0 END),
            SUM(SUM(CASE WHEN dataset_split = 'validation' THEN isFraud ELSE 0 END)) OVER()
        ) * 100, 2
    ) AS validation_fraud_capture_percent

FROM fraud_detection.final_risk_classification f
JOIN fraud_detection.feature_refinement_store USING(TransactionID)
GROUP BY risk_category
ORDER BY
CASE
    WHEN risk_category='Critical Risk' THEN 1
    WHEN risk_category='High Risk' THEN 2
    WHEN risk_category='Medium Risk' THEN 3
    ELSE 4
END;