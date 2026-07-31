-- =========================================================
-- ENTITY RISK SCORE
--
-- Purpose:
--     Score card, address, email, and device identity segments
--     by fraud lift, using percentile-based tiers sized to the
--     actual eligible population (131 rows -> 5 tiers/quintiles).
--
-- Source:
--     fraud_analysis_results (train-only lift values)
--
-- Notes:
--     - Eligibility requires Transactions > 100 (stability) and
--       Fraud_Lift > 1 (some measurable elevation above baseline).
--     - Excludes context, behavior, M-feature, identity-completeness,
--       and distance signals, which are scored in their own
--       dedicated risk tables — prevents double-counting the same
--       signal across multiple pillars.
--     - Tier boundaries (p20/p40/p60/p80) are computed fresh from
--       the eligible population each time this table is rebuilt —
--       self-recalibrating if the underlying data changes.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.entity_risk_score AS

WITH eligible AS (
    SELECT *
    FROM fraud_detection.fraud_analysis_results
    WHERE Transactions > 100
      AND Fraud_Lift > 1
      AND NOT (
            Analysis_Type LIKE 'Missing_%'
            -- M RISK LAYER FEATURES
            OR Analysis_Type LIKE 'Total_%'
            OR Analysis_Type IN ('M1','M2','M3','M4','M5','M6','M7','M8','M9')
            OR Analysis_Type LIKE 'M4%'
            -- IDENTITY LAYER FEATURES
            OR Segment IN ('unknown', '-999')
            OR Analysis_Type LIKE 'Identity_%'
            -- CONTEXT LAYER FEATURES
            OR Analysis_Type IN (
                'ProductCD','Amount_Bucket','Transaction_Hour','Card_Type','Card_Network','Device_Type','Transaction_Time_Category'
            )
            -- BEHAVIORAL / DERIVED FEATURES
            OR Analysis_Type LIKE '%ZScore%'
            OR Analysis_Type LIKE '%Deviation%'
            OR Analysis_Type LIKE '%Frequency%'
            OR Analysis_Type LIKE '%Count%'
            OR Analysis_Type LIKE '%Velocity%'
            OR Analysis_Type LIKE 'Distance%'
      )
),

lift_percentiles AS (
    SELECT
        APPROX_QUANTILES(Fraud_Lift, 100)[OFFSET(20)] AS p20,
        APPROX_QUANTILES(Fraud_Lift, 100)[OFFSET(40)] AS p40,
        APPROX_QUANTILES(Fraud_Lift, 100)[OFFSET(60)] AS p60,
        APPROX_QUANTILES(Fraud_Lift, 100)[OFFSET(80)] AS p80
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
        WHEN Fraud_Lift < (SELECT p20 FROM lift_percentiles) THEN 1
        WHEN Fraud_Lift < (SELECT p40 FROM lift_percentiles) THEN 2
        WHEN Fraud_Lift < (SELECT p60 FROM lift_percentiles) THEN 3
        WHEN Fraud_Lift < (SELECT p80 FROM lift_percentiles) THEN 4
        ELSE 5
    END AS entity_risk_score
FROM eligible;