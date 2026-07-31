-- =========================================================
-- FRAUD DETECTION PROJECT
-- FEATURE REFINEMENT LAYER
--
-- Purpose:
--     Convert continuous engineered features into
--     business-friendly categorical bands, using train-only
--     percentile thresholds pulled from threshold_analysis_engineered.
--
-- Source:
--     fraud_feature_store
--
-- Output:
--     feature_refinement_store
--
-- Notes:
--     - Card_Transaction_Count_Band, Card_Profile_Frequency_Band,
--       Transaction_Amount_Deviation_Band, and M4_Frequency_Band
--       all use dynamic, train-derived percentile cutoffs — NOT
--       hardcoded numbers. This keeps the framework self-
--       recalibrating if the underlying data changes.
--     - Card_Transaction_ZScore_Band and TransactionAmt_ZScore_Band
--       intentionally use FIXED cutoffs (-1/1/2/4), since these
--       represent standard statistical convention (approx.
--       standard-deviation bands), not data-derived thresholds —
--       no leakage concern, and no need to make them dynamic.
--     - Distance_1 / Distance_2 remain unbanded (known limitation,
--       documented in fraud_feature_store.sql).
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.feature_refinement_store AS

WITH thresholds AS (
    SELECT Metric, Median_Value, P90, P95, P99
    FROM fraud_detection.threshold_analysis_engineered
    WHERE Metric IN (
        'Card_Transaction_Count',
        'Card_Profile_Frequency',
        'Transaction_Amount_Deviation',
        'M4_Frequency'
    )
),

card_count_t AS (
    SELECT Median_Value, P90, P95, P99 FROM thresholds WHERE Metric = 'Card_Transaction_Count'
),
card_profile_t AS (
    SELECT Median_Value, P90, P95, P99 FROM thresholds WHERE Metric = 'Card_Profile_Frequency'
),
txn_deviation_t AS (
    SELECT Median_Value, P90, P95, P99 FROM thresholds WHERE Metric = 'Transaction_Amount_Deviation'
),
m4_freq_t AS (
    SELECT Median_Value, P90, P95, P99 FROM thresholds WHERE Metric = 'M4_Frequency'
)

SELECT
    *,

-- =====================================================
-- CARD TRANSACTION COUNT BAND (thresholds from train)
-- =====================================================
CASE
    WHEN Card_Transaction_Count < (SELECT Median_Value FROM card_count_t) THEN '<Median'
    WHEN Card_Transaction_Count < (SELECT P90 FROM card_count_t) THEN 'Median-P90'
    WHEN Card_Transaction_Count < (SELECT P95 FROM card_count_t) THEN 'P90-P95'
    WHEN Card_Transaction_Count < (SELECT P99 FROM card_count_t) THEN 'P95-P99'
    ELSE 'P99+'
END AS Card_Transaction_Count_Band,

-- =====================================================
-- CARD PROFILE FREQUENCY BAND (thresholds from train)
-- =====================================================
CASE
    WHEN Card_Profile_Frequency < (SELECT Median_Value FROM card_profile_t) THEN '<Median'
    WHEN Card_Profile_Frequency < (SELECT P90 FROM card_profile_t) THEN 'Median-P90'
    WHEN Card_Profile_Frequency < (SELECT P95 FROM card_profile_t) THEN 'P90-P95'
    WHEN Card_Profile_Frequency < (SELECT P99 FROM card_profile_t) THEN 'P95-P99'
    ELSE 'P99+'
END AS Card_Profile_Frequency_Band,

-- =====================================================
-- CARD TRANSACTION Z SCORE BAND (fixed statistical cutoffs — kept as-is)
-- =====================================================
CASE
    WHEN Card_Transaction_ZScore < -1 THEN '<-1'
    WHEN Card_Transaction_ZScore < 1 THEN '-1 to 1'
    WHEN Card_Transaction_ZScore < 2 THEN '1 to 2'
    WHEN Card_Transaction_ZScore < 4 THEN '2 to 4'
    ELSE '>4'
END AS Card_Transaction_ZScore_Band,

-- =====================================================
-- GLOBAL TRANSACTION Z SCORE BAND (fixed statistical cutoffs — kept as-is)
-- =====================================================
CASE
    WHEN TransactionAmt_ZScore < -1 THEN '<-1'
    WHEN TransactionAmt_ZScore < 1 THEN '-1 to 1'
    WHEN TransactionAmt_ZScore < 2 THEN '1 to 2'
    WHEN TransactionAmt_ZScore < 4 THEN '2 to 4'
    ELSE '>4'
END AS TransactionAmt_ZScore_Band,

-- =====================================================
-- TRANSACTION DEVIATION BAND (thresholds from train)
-- =====================================================
CASE
    WHEN Transaction_Amount_Deviation < (SELECT Median_Value FROM txn_deviation_t) THEN '<Median'
    WHEN Transaction_Amount_Deviation < (SELECT P90 FROM txn_deviation_t) THEN 'Median-P90'
    WHEN Transaction_Amount_Deviation < (SELECT P95 FROM txn_deviation_t) THEN 'P90-P95'
    WHEN Transaction_Amount_Deviation < (SELECT P99 FROM txn_deviation_t) THEN 'P95-P99'
    ELSE 'P99+'
END AS Transaction_Amount_Deviation_Band,

-- =====================================================
-- M4 FREQUENCY BAND (thresholds from train)
-- =====================================================
CASE
    WHEN M4_Frequency < (SELECT Median_Value FROM m4_freq_t) THEN '<Median'
    WHEN M4_Frequency < (SELECT P90 FROM m4_freq_t) THEN 'Median-P90'
    WHEN M4_Frequency < (SELECT P95 FROM m4_freq_t) THEN 'P90-P95'
    WHEN M4_Frequency < (SELECT P99 FROM m4_freq_t) THEN 'P95-P99'
    ELSE 'P99+'
END AS M4_Frequency_Band

FROM fraud_detection.fraud_feature_store;