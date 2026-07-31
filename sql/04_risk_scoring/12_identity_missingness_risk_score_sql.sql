-- =========================================================
-- IDENTITY MISSINGNESS RISK SCORE
--
-- Purpose:
--     Score identity-completeness and missing-value signals
--     by fraud lift. Only 6 eligible rows after filtering —
--     too few for percentile-based tiering to be statistically
--     meaningful, so FIXED thresholds are used instead
--     (deliberate exception to the percentile approach used
--     elsewhere in this pipeline).
--
-- Source:
--     fraud_analysis_results (train-only lift values)
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.identity_missingness_risk_score AS

SELECT
    Analysis_Type,
    Segment,
    Transactions,
    Fraud_Transactions,
    Fraud_Rate_Percent,
    Fraud_Lift,
    CASE
        WHEN Fraud_Lift < 2 THEN 1
        WHEN Fraud_Lift < 3 THEN 2
        WHEN Fraud_Lift < 4 THEN 3
        ELSE 4
    END AS identity_missingness_score
FROM fraud_detection.fraud_analysis_results
WHERE Transactions > 100
  AND Fraud_Lift > 1
  AND Analysis_Type NOT IN (
      'M1','M2','M3','M4','M5','M6','M7','M8','M9',
      'M4_Frequency',
      'Total_M_True_Flags',
      'Total_M_Unknown_Flags',
      'Identity_Status'
  )
  AND Analysis_Type NOT LIKE 'Missing%'
  -- Prevent double counting against Identity_Completeness_Score
  AND Analysis_Type NOT IN (
      'Browser',
      'Operating System',
      'Screen Resolution',
      'Device_Info',
      'Device_Type'
  )
  AND (
        Analysis_Type = 'Identity_Completeness_Score'
        OR Segment IN ('-999','unknown')
      )
  AND NOT (
        Analysis_Type = 'Address_2'
        AND Segment = '-999'
      );