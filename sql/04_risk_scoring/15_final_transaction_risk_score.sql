-- =========================================================
-- FRAUD DETECTION PROJECT
-- FINAL TRANSACTION RISK SCORE
--
-- Source:
--     transaction_layer_scores
--
-- Output:
--     final_transaction_risk_score
--
-- Purpose:
--     Normalize each of the five risk pillars to a 0-1 scale
--     using its train-window maximum, apply business-defined
--     weights (Entity 30 / Identity 25 / Behavior 20 / Context 15
--     / M 10 = 100 total), and produce one explainable 0-100
--     fraud risk score per transaction.
--
-- Notes:
--     - max_values is filtered to dataset_split = 'train'. This
--       is a normalization constant used on EVERY row (train and
--       validation), so — same principle as global_avg_amt/
--       global_std_amt in fraud_feature_store.sql — it must be
--       learned only from train data to avoid validation-window
--       information leaking into the scoring formula.
--     - A validation-window transaction can, in rare cases,
--       exceed its pillar's train-derived max (e.g. more
--       cumulative card history than anything seen in train).
--       SAFE_DIVIDE will simply produce a weighted value over
--       that pillar's intended point-share — this is expected
--       and arguably meaningful (flags "riskier than anything
--       trained on"), not a bug to suppress.
--     - Pillar weights (30/25/20/15/10) reflect a business
--       judgment about which categories of signal matter most:
--       entity-level identifiers and identity completeness are
--       weighted highest, contextual/categorical signals lowest.
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.final_transaction_risk_score AS

WITH max_values AS (
    SELECT
        MAX(entity_score) AS max_entity,
        MAX(identity_score) AS max_identity,
        MAX(behavior_score) AS max_behavior,
        MAX(m_score) AS max_m,
        MAX(context_score) AS max_context
    FROM fraud_detection.transaction_layer_scores
    WHERE dataset_split = 'train'
)

SELECT
    t.*,

    -- =====================================================
    -- WEIGHTED COMPONENT SCORES
    -- =====================================================
    ROUND(SAFE_DIVIDE(t.entity_score, NULLIF(m.max_entity,0)) * 30, 2) AS entity_weighted_score,
    ROUND(SAFE_DIVIDE(t.identity_score, NULLIF(m.max_identity,0)) * 25, 2) AS identity_weighted_score,
    ROUND(SAFE_DIVIDE(t.behavior_score, NULLIF(m.max_behavior,0)) * 20, 2) AS behavior_weighted_score,
    ROUND(SAFE_DIVIDE(t.context_score, NULLIF(m.max_context,0)) * 15, 2) AS context_weighted_score,
    ROUND(SAFE_DIVIDE(t.m_score, NULLIF(m.max_m,0)) * 10, 2) AS m_weighted_score,

    -- =====================================================
    -- FINAL FRAUD RISK SCORE (0-100)
    -- =====================================================
    ROUND(
        SAFE_DIVIDE(t.entity_score, NULLIF(m.max_entity,0)) * 30
      + SAFE_DIVIDE(t.identity_score, NULLIF(m.max_identity,0)) * 25
      + SAFE_DIVIDE(t.behavior_score, NULLIF(m.max_behavior,0)) * 20
      + SAFE_DIVIDE(t.context_score, NULLIF(m.max_context,0)) * 15
      + SAFE_DIVIDE(t.m_score, NULLIF(m.max_m,0)) * 10
    , 2) AS final_risk_score

FROM fraud_detection.transaction_layer_scores t
CROSS JOIN max_values m;