-- =========================================================
-- FRAUD DETECTION PROJECT
-- FINAL RISK CLASSIFICATION
--
-- Source:
--     final_transaction_risk_score
--
-- Output:
--     final_risk_classification
--
-- Purpose:
--     Bucket the continuous 0-100 final_risk_score into
--     business-friendly categories for review prioritization.
--
-- Notes:
--     - Boundaries (20/40/60) are fixed, business-judgment
--       thresholds — analogous to the Z-score bands in
--       feature_refinement_store, these represent an
--       interpretive convention rather than a value learned
--       from data, so no train/validation leakage concern here.
--     - See sql/05_validation/ for evidence that these
--       categories produce a monotonically increasing fraud
--       rate on the validation (unseen) window.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.final_risk_classification AS

SELECT
    TransactionID,
    TransactionDT,
    TransactionAmt,
    final_risk_score,
    CASE
        WHEN final_risk_score < 20 THEN 'Low Risk'
        WHEN final_risk_score < 40 THEN 'Medium Risk'
        WHEN final_risk_score < 60 THEN 'High Risk'
        ELSE 'Critical Risk'
    END AS risk_category
FROM fraud_detection.final_transaction_risk_score;