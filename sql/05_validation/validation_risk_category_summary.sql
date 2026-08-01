-- =========================================================
-- FRAUD DETECTION PROJECT
-- VALIDATION: RISK CATEGORY SUMMARY (RATE + CAPTURE)
--
-- Purpose:
--     Combines two validation views into one table:
--       1. Fraud_Rate_Percent  — within this category, what %
--          of transactions are fraud? (answers: "is this
--          category actually riskier?")
--       2. Fraud_Capture_Percent — of ALL fraud in the
--          validation window, what % sits in this category?
--          (answers: "how much fraud would I catch by
--          reviewing this category?")
--
-- Source:
--     final_risk_classification
--     feature_refinement_store (for dataset_split)
--
-- Notes:
--     - Filtered to dataset_split = 'validation' throughout —
--       this is the out-of-sample check, not a description of
--       the data the risk weights were learned from.
--     - Fraud_Rate_Percent should increase monotonically from
--       Low -> Medium -> High -> Critical (observed on this
--       run: 1.24% -> 1.79% -> 5.98% -> 8.7%, no reversals).
--     - Fraud_Capture_Percent does NOT need to be monotonic in
--       the same direction — it depends on category size too.
--       E.g. Medium can capture a similar or larger % of total
--       fraud than Critical simply because it contains far more
--       transactions, even though its per-transaction rate is
--       much lower. Read rate and capture as answering two
--       different questions, not the same one.
--     - Combining Critical + High Risk gives the practical
--       business number: reviewing ~13% of volume captures
--       ~40% of all fraud in this run.
-- =========================================================

SELECT
    risk_category,
    COUNT(*) AS transactions,
    SUM(isFraud) AS fraud_transactions,
    ROUND(AVG(isFraud) * 100, 2) AS fraud_rate_percent,
    ROUND(
        SUM(isFraud) * 100.0 /
        SUM(SUM(isFraud)) OVER(),
        2
    ) AS fraud_capture_percent
FROM fraud_detection.final_risk_classification f
JOIN fraud_detection.feature_refinement_store USING(TransactionID)
WHERE dataset_split = 'validation'
GROUP BY risk_category
ORDER BY
CASE
    WHEN risk_category='Critical Risk' THEN 1
    WHEN risk_category='High Risk' THEN 2
    WHEN risk_category='Medium Risk' THEN 3
    ELSE 4
END;