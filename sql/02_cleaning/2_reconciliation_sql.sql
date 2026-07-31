-- =========================================================
-- FRAUD DETECTION PROJECT
-- STAGE 02a: RECONCILIATION ENGINE
--
-- Purpose:
--     Quantify identity-field completeness per transaction.
--     Missingness itself is treated as a signal, not just
--     something to impute away.
--
-- Source:
--     raw_feature_store
--
-- Output:
--     reconciliation_master
--
-- Notes:
--     - dataset_split flows through automatically via SELECT *,
--       no explicit handling needed in this file.
--     - Identity_Completeness_Score (0-5) and Identity_Status
--       are computed from the same underlying missing-flags,
--       so they should never be recomputed independently
--       downstream — treat this table as the source of truth
--       for identity completeness.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.reconciliation_master AS

WITH identity_reconciliation AS (

SELECT
*,

-- =========================================================
-- MISSING IDENTITY FLAGS
-- =========================================================
CASE WHEN DeviceType IS NULL THEN 1 ELSE 0 END AS Missing_DeviceType_Flag,
CASE WHEN DeviceInfo IS NULL THEN 1 ELSE 0 END AS Missing_DeviceInfo_Flag,
CASE WHEN id_30 IS NULL THEN 1 ELSE 0 END AS Missing_OS_Flag,
CASE WHEN id_31 IS NULL THEN 1 ELSE 0 END AS Missing_Browser_Flag,
CASE WHEN id_33 IS NULL THEN 1 ELSE 0 END AS Missing_Resolution_Flag,

-- =========================================================
-- IDENTITY COMPLETENESS SCORE (0-5)
-- =========================================================
(
    CASE WHEN DeviceType IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN DeviceInfo IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN id_30 IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN id_31 IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN id_33 IS NOT NULL THEN 1 ELSE 0 END
) AS Identity_Completeness_Score

FROM fraud_detection.raw_feature_store

)

SELECT
*,

-- =========================================================
-- IDENTITY STATUS (derived from completeness score)
-- =========================================================
CASE
    WHEN Identity_Completeness_Score = 0 THEN 'Fully Missing Identity'
    WHEN Identity_Completeness_Score < 5 THEN 'Partial Identity'
    ELSE 'Complete Identity'
END AS Identity_Status

FROM identity_reconciliation;