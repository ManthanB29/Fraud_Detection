-- =========================================================
-- FRAUD DETECTION PROJECT
-- FEATURE ENGINEERING LAYER (TIME-AWARE, TRAIN-ANCHORED)
--
-- Purpose:
--     Engineer time, amount, card, device, email, product,
--     address, identity, and M-feature signals.
--
-- Source:
--     feature_store_base
--
-- Output:
--     fraud_feature_store
--
-- Notes:
--     - Amount_Bucket thresholds and the global Z-score
--       normalization constants (global_avg_amt, global_std_amt)
--       are computed from TRAIN rows only, then applied to
--       every row (train + validation). This mirrors fitting
--       a scaler on training data and applying it everywhere.
--     - All COUNT(*)/AVG(...) OVER(PARTITION BY ...) window
--       features use ORDER BY TransactionDT with
--       RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW,
--       making them cumulative-to-date rather than full-table
--       aggregates. This prevents a transaction's "velocity"
--       features from including activity that happened AFTER
--       it — a real-world deployment would only ever see prior
--       history, never future transactions.
--     - Distance_1 / Distance_2 are NOT banded here (unlike
--       Card_Transaction_Count, Transaction_Amount_Deviation,
--       etc.) — known limitation, kept as raw values.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.fraud_feature_store AS

WITH amount_percentiles AS (
    SELECT
        APPROX_QUANTILES(TransactionAmt, 100)[OFFSET(50)] AS p50,
        APPROX_QUANTILES(TransactionAmt, 100)[OFFSET(90)] AS p90,
        APPROX_QUANTILES(TransactionAmt, 100)[OFFSET(95)] AS p95,
        APPROX_QUANTILES(TransactionAmt, 100)[OFFSET(99)] AS p99
    FROM fraud_detection.feature_store_base
    WHERE dataset_split = 'train'
),

global_stats AS (
    SELECT
        AVG(TransactionAmt) AS global_avg_amt,
        STDDEV(TransactionAmt) AS global_std_amt
    FROM fraud_detection.feature_store_base
    WHERE dataset_split = 'train'
),

