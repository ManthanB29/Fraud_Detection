-- =========================================================
-- FRAUD DETECTION PROJECT
-- FRAUD ANALYSIS RESULTS (LIFT TABLE) — TRAIN WINDOW ONLY
--
-- Purpose:
--     Compute fraud rate, fraud lift (segment rate ÷ portfolio
--     rate), and fraud contribution for every categorical
--     segment and engineered band across the feature set.
--     This is the core "signal discovery" table — every
--     downstream risk-score table (entity, context, behavior,
--     identity_missingness, m_features) reads its lift values
--     from here.
--
-- Source:
--     feature_refinement_store
--
-- Output:
--     fraud_analysis_results
--
-- Notes:
--     - CRITICAL: filtered to dataset_split = 'train' in
--       portfolio_stats AND every individual UNION ALL branch.
--       This is the single most important leakage guard in
--       the whole pipeline — fraud lift is a "rule learned
--       from labels," so it must never be computed using
--       validation-window fraud outcomes. If you add a new
--       Analysis_Type branch here, you MUST add
--       "WHERE f.dataset_split = 'train'" to it as well, or
--       the entire train/validation separation is compromised.
--     - Several Analysis_Type values (Card_Transaction_Count,
--       Card_Profile_Frequency, Transaction_Amount_Deviation,
--       Card_Transaction_ZScore, TransactionAmt_ZScore,
--       M4_Frequency) group by their pre-computed "_Band"
--       column from feature_refinement_store, but are labeled
--       WITHOUT the "_Band" suffix for readability. The
--       grouping itself is still fully banded — this is a
--       display-naming choice, not raw/unbanded data.
--     - HAVING COUNT(*) >= 100 on several high-cardinality
--       fields (Card1, Card2, Card3, Card5, Address, Address_2,
--       email domains, Device_Info, Browser, OS, Screen
--       Resolution, Distance_1, Distance_2) filters out
--       segments too small to trust for a stable lift estimate.
--     - Distance_1 / Distance_2 group on raw dist1/dist2 values
--       directly (not banded) — known limitation, documented
--       in fraud_feature_store.sql.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.fraud_analysis_results AS

WITH portfolio_stats AS (
    SELECT
        AVG(isFraud) * 100 AS overall_fraud_rate,
        SUM(isFraud) AS total_fraud_txns
    FROM fraud_detection.feature_refinement_store
    WHERE dataset_split = 'train'
)

