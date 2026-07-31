-- =========================================================
-- BEHAVIOR RISK SCORE
--
-- Purpose:
--     Score card velocity/z-score/deviation and distance
--     signals by fraud lift (20 eligible rows -> 3 tiers/terciles).
--
-- Source:
--     fraud_analysis_results (train-only lift values)
--
-- Notes:
--     - Tiers labeled 2/3/4 (not 1/2/3) — an intentional design
--       choice to widen the numeric gap between "no signal" (0,
--       via COALESCE downstream) and "weakest active signal" (2).
--       Final risk-score normalization uses MAX()-based scaling,
--       so this labeling choice doesn't distort the final 0-100
--       score — see final_transaction_risk_score.sql.
--     - Distance_1 / Distance_2 remain unbanded (raw values),
--       unlike the other 5 features in this pillar — known
--       limitation, documented in fraud_feature_store.sql.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.behavior_risk_score AS

WITH eligible AS (
    SELECT *
    FROM fraud_detection.fraud_analysis_results
    WHERE Transactions > 100
      AND Fraud_Lift > 1
      AND Analysis_Type IN (
            'Card_Profile_Frequency',
            'Card_Transaction_Count',
            'Card_Transaction_ZScore',
            'TransactionAmt_ZScore',
            'Transaction_Amount_Deviation',
            'Distance_1',
            'Distance_2'
      )
      AND Segment NOT IN ('unknown', '-999')
),

lift_percentiles AS (
    SELECT
        APPROX_QUANTILES(Fraud_Lift, 100)[OFFSET(33)] AS p33,
        APPROX_QUANTILES(Fraud_Lift, 100)[OFFSET(67)] AS p67
    FROM eligible
)

SELECT
    Analysis_Type,
    Segment,
    Transactions,
    Fraud_Transactions,
    Fraud_Rate_Percent,
    Fraud_Lift,
    CASE
        WHEN Fraud_Lift < (SELECT p33 FROM lift_percentiles) THEN 2
        WHEN Fraud_Lift < (SELECT p67 FROM lift_percentiles) THEN 3
        ELSE 4
    END AS behavior_risk_score
FROM eligible;