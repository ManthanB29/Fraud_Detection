-- =========================================================
-- FRAUD DETECTION PROJECT
-- STAGE 01: RAW FEATURE STORE
--
-- Purpose:
--     Join raw transaction + identity data with no cleaning.
--     Establishes the time-based train/validation split that
--     every downstream table inherits.
--
-- Source:
--     fraud_detection.transactions
--     fraud_detection.identity
--
-- Output:
--     raw_feature_store
--
-- Notes:
--     - dataset_split is assigned here, at the earliest possible
--       stage, so it propagates through every subsequent table
--       without needing to be recomputed.
--     - Split is time-based (75th percentile of TransactionDT),
--       NOT random — preserves chronological order so that
--       "train" always precedes "validation" in time. This is
--       required for a valid train/validation evaluation on
--       time-series-flavored fraud data.
--     - No filtering, casting, or null-handling happens here —
--       that's deferred to the cleaning stage (feature_store_base)
--       so this table remains a faithful raw join for auditing.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.raw_feature_store AS

WITH cutoff AS (
  SELECT APPROX_QUANTILES(TransactionDT, 100)[OFFSET(75)] AS split_point
  FROM fraud_detection.transactions
)

SELECT
-- CORE
t.TransactionID, t.isFraud, t.TransactionDT, t.TransactionAmt,
-- PRODUCT
t.ProductCD,
-- CARD
t.card1, t.card2, t.card3, t.card4, t.card5, t.card6,
-- ADDRESS
t.addr1, t.addr2,
-- DISTANCE
t.dist1, t.dist2,
-- EMAIL
t.P_emaildomain, t.R_emaildomain,
-- M FEATURES
t.M1, t.M2, t.M3, t.M4, t.M5, t.M6, t.M7, t.M8, t.M9,
-- IDENTITY FEATURES
i.DeviceType, i.DeviceInfo, i.id_30, i.id_31, i.id_33,

-- =========================================================
-- TIME-BASED SPLIT (75th percentile of TransactionDT)
-- =========================================================
CASE
    WHEN t.TransactionDT < (SELECT split_point FROM cutoff)
    THEN 'train'
    ELSE 'validation'
END AS dataset_split

FROM fraud_detection.transactions t
LEFT JOIN fraud_detection.identity i
ON t.TransactionID = i.TransactionID;