-- Product Fraud Analysis
SELECT
    'ProductCD' AS Analysis_Type,
    CAST(ProductCD AS STRING) AS Segment,
    COUNT(*) AS Transactions,
    SUM(isFraud) AS Fraud_Transactions,
    ROUND(AVG(isFraud) * 100, 2) AS Fraud_Rate_Percent,
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2) AS Fraud_Lift,
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2) AS Fraud_Contribution_Percent
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY ProductCD, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Card Network Fraud Analysis
SELECT
    'Card_Network',
    CAST(card4 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY card4, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Card Type Fraud Analysis
SELECT
    'Card_Type',
    CAST(card6 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY card6, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Card1 High Risk Analysis
SELECT
    'Card1',
    CAST(card1 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY card1, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Address Fraud Analysis
SELECT
    'Address',
    CAST(addr1 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY addr1, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Purchaser Email Domain Fraud Analysis
SELECT
    'P_EmailDomain',
    CAST(P_emaildomain AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY P_emaildomain, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Recipient Email Domain Fraud Analysis
SELECT
    'R_EmailDomain',
    CAST(R_emaildomain AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY R_emaildomain, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Transaction Hour Fraud Analysis
SELECT
    'Transaction_Hour',
    CAST(TransactionHour AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY TransactionHour, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Identity Status Fraud Analysis
SELECT
    'Identity_Status',
    CAST(Identity_Status AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Identity_Status, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Identity Completeness Score Fraud Analysis
SELECT
    'Identity_Completeness_Score',
    CAST(Identity_Completeness_Score AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Identity_Completeness_Score, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Missing Device Type Flag Analysis
SELECT
    'Missing_DeviceType_Flag',
    CAST(Missing_DeviceType_Flag AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Missing_DeviceType_Flag, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Missing Device Info Flag Analysis
SELECT
    'Missing_DeviceInfo_Flag',
    CAST(Missing_DeviceInfo_Flag AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Missing_DeviceInfo_Flag, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Missing Browser Flag
SELECT
    'Missing_Browser_Flag',
    CAST(Missing_Browser_Flag AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Missing_Browser_Flag, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Missing Resolution Flag
SELECT
    'Missing_Resolution_Flag',
    CAST(Missing_Resolution_Flag AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Missing_Resolution_Flag, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Missing OS Flag
SELECT
    'Missing_OS_Flag',
    CAST(Missing_OS_Flag AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Missing_OS_Flag, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Card2 Risk
SELECT
    'Card2',
    CAST(card2 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY card2, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Card3 Risk
SELECT
    'Card3',
    CAST(card3 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY card3, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Card5 Risk
SELECT
    'Card5',
    CAST(card5 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY card5, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Address 2 Risk
SELECT
    'Address_2',
    CAST(addr2 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY addr2, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Device Type
SELECT
    'Device_Type',
    CAST(DeviceType AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY DeviceType, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- M1
SELECT
    'M1',
    CAST(M1 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY M1, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- M2
SELECT
    'M2',
    CAST(M2 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY M2, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- M3
SELECT
    'M3',
    CAST(M3 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY M3, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- M4
SELECT
    'M4',
    CAST(M4 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY M4, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- M5
SELECT
    'M5',
    CAST(M5 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY M5, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- M6
SELECT
    'M6',
    CAST(M6 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY M6, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- M7
SELECT
    'M7',
    CAST(M7 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY M7, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- M8
SELECT
    'M8',
    CAST(M8 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY M8, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- M9
SELECT
    'M9',
    CAST(M9 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY M9, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Amount Bucket
SELECT
    'Amount_Bucket',
    CAST(Amount_Bucket AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Amount_Bucket, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Transaction Time Category
SELECT
    'Transaction_Time_Category',
    CAST(Transaction_Time_Category AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Transaction_Time_Category, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Distance 1
SELECT
    'Distance_1',
    CAST(dist1 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY dist1, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Distance 2
SELECT
    'Distance_2',
    CAST(dist2 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY dist2, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Device Info
SELECT
    'Device_Info',
    CAST(DeviceInfo AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY DeviceInfo, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Operating System
SELECT
    'Operating System',
    CAST(id_30 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY id_30, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Browser
SELECT
    'Browser',
    CAST(id_31 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY id_31, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Screen Resolution
SELECT
    'Screen Resolution',
    CAST(id_33 AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY id_33, p.overall_fraud_rate, p.total_fraud_txns
HAVING COUNT(*) >= 100

UNION ALL

-- Card Transaction Count Buckets
SELECT
    'Card_Transaction_Count',
    Card_Transaction_Count_Band,
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100,2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate,0),2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns,0),2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Card_Transaction_Count_Band, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Card Profile Frequency
SELECT
    'Card_Profile_Frequency',
    Card_Profile_Frequency_Band,
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100,2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate,0),2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns,0),2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Card_Profile_Frequency_Band, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Transaction Amount Deviation
SELECT
    'Transaction_Amount_Deviation',
    Transaction_Amount_Deviation_Band,
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100,2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate,0),2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns,0),2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Transaction_Amount_Deviation_Band, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Card Transaction Z Score
SELECT
    'Card_Transaction_ZScore',
    Card_Transaction_ZScore_Band,
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100,2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate,0),2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns,0),2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Card_Transaction_ZScore_Band, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- TransactionAmt Z-Score
SELECT
    'TransactionAmt_ZScore',
    TransactionAmt_ZScore_Band,
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100,2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate,0),2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns,0),2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY TransactionAmt_ZScore_Band, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Total M True Flags
SELECT
    'Total_M_True_Flags',
    CAST(Total_M_True_Flags AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Total_M_True_Flags, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- Total M Unknown Flags
SELECT
    'Total_M_Unknown_Flags',
    CAST(Total_M_Unknown_Flags AS STRING),
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY Total_M_Unknown_Flags, p.overall_fraud_rate, p.total_fraud_txns

UNION ALL

-- M4 Frequency (dynamic band, train-only thresholds)
SELECT
    'M4_Frequency',
    M4_Frequency_Band,
    COUNT(*),
    SUM(isFraud),
    ROUND(AVG(isFraud) * 100, 2),
    ROUND((AVG(isFraud) * 100) / NULLIF(p.overall_fraud_rate, 0), 2),
    ROUND(SUM(isFraud) * 100.0 / NULLIF(p.total_fraud_txns, 0), 2)
FROM fraud_detection.feature_refinement_store f
CROSS JOIN portfolio_stats p
WHERE f.dataset_split = 'train'
GROUP BY M4_Frequency_Band, p.overall_fraud_rate, p.total_fraud_txns
;