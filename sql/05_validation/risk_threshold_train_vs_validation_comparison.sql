-- =========================================================
-- FRAUD DETECTION PROJECT
-- RISK THRESHOLD ANALYSIS — TRAIN vs VALIDATION COMPARISON
--
-- Purpose:
--     Side-by-side comparison of the threshold/lift sweep on
--     train (data the risk weights were learned from) vs.
--     validation (unseen data). Train is shown ONLY as a
--     reference/contrast point — it is not evidence of
--     generalization, since the weights were fit on it.
--     VALIDATION is the only column that constitutes genuine
--     out-of-sample proof.
--
-- Source:
--     final_transaction_risk_score
--
-- Notes:
--     - If train's lift curve is dramatically higher than
--       validation's at every threshold, that's a signal of
--       overfitting to train-specific noise. If the two curves
--       have a broadly similar SHAPE (lift increasing steadily
--       with threshold) even at different absolute levels,
--       that's a reassuring sign the framework generalizes.
-- =========================================================

WITH train_totals AS (
    SELECT
        COUNT(*) AS total_transactions,
        SUM(isFraud) AS total_fraud
    FROM fraud_detection.final_transaction_risk_score
    WHERE dataset_split = 'train'
),

validation_totals AS (
    SELECT
        COUNT(*) AS total_transactions,
        SUM(isFraud) AS total_fraud
    FROM fraud_detection.final_transaction_risk_score
    WHERE dataset_split = 'validation'
),

thresholds AS (
    SELECT threshold FROM UNNEST([0,10,20,30,40,50,60,70,80]) AS threshold
),

train_metrics AS (
    SELECT
        th.threshold,
        COUNT(*) AS train_transactions_reviewed,
        SUM(f.isFraud) AS train_fraud_transactions,
        ROUND(COUNT(*) * 100.0 / tt.total_transactions, 2) AS train_review_percent,
        ROUND(SUM(f.isFraud) * 100.0 / tt.total_fraud, 2) AS train_capture_percent
    FROM thresholds th
    CROSS JOIN train_totals tt
    JOIN fraud_detection.final_transaction_risk_score f
    ON f.final_risk_score >= th.threshold
    AND f.dataset_split = 'train'
    GROUP BY th.threshold, tt.total_transactions, tt.total_fraud
),

validation_metrics AS (
    SELECT
        th.threshold,
        COUNT(*) AS validation_transactions_reviewed,
        SUM(f.isFraud) AS validation_fraud_transactions,
        ROUND(COUNT(*) * 100.0 / vt.total_transactions, 2) AS validation_review_percent,
        ROUND(SUM(f.isFraud) * 100.0 / vt.total_fraud, 2) AS validation_capture_percent
    FROM thresholds th
    CROSS JOIN validation_totals vt
    JOIN fraud_detection.final_transaction_risk_score f
    ON f.final_risk_score >= th.threshold
    AND f.dataset_split = 'validation'
    GROUP BY th.threshold, vt.total_transactions, vt.total_fraud
)

SELECT
    tm.threshold,
    tm.train_review_percent,
    tm.train_capture_percent,
    ROUND(SAFE_DIVIDE(tm.train_capture_percent, tm.train_review_percent), 2) AS train_lift,
    vm.validation_review_percent,
    vm.validation_capture_percent,
    ROUND(SAFE_DIVIDE(vm.validation_capture_percent, vm.validation_review_percent), 2) AS validation_lift
FROM train_metrics tm
JOIN validation_metrics vm ON tm.threshold = vm.threshold
ORDER BY tm.threshold;