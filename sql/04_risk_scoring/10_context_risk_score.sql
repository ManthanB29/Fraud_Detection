-- =========================================================
-- CONTEXT RISK SCORE
--
-- Purpose:
--     Score product, timing, and card-network/type context
--     signals by fraud lift (22 eligible rows -> 3 tiers/terciles).
--
-- Source:
--     fraud_analysis_results (train-only lift values)
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.context_risk_score AS

WITH eligible AS (
    SELECT *
    FROM fraud_detection.fraud_analysis_results
    WHERE Transactions > 100
      AND Fraud_Lift > 1
      AND Analysis_Type IN (
            'ProductCD',
            'Transaction_Hour',
            'Device_Type',
            'Card_Network',
            'Amount_Bucket',
            'Card_Type'
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
        WHEN Fraud_Lift < (SELECT p33 FROM lift_percentiles) THEN 1
        WHEN Fraud_Lift < (SELECT p67 FROM lift_percentiles) THEN 2
        ELSE 3
    END AS context_risk_score
FROM eligible;