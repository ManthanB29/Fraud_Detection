-- =========================================================
-- FRAUD DETECTION PROJECT
-- STAGE 02b: CLEANING & STANDARDIZATION LAYER
--
-- Purpose:
--     Cast types, standardize casing/whitespace, and impute
--     sentinel values (-999 / 'unknown') for downstream use.
--
-- Source:
--     reconciliation_master
--
-- Output:
--     feature_store_base
--
-- Notes:
--     - This table uses an EXPLICIT column list (not SELECT *),
--       so any new column added upstream will NOT appear here
--       automatically. dataset_split is explicitly included
--       below for this reason — it was previously dropped
--       silently at this stage before being added back in.
--       If you add new raw columns upstream, remember to add
--       them here too.
--     - Identity fields (Missing_*_Flag, Identity_Completeness_Score,
--       Identity_Status) are carried through as-is from
--       reconciliation_master — do not recompute them here.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.feature_store_base AS

SELECT
-- =========================================================
-- CORE IDENTIFIERS + TARGET
-- =========================================================
TransactionID,
isFraud,
TransactionDT,
SAFE_CAST(TransactionAmt AS FLOAT64) AS TransactionAmt,

-- =========================================================
-- PRODUCT FEATURES
-- =========================================================
LOWER(TRIM(COALESCE(CAST(ProductCD AS STRING), 'unknown'))) AS ProductCD,

-- =========================================================
-- CARD FEATURES
-- =========================================================
COALESCE(SAFE_CAST(card1 AS FLOAT64), -999) AS card1,
COALESCE(SAFE_CAST(card2 AS FLOAT64), -999) AS card2,
COALESCE(SAFE_CAST(card3 AS FLOAT64), -999) AS card3,
LOWER(TRIM(COALESCE(CAST(card4 AS STRING), 'unknown'))) AS card4,
COALESCE(SAFE_CAST(card5 AS FLOAT64), -999) AS card5,
LOWER(TRIM(COALESCE(CAST(card6 AS STRING), 'unknown'))) AS card6,

-- =========================================================
-- ADDRESS FEATURES
-- =========================================================
COALESCE(SAFE_CAST(addr1 AS FLOAT64), -999) AS addr1,
COALESCE(SAFE_CAST(addr2 AS FLOAT64), -999) AS addr2,

-- =========================================================
-- DISTANCE FEATURES
-- =========================================================
COALESCE(SAFE_CAST(dist1 AS FLOAT64), -999) AS dist1,
COALESCE(SAFE_CAST(dist2 AS FLOAT64), -999) AS dist2,

-- =========================================================
-- EMAIL FEATURES
-- =========================================================
LOWER(TRIM(COALESCE(CAST(P_emaildomain AS STRING), 'unknown'))) AS P_emaildomain,
LOWER(TRIM(COALESCE(CAST(R_emaildomain AS STRING), 'unknown'))) AS R_emaildomain,

-- =========================================================
-- M FEATURES
-- =========================================================
LOWER(TRIM(COALESCE(CAST(M1 AS STRING), 'unknown'))) AS M1,
LOWER(TRIM(COALESCE(CAST(M2 AS STRING), 'unknown'))) AS M2,
LOWER(TRIM(COALESCE(CAST(M3 AS STRING), 'unknown'))) AS M3,
LOWER(TRIM(COALESCE(CAST(M4 AS STRING), 'unknown'))) AS M4,
LOWER(TRIM(COALESCE(CAST(M5 AS STRING), 'unknown'))) AS M5,
LOWER(TRIM(COALESCE(CAST(M6 AS STRING), 'unknown'))) AS M6,
LOWER(TRIM(COALESCE(CAST(M7 AS STRING), 'unknown'))) AS M7,
LOWER(TRIM(COALESCE(CAST(M8 AS STRING), 'unknown'))) AS M8,
LOWER(TRIM(COALESCE(CAST(M9 AS STRING), 'unknown'))) AS M9,

-- =========================================================
-- IDENTITY FEATURES (FROM RECONCILIATION - DO NOT RECOMPUTE)
-- =========================================================
LOWER(TRIM(COALESCE(CAST(DeviceType AS STRING), 'unknown'))) AS DeviceType,
LOWER(TRIM(COALESCE(CAST(DeviceInfo AS STRING), 'unknown'))) AS DeviceInfo,
LOWER(TRIM(COALESCE(CAST(id_30 AS STRING), 'unknown'))) AS id_30,
LOWER(TRIM(COALESCE(CAST(id_31 AS STRING), 'unknown'))) AS id_31,
LOWER(TRIM(COALESCE(CAST(id_33 AS STRING), 'unknown'))) AS id_33,

-- =========================================================
-- RECONCILIATION FEATURES (SOURCE OF TRUTH)
-- =========================================================
Missing_DeviceType_Flag,
Missing_DeviceInfo_Flag,
Missing_OS_Flag,
Missing_Browser_Flag,
Missing_Resolution_Flag,
Identity_Completeness_Score,
Identity_Status,

-- =========================================================
-- TRAIN / VALIDATION SPLIT (carried explicitly — see notes above)
-- =========================================================
dataset_split

FROM fraud_detection.reconciliation_master;