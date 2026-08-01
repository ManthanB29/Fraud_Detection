-- =========================================================
-- FRAUD DETECTION PROJECT
-- VALIDATION: FRAUD RATE BY SCORE BAND (10-POINT BANDS)
--
-- Purpose:
--     Finer-grained version of validation_risk_category_rate —
--     checks monotonicity at 10-point score-band resolution
--     instead of just the 4 broad categories.
--
-- Source:
--     final_transaction_risk_score
--
-- Notes:
--     - Filtered to dataset_split = 'validation'.
--     - Observed result on this run: fraud rate increased at
--       every single band (0.7% -> 1.45% -> 1.5% -> 3.18% ->
--       3.36% -> 7.74% -> 8.49% -> 12.9%), with no dips —
--       a stronger result than the 4-category view alone, since
--       it shows the score discriminates well even at finer
--       resolution.
--     - The top bands (60+) have low transaction counts
--       (~600 and ~30 respectively in this run) — note sample
--       size explicitly whenever citing these bands, since a
--       small population makes the rate more sensitive to
--       individual outcomes.
-- =========================================================

SELECT
    CONCAT(
        CAST(FLOOR(final_risk_score/10)*10 AS STRING), '-',
        CAST(FLOOR(final_risk_score/10)*10 + 9 AS STRING)
    ) AS score_band,
    COUNT(*) AS transactions,
    SUM(isFraud) AS fraud_transactions,
    ROUND(SAFE_DIVIDE(SUM(isFraud), COUNT(*)) * 100, 2) AS fraud_rate_percent
FROM fraud_detection.final_transaction_risk_score
WHERE dataset_split = 'validation'
GROUP BY score_band
ORDER BY MIN(FLOOR(final_risk_score/10));