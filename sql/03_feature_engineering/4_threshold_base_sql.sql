-- =========================================================
-- FRAUD DETECTION PROJECT
-- THRESHOLD ANALYSIS (BASE) — TRAIN WINDOW ONLY
--
-- Purpose:
--     Compute descriptive percentile statistics (median, P90,
--     P95, P99) on raw numeric features, BEFORE feature
--     engineering. Used to sanity-check distributions and
--     inform bucket design in later stages.
--
-- Source:
--     feature_store_base
--
-- Output:
--     threshold_analysis_base
--
-- Notes:
--     - Filtered to dataset_split = 'train' throughout. Any
--       threshold derived from data and later used in a
--       scoring feature must be learned from train only, to
--       avoid validation-window information leaking into
--       feature engineering.
--     - Sentinel value -999 (used for missing numeric fields)
--       is excluded via NULLIF before computing statistics,
--       so it doesn't distort percentiles.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.threshold_analysis_base AS

WITH metrics AS (

-- TransactionAmt
SELECT
    'TransactionAmt' AS Metric,
    MIN(TransactionAmt) AS Min_Value,
    ROUND(AVG(TransactionAmt), 2) AS Avg_Value,
    APPROX_QUANTILES(TransactionAmt,100)[OFFSET(50)] AS Median_Value,
    APPROX_QUANTILES(TransactionAmt,100)[OFFSET(90)] AS P90,
    APPROX_QUANTILES(TransactionAmt,100)[OFFSET(95)] AS P95,
    APPROX_QUANTILES(TransactionAmt,100)[OFFSET(99)] AS P99,
    MAX(TransactionAmt) AS Max_Value
FROM fraud_detection.feature_store_base
WHERE dataset_split = 'train'

UNION ALL

-- dist1
SELECT
    'dist1',
    MIN(NULLIF(dist1, -999)),
    ROUND(AVG(NULLIF(dist1, -999)),  2),
    APPROX_QUANTILES(NULLIF(dist1, -999),100)[OFFSET(50)],
    APPROX_QUANTILES(NULLIF(dist1, -999),100)[OFFSET(90)],
    APPROX_QUANTILES(NULLIF(dist1, -999),100)[OFFSET(95)],
    APPROX_QUANTILES(NULLIF(dist1, -999),100)[OFFSET(99)],
    MAX(NULLIF(dist1, -999))
FROM fraud_detection.feature_store_base
WHERE dataset_split = 'train'

UNION ALL

-- dist2
SELECT
    'dist2',
    MIN(NULLIF(dist2, -999)),
    ROUND(AVG(NULLIF(dist2, -999)),  2),
    APPROX_QUANTILES(NULLIF(dist2, -999),100)[OFFSET(50)],
    APPROX_QUANTILES(NULLIF(dist2, -999),100)[OFFSET(90)],
    APPROX_QUANTILES(NULLIF(dist2, -999),100)[OFFSET(95)],
    APPROX_QUANTILES(NULLIF(dist2, -999),100)[OFFSET(99)],
    MAX(NULLIF(dist2, -999))
FROM fraud_detection.feature_store_base
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'card2',
    MIN(NULLIF(card2, -999)),
    ROUND(AVG(NULLIF(card2, -999)),  2),
    APPROX_QUANTILES(NULLIF(card2, -999),100)[OFFSET(50)],
    APPROX_QUANTILES(NULLIF(card2, -999),100)[OFFSET(90)],
    APPROX_QUANTILES(NULLIF(card2, -999),100)[OFFSET(95)],
    APPROX_QUANTILES(NULLIF(card2, -999),100)[OFFSET(99)],
    MAX(NULLIF(card2, -999))
FROM fraud_detection.feature_store_base
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'card3',
    MIN(NULLIF(card3, -999)),
    ROUND(AVG(NULLIF(card3, -999)),  2),
    APPROX_QUANTILES(NULLIF(card3, -999),100)[OFFSET(50)],
    APPROX_QUANTILES(NULLIF(card3, -999),100)[OFFSET(90)],
    APPROX_QUANTILES(NULLIF(card3, -999),100)[OFFSET(95)],
    APPROX_QUANTILES(NULLIF(card3, -999),100)[OFFSET(99)],
    MAX(NULLIF(card3, -999))
FROM fraud_detection.feature_store_base
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'card5',
    MIN(NULLIF(card5, -999)),
    ROUND(AVG(NULLIF(card5, -999)),  2),
    APPROX_QUANTILES(NULLIF(card5, -999),100)[OFFSET(50)],
    APPROX_QUANTILES(NULLIF(card5, -999),100)[OFFSET(90)],
    APPROX_QUANTILES(NULLIF(card5, -999),100)[OFFSET(95)],
    APPROX_QUANTILES(NULLIF(card5, -999),100)[OFFSET(99)],
    MAX(NULLIF(card5, -999))
FROM fraud_detection.feature_store_base
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'card1',
    MIN(NULLIF(card1, -999)),
    ROUND(AVG(NULLIF(card1, -999)),  2),
    APPROX_QUANTILES(NULLIF(card1, -999),100)[OFFSET(50)],
    APPROX_QUANTILES(NULLIF(card1, -999),100)[OFFSET(90)],
    APPROX_QUANTILES(NULLIF(card1, -999),100)[OFFSET(95)],
    APPROX_QUANTILES(NULLIF(card1, -999),100)[OFFSET(99)],
    MAX(NULLIF(card1, -999))
FROM fraud_detection.feature_store_base
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'addr1',
    MIN(NULLIF(addr1, -999)),
    ROUND(AVG(NULLIF(addr1, -999)),  2),
    APPROX_QUANTILES(NULLIF(addr1, -999),100)[OFFSET(50)],
    APPROX_QUANTILES(NULLIF(addr1, -999),100)[OFFSET(90)],
    APPROX_QUANTILES(NULLIF(addr1, -999),100)[OFFSET(95)],
    APPROX_QUANTILES(NULLIF(addr1, -999),100)[OFFSET(99)],
    MAX(NULLIF(addr1, -999))
FROM fraud_detection.feature_store_base
WHERE dataset_split = 'train'

UNION ALL

SELECT
    'addr2',
    MIN(NULLIF(addr2, -999)),
    ROUND(AVG(NULLIF(addr2, -999)),  2),
    APPROX_QUANTILES(NULLIF(addr2, -999),100)[OFFSET(50)],
    APPROX_QUANTILES(NULLIF(addr2, -999),100)[OFFSET(90)],
    APPROX_QUANTILES(NULLIF(addr2, -999),100)[OFFSET(95)],
    APPROX_QUANTILES(NULLIF(addr2, -999),100)[OFFSET(99)],
    MAX(NULLIF(addr2, -999))
FROM fraud_detection.feature_store_base
WHERE dataset_split = 'train'

)

SELECT * FROM metrics;