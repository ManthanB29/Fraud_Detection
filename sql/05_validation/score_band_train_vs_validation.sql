-- =========================================================
-- FRAUD DETECTION PROJECT
-- SCORE BAND FRAUD RATE — TRAIN vs VALIDATION COMPARISON
--
-- Purpose:
--     Finer-grained (10-point band) version of the risk
--     category comparison above — checks monotonicity at
--     higher resolution, train vs. validation side by side.
--
-- Source:
--     final_transaction_risk_score
--
-- Notes:
--     - Same reference/contrast caveat as above: train is not
--       evidence of generalization, only validation is.
--     - Note sample size in the top bands (60+) explicitly when
--       citing them — both windows have low transaction counts
--       there, making the rate more sensitive to individual
--       outcomes.
-- =========================================================

SELECT
    CONCAT(
        CAST(FLOOR(final_risk_score/10)*10 AS STRING), '-',
        CAST(FLOOR(final_risk_score/10)*10 + 9 AS STRING)
    ) AS score_band,

    -- TRAIN WINDOW
    COUNTIF(dataset_split = 'train') AS train_transactions,
    SUM(CASE WHEN dataset_split = 'train' THEN isFraud ELSE 0 END) AS train_fraud_transactions,
    ROUND(
        SAFE_DIVIDE(
            SUM(CASE WHEN dataset_split = 'train' THEN isFraud ELSE 0 END),
            COUNTIF(dataset_split = 'train')
        ) * 100, 2
    ) AS train_fraud_rate_percent,

    -- VALIDATION WINDOW
    COUNTIF(dataset_split = 'validation') AS validation_transactions,
    SUM(CASE WHEN dataset_split = 'validation' THEN isFraud ELSE 0 END) AS validation_fraud_transactions,
    ROUND(
        SAFE_DIVIDE(
            SUM(CASE WHEN dataset_split = 'validation' THEN isFraud ELSE 0 END),
            COUNTIF(dataset_split = 'validation')
        ) * 100, 2
    ) AS validation_fraud_rate_percent

FROM fraud_detection.final_transaction_risk_score
GROUP BY score_band
ORDER BY MIN(FLOOR(final_risk_score/10));