base_features AS (

SELECT
*,

-- =====================================================
-- TIME FEATURES
-- =====================================================
MOD(CAST(TransactionDT / 3600 AS INT64), 24) AS TransactionHour,

CASE
    WHEN MOD(CAST(TransactionDT / 3600 AS INT64),24) BETWEEN 5 AND 11 THEN 'Morning'
    WHEN MOD(CAST(TransactionDT / 3600 AS INT64),24) BETWEEN 12 AND 16 THEN 'Afternoon'
    WHEN MOD(CAST(TransactionDT / 3600 AS INT64),24) BETWEEN 17 AND 20 THEN 'Evening'
    WHEN MOD(CAST(TransactionDT / 3600 AS INT64),24) BETWEEN 21 AND 23 THEN 'Night'
    ELSE 'Late Night'
END AS Transaction_Time_Category,

-- =====================================================
-- AMOUNT FEATURES (thresholds learned from train only)
-- =====================================================
CASE
    WHEN TransactionAmt <= (SELECT p50 FROM amount_percentiles) THEN 'Low Amount'
    WHEN TransactionAmt <= (SELECT p90 FROM amount_percentiles) THEN 'Typical Amount'
    WHEN TransactionAmt <= (SELECT p95 FROM amount_percentiles) THEN 'High Amount'
    WHEN TransactionAmt <= (SELECT p99 FROM amount_percentiles) THEN 'Very High Amount'
    ELSE 'Extreme Amount'
END AS Amount_Bucket,

-- =====================================================
-- CARD FEATURES (point-in-time cumulative, not full-table)
-- =====================================================
COUNT(*) OVER(
    PARTITION BY SAFE_CAST(card1 AS INT64)
    ORDER BY TransactionDT
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Card_Transaction_Count,

ROUND(
    AVG(TransactionAmt) OVER(
        PARTITION BY SAFE_CAST(card1 AS INT64)
        ORDER BY TransactionDT
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2
) AS Card_Avg_TransactionAmt,

ROUND(
    TransactionAmt - AVG(TransactionAmt) OVER(
        PARTITION BY SAFE_CAST(card1 AS INT64)
        ORDER BY TransactionDT
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2
) AS Transaction_Amount_Deviation,

COUNT(*) OVER(
    PARTITION BY
        CAST(card1 AS STRING),
        CAST(card2 AS STRING),
        CAST(card3 AS STRING),
        CAST(card5 AS STRING)
    ORDER BY TransactionDT
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Card_Profile_Frequency,

ROUND(
    SAFE_DIVIDE(
        TransactionAmt - AVG(TransactionAmt) OVER(
            PARTITION BY SAFE_CAST(card1 AS INT64)
            ORDER BY TransactionDT
            RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        NULLIF(STDDEV(TransactionAmt) OVER(
            PARTITION BY SAFE_CAST(card1 AS INT64)
            ORDER BY TransactionDT
            RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 0)
    ), 2
) AS Card_Transaction_ZScore,

-- =====================================================
-- DEVICE FEATURES (point-in-time cumulative)
-- =====================================================
COUNT(*) OVER(
    PARTITION BY DeviceInfo
    ORDER BY TransactionDT
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Device_Transaction_Count,

COUNT(*) OVER(
    PARTITION BY id_31
    ORDER BY TransactionDT
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Browser_Frequency,

COUNT(*) OVER(
    PARTITION BY id_30
    ORDER BY TransactionDT
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS OS_Frequency,

-- =====================================================
-- EMAIL & PRODUCT FEATURES (point-in-time cumulative)
-- =====================================================
COUNT(*) OVER(
    PARTITION BY P_emaildomain
    ORDER BY TransactionDT
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Email_Frequency,

COUNT(*) OVER(
    PARTITION BY ProductCD
    ORDER BY TransactionDT
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Product_Frequency,

-- =====================================================
-- ADDRESS FEATURE (point-in-time cumulative)
-- =====================================================
COUNT(*) OVER(
    PARTITION BY CAST(addr1 AS STRING)
    ORDER BY TransactionDT
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Address_Transaction_Count,

-- =====================================================
-- IDENTITY FEATURES (point-in-time cumulative)
-- =====================================================
COUNT(*) OVER(
    PARTITION BY Identity_Status
    ORDER BY TransactionDT
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Identity_Status_Frequency,

-- =====================================================
-- M FEATURES (row-level, no leakage risk here)
-- =====================================================
(
CASE WHEN M1='true' THEN 1 ELSE 0 END +
CASE WHEN M2='true' THEN 1 ELSE 0 END +
CASE WHEN M3='true' THEN 1 ELSE 0 END +
CASE WHEN M5='true' THEN 1 ELSE 0 END +
CASE WHEN M6='true' THEN 1 ELSE 0 END +
CASE WHEN M7='true' THEN 1 ELSE 0 END +
CASE WHEN M8='true' THEN 1 ELSE 0 END +
CASE WHEN M9='true' THEN 1 ELSE 0 END
) AS Total_M_True_Flags,

(
CASE WHEN M1='unknown' THEN 1 ELSE 0 END +
CASE WHEN M2='unknown' THEN 1 ELSE 0 END +
CASE WHEN M3='unknown' THEN 1 ELSE 0 END +
CASE WHEN M5='unknown' THEN 1 ELSE 0 END +
CASE WHEN M6='unknown' THEN 1 ELSE 0 END +
CASE WHEN M7='unknown' THEN 1 ELSE 0 END +
CASE WHEN M8='unknown' THEN 1 ELSE 0 END +
CASE WHEN M9='unknown' THEN 1 ELSE 0 END
) AS Total_M_Unknown_Flags,

COUNT(*) OVER(
    PARTITION BY SAFE_CAST(card1 AS INT64), M4
    ORDER BY TransactionDT
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS M4_Frequency,

-- =====================================================
-- GLOBAL STATISTICAL FEATURE (normalization learned from train)
-- =====================================================
ROUND(
    SAFE_DIVIDE(
        TransactionAmt - (SELECT global_avg_amt FROM global_stats),
        NULLIF((SELECT global_std_amt FROM global_stats), 0)
    ), 2
) AS TransactionAmt_ZScore

FROM fraud_detection.feature_store_base

)

SELECT * FROM base_features;