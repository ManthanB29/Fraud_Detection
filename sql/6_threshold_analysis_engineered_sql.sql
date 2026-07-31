-- =========================================================
-- FRAUD DETECTION PROJECT
-- THRESHOLD ANALYSIS (ENGINEERED) — TRAIN WINDOW ONLY
--
-- Purpose:
--     Compute percentile statistics on the engineered
--     behavioral/velocity features. Feeds feature_refinement_store
--     directly — these percentiles ARE the band boundaries used
--     downstream, not just descriptive stats.
--
-- Source:
--     fraud_feature_store
--
-- Output:
--     threshold_analysis_engineered
--
-- Notes:
--     - Filtered to dataset_split = 'train' throughout, since
--       these percentiles become real scoring thresholds
--       (see feature_refinement_store) — computing them on
--       validation rows would leak validation information
--       into the feature engineering step.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.threshold_analysis_engineered AS

WITH metrics AS (

SELECT
    'Card_Transaction_Count' AS Metric,
    MIN(Card_Transaction_Count) AS Min_Value,
    ROUND(AVG(Card_Transaction_Count), 2) AS Avg_Value,
    APPROX_QUANTILES(Card_Transaction_Count,100)[OFFSET(50)] AS Median_Value,
    APPROX_QUANTILES(Card_Transaction_Count,100)[OFFSET(90)] AS P90,
    APPROX_QUANTILES(Card_Transaction_Count,100)[OFFSET(95)] AS P95,
    APPROX_QUANTILES(Card_Transaction_Count,100)[OFFSET(99)] AS P99,
    MAX(Card_Transaction_Count) AS Max_Value
FROM fraud_detection.fraud_feature_store
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'Card_Transaction_ZScore',
    MIN(Card_Transaction_ZScore),
    ROUND(AVG(Card_Transaction_ZScore), 2),
    APPROX_QUANTILES(Card_Transaction_ZScore,100)[OFFSET(50)],
    APPROX_QUANTILES(Card_Transaction_ZScore,100)[OFFSET(90)],
    APPROX_QUANTILES(Card_Transaction_ZScore,100)[OFFSET(95)],
    APPROX_QUANTILES(Card_Transaction_ZScore,100)[OFFSET(99)],
    MAX(Card_Transaction_ZScore)
FROM fraud_detection.fraud_feature_store
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'Card_Profile_Frequency',
    MIN(Card_Profile_Frequency),
    ROUND(AVG(Card_Profile_Frequency), 2),
    APPROX_QUANTILES(Card_Profile_Frequency,100)[OFFSET(50)],
    APPROX_QUANTILES(Card_Profile_Frequency,100)[OFFSET(90)],
    APPROX_QUANTILES(Card_Profile_Frequency,100)[OFFSET(95)],
    APPROX_QUANTILES(Card_Profile_Frequency,100)[OFFSET(99)],
    MAX(Card_Profile_Frequency)
FROM fraud_detection.fraud_feature_store
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'Total_M_True_Flags',
    MIN(Total_M_True_Flags),
    ROUND(AVG(Total_M_True_Flags), 2),
    APPROX_QUANTILES(Total_M_True_Flags,100)[OFFSET(50)],
    APPROX_QUANTILES(Total_M_True_Flags,100)[OFFSET(90)],
    APPROX_QUANTILES(Total_M_True_Flags,100)[OFFSET(95)],
    APPROX_QUANTILES(Total_M_True_Flags,100)[OFFSET(99)],
    MAX(Total_M_True_Flags)
FROM fraud_detection.fraud_feature_store
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'Total_M_Unknown_Flags',
    MIN(Total_M_Unknown_Flags),
    ROUND(AVG(Total_M_Unknown_Flags), 2),
    APPROX_QUANTILES(Total_M_Unknown_Flags,100)[OFFSET(50)],
    APPROX_QUANTILES(Total_M_Unknown_Flags,100)[OFFSET(90)],
    APPROX_QUANTILES(Total_M_Unknown_Flags,100)[OFFSET(95)],
    APPROX_QUANTILES(Total_M_Unknown_Flags,100)[OFFSET(99)],
    MAX(Total_M_Unknown_Flags)
FROM fraud_detection.fraud_feature_store
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'TransactionAmt_ZScore',
    MIN(TransactionAmt_ZScore),
    ROUND(AVG(TransactionAmt_ZScore), 2),
    APPROX_QUANTILES(TransactionAmt_ZScore,100)[OFFSET(50)],
    APPROX_QUANTILES(TransactionAmt_ZScore,100)[OFFSET(90)],
    APPROX_QUANTILES(TransactionAmt_ZScore,100)[OFFSET(95)],
    APPROX_QUANTILES(TransactionAmt_ZScore,100)[OFFSET(99)],
    MAX(TransactionAmt_ZScore)
FROM fraud_detection.fraud_feature_store
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'Transaction_Amount_Deviation',
    MIN(Transaction_Amount_Deviation),
    ROUND(AVG(Transaction_Amount_Deviation), 2),
    APPROX_QUANTILES(Transaction_Amount_Deviation,100)[OFFSET(50)],
    APPROX_QUANTILES(Transaction_Amount_Deviation,100)[OFFSET(90)],
    APPROX_QUANTILES(Transaction_Amount_Deviation,100)[OFFSET(95)],
    APPROX_QUANTILES(Transaction_Amount_Deviation,100)[OFFSET(99)],
    MAX(Transaction_Amount_Deviation)
FROM fraud_detection.fraud_feature_store
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'Card_Avg_TransactionAmt',
    MIN(Card_Avg_TransactionAmt),
    ROUND(AVG(Card_Avg_TransactionAmt), 2),
    APPROX_QUANTILES(Card_Avg_TransactionAmt,100)[OFFSET(50)],
    APPROX_QUANTILES(Card_Avg_TransactionAmt,100)[OFFSET(90)],
    APPROX_QUANTILES(Card_Avg_TransactionAmt,100)[OFFSET(95)],
    APPROX_QUANTILES(Card_Avg_TransactionAmt,100)[OFFSET(99)],
    MAX(Card_Avg_TransactionAmt)
FROM fraud_detection.fraud_feature_store
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'M4_Frequency',
    MIN(M4_Frequency),
    ROUND(AVG(M4_Frequency), 2),
    APPROX_QUANTILES(M4_Frequency,100)[OFFSET(50)],
    APPROX_QUANTILES(M4_Frequency,100)[OFFSET(90)],
    APPROX_QUANTILES(M4_Frequency,100)[OFFSET(95)],
    APPROX_QUANTILES(M4_Frequency,100)[OFFSET(99)],
    MAX(M4_Frequency)
FROM fraud_detection.fraud_feature_store
WHERE dataset_split = 'train'

)

SELECT * FROM metrics;