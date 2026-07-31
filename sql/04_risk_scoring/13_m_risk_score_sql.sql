-- =========================================================
-- M RISK SCORE
--
-- Purpose:
--     Score M1-M9 categorical flags and derived M-summary
--     features by fraud lift (18 eligible rows -> 2 tiers,
--     median split only — too few rows to support 3+ tiers).
--
-- Source:
--     fraud_analysis_results (train-only lift values)
--
-- Notes:
--     - Tiers labeled 2/3 (not 1/2) — same intentional design
--       choice as behavior_risk_score, see notes there.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.m_risk_score AS

WITH eligible AS (
    SELECT *
    FROM fraud_detection.fraud_analysis_results
    WHERE Transactions > 100
      AND Fraud_Lift > 1
      AND Analysis_Type IN (
            'M1','M2','M3','M4','M5',
            'M6','M7','M8','M9',
            'M4_Frequency',
            'Total_M_True_Flags',
            'Total_M_Unknown_Flags'
      )
),

lift_percentiles AS (
    SELECT
        APPROX_QUANTILES(Fraud_Lift, 100)[OFFSET(50)] AS p50
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
        WHEN Fraud_Lift < (SELECT p50 FROM lift_percentiles) THEN 2
        ELSE 3
    END AS m_risk_score
FROM eligible;