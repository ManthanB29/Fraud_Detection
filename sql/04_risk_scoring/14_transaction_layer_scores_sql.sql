-- =========================================================
-- FRAUD DETECTION PROJECT
-- TRANSACTION LAYER SCORES
--
-- Purpose:
--     Join every transaction against the five risk-score
--     lookup tables (entity, context, behavior, identity_
--     missingness, m) and sum each pillar's contributing
--     signals into one raw score per pillar, per transaction.
--
-- Source:
--     feature_refinement_store
--     entity_risk_score, context_risk_score, behavior_risk_score,
--     identity_missingness_risk_score, m_risk_score
--
-- Output:
--     transaction_layer_scores
--
-- Notes:
--     - No dataset_split filter here, intentionally — every
--       transaction (train AND validation) gets scored, since
--       in production every incoming transaction needs a score.
--       Only the LOOKUP tables being joined against (entity_
--       risk_score, etc.) were built using train-only data;
--       this table just applies those pre-computed weights
--       to everyone.
--     - COALESCE(..., 0) on every join means "no matching risk
--       segment" contributes 0 to that pillar, not NULL — so a
--       transaction with a brand-new card1 never seen before,
--       for example, simply scores 0 on that join rather than
--       breaking the sum.
--     - Entity joins exclude sentinel/unknown values (card1 <>
--       -999, P_emaildomain <> 'unknown', etc.) since those
--       segments were already excluded when entity_risk_score
--       was built — this keeps the join logic aligned with
--       how the lookup table was constructed.
--     - Identity joins (identity_address, identity_card2,
--       identity_card5, identity_distance1) only match when the
--       lookup table itself contains a '-999'/'unknown' row for
--       that Analysis_Type — see identity_missingness_risk_score.sql,
--       which only qualifies -999/unknown segments for this
--       pillar (except Identity_Completeness_Score itself).
-- =========================================================

CREATE OR REPLACE TABLE fraud_detection.transaction_layer_scores AS

SELECT
    f.*,

    -- =====================================================
    -- ENTITY RISK SCORE
    -- =====================================================
    COALESCE(card1.entity_risk_score, 0) +
    COALESCE(card2.entity_risk_score, 0) +
    COALESCE(card3.entity_risk_score, 0) +
    COALESCE(card5.entity_risk_score, 0) +
    COALESCE(email.entity_risk_score, 0) +
    COALESCE(receiver_email.entity_risk_score,0) +
    COALESCE(entity_address.entity_risk_score, 0) +
    COALESCE(device.entity_risk_score, 0) +
    COALESCE(browser.entity_risk_score, 0) +
    COALESCE(os.entity_risk_score, 0) +
    COALESCE(screen_resolution.entity_risk_score,0)
    AS entity_score,

    -- =====================================================
    -- CONTEXT RISK SCORE
    -- =====================================================
    COALESCE(product.context_risk_score, 0) +
    COALESCE(hour.context_risk_score, 0) +
    COALESCE(device_type.context_risk_score, 0) +
    COALESCE(card_network.context_risk_score, 0) +
    COALESCE(card_type.context_risk_score, 0) +
    COALESCE(amount_bucket.context_risk_score, 0)
    AS context_score,

    -- =====================================================
    -- BEHAVIOR RISK SCORE
    -- =====================================================
    COALESCE(card_count.behavior_risk_score, 0) +
    COALESCE(card_profile.behavior_risk_score, 0) +
    COALESCE(card_zscore.behavior_risk_score, 0) +
    COALESCE(txn_zscore.behavior_risk_score, 0) +
    COALESCE(txn_deviation.behavior_risk_score, 0) +
    COALESCE(distance1.behavior_risk_score, 0) +
    COALESCE(distance2.behavior_risk_score, 0)
    AS behavior_score,

    -- =====================================================
    -- IDENTITY RISK SCORE
    -- =====================================================
    COALESCE(identity.identity_missingness_score, 0) +
    COALESCE(identity_address.identity_missingness_score, 0) +
    COALESCE(identity_card2.identity_missingness_score, 0) +
    COALESCE(identity_card5.identity_missingness_score, 0) +
    COALESCE(identity_distance1.identity_missingness_score, 0)
    AS identity_score,

    -- =====================================================
    -- M RISK SCORE
    -- =====================================================
    COALESCE(m1.m_risk_score, 0) +
    COALESCE(m2.m_risk_score, 0) +
    COALESCE(m3.m_risk_score, 0) +
    COALESCE(m4.m_risk_score, 0) +
    COALESCE(m5.m_risk_score, 0) +
    COALESCE(m6.m_risk_score, 0) +
    COALESCE(m7.m_risk_score, 0) +
    COALESCE(m8.m_risk_score, 0) +
    COALESCE(m9.m_risk_score, 0) +
    COALESCE(m4_frequency.m_risk_score, 0) +
    COALESCE(total_m_true.m_risk_score, 0) +
    COALESCE(total_m_unknown.m_risk_score, 0)
    AS m_score

FROM fraud_detection.feature_refinement_store f

-- =====================================================
-- ENTITY JOINS
-- =====================================================
LEFT JOIN fraud_detection.entity_risk_score card1
ON card1.Analysis_Type = 'Card1'
AND SAFE_CAST(f.card1 AS STRING) = card1.Segment
AND f.card1 <> -999

LEFT JOIN fraud_detection.entity_risk_score card2
ON card2.Analysis_Type = 'Card2'
AND SAFE_CAST(f.card2 AS STRING) = card2.Segment
AND f.card2 <> -999

LEFT JOIN fraud_detection.entity_risk_score card3
ON card3.Analysis_Type = 'Card3'
AND SAFE_CAST(f.card3 AS STRING) = card3.Segment
AND f.card3 <> -999

LEFT JOIN fraud_detection.entity_risk_score card5
ON card5.Analysis_Type = 'Card5'
AND SAFE_CAST(f.card5 AS STRING) = card5.Segment
AND f.card5 <> -999

LEFT JOIN fraud_detection.entity_risk_score email
ON email.Analysis_Type = 'P_EmailDomain'
AND f.P_emaildomain = email.Segment
AND f.P_emaildomain <> 'unknown'

LEFT JOIN fraud_detection.entity_risk_score receiver_email
ON receiver_email.Analysis_Type = 'R_EmailDomain'
AND f.R_emaildomain = receiver_email.Segment
AND f.R_emaildomain <> 'unknown'

LEFT JOIN fraud_detection.entity_risk_score entity_address
ON entity_address.Analysis_Type = 'Address'
AND SAFE_CAST(f.addr1 AS STRING) = entity_address.Segment
AND f.addr1 <> -999

LEFT JOIN fraud_detection.entity_risk_score device
ON device.Analysis_Type = 'Device_Info'
AND f.DeviceInfo = device.Segment
AND f.DeviceInfo <> 'unknown'

LEFT JOIN fraud_detection.entity_risk_score browser
ON browser.Analysis_Type = 'Browser'
AND f.id_31 = browser.Segment
AND f.id_31 <> 'unknown'

LEFT JOIN fraud_detection.entity_risk_score os
ON os.Analysis_Type = 'Operating System'
AND f.id_30 = os.Segment
AND f.id_30 <> 'unknown'

LEFT JOIN fraud_detection.entity_risk_score screen_resolution
ON screen_resolution.Analysis_Type = 'Screen Resolution'
AND f.id_33 = screen_resolution.Segment
AND f.id_33 <> 'unknown'

-- =====================================================
-- CONTEXT JOINS
-- =====================================================
LEFT JOIN fraud_detection.context_risk_score product
ON product.Analysis_Type = 'ProductCD'
AND f.ProductCD = product.Segment
AND f.ProductCD <> 'unknown'

LEFT JOIN fraud_detection.context_risk_score hour
ON hour.Analysis_Type = 'Transaction_Hour'
AND SAFE_CAST(f.TransactionHour AS STRING) = hour.Segment

LEFT JOIN fraud_detection.context_risk_score device_type
ON device_type.Analysis_Type = 'Device_Type'
AND f.DeviceType = device_type.Segment
AND f.DeviceType <> 'unknown'

LEFT JOIN fraud_detection.context_risk_score card_network
ON card_network.Analysis_Type = 'Card_Network'
AND f.card4 = card_network.Segment
AND f.card4 <> 'unknown'

LEFT JOIN fraud_detection.context_risk_score card_type
ON card_type.Analysis_Type = 'Card_Type'
AND f.card6 = card_type.Segment
AND f.card6 <> 'unknown'

LEFT JOIN fraud_detection.context_risk_score amount_bucket
ON amount_bucket.Analysis_Type = 'Amount_Bucket'
AND f.Amount_Bucket = amount_bucket.Segment

-- =====================================================
-- BEHAVIOR JOINS
-- =====================================================
LEFT JOIN fraud_detection.behavior_risk_score card_count
ON card_count.Analysis_Type = 'Card_Transaction_Count'
AND f.Card_Transaction_Count_Band = card_count.Segment

LEFT JOIN fraud_detection.behavior_risk_score card_profile
ON card_profile.Analysis_Type = 'Card_Profile_Frequency'
AND f.Card_Profile_Frequency_Band = card_profile.Segment

LEFT JOIN fraud_detection.behavior_risk_score card_zscore
ON card_zscore.Analysis_Type = 'Card_Transaction_ZScore'
AND f.Card_Transaction_ZScore_Band = card_zscore.Segment

LEFT JOIN fraud_detection.behavior_risk_score txn_zscore
ON txn_zscore.Analysis_Type = 'TransactionAmt_ZScore'
AND f.TransactionAmt_ZScore_Band = txn_zscore.Segment

LEFT JOIN fraud_detection.behavior_risk_score txn_deviation
ON txn_deviation.Analysis_Type = 'Transaction_Amount_Deviation'
AND f.Transaction_Amount_Deviation_Band = txn_deviation.Segment

LEFT JOIN fraud_detection.behavior_risk_score distance1
ON distance1.Analysis_Type = 'Distance_1'
AND SAFE_CAST(f.dist1 AS STRING) = distance1.Segment
AND f.dist1 <> -999

LEFT JOIN fraud_detection.behavior_risk_score distance2
ON distance2.Analysis_Type = 'Distance_2'
AND SAFE_CAST(f.dist2 AS STRING) = distance2.Segment
AND f.dist2 <> -999

-- =====================================================
-- IDENTITY COMPLETENESS JOINS
-- =====================================================
LEFT JOIN fraud_detection.identity_missingness_risk_score identity
ON identity.Analysis_Type = 'Identity_Completeness_Score'
AND SAFE_CAST(f.Identity_Completeness_Score AS STRING) = identity.Segment

-- =====================================================
-- Missing Address, Card2, Card5, Distance1
-- Only joins when the lookup table has a -999/unknown row
-- =====================================================
LEFT JOIN fraud_detection.identity_missingness_risk_score identity_address
ON identity_address.Analysis_Type = 'Address'
AND SAFE_CAST(f.addr1 AS STRING) = identity_address.Segment

LEFT JOIN fraud_detection.identity_missingness_risk_score identity_card2
ON identity_card2.Analysis_Type = 'Card2'
AND SAFE_CAST(f.card2 AS STRING) = identity_card2.Segment

LEFT JOIN fraud_detection.identity_missingness_risk_score identity_card5
ON identity_card5.Analysis_Type = 'Card5'
AND SAFE_CAST(f.card5 AS STRING) = identity_card5.Segment

LEFT JOIN fraud_detection.identity_missingness_risk_score identity_distance1
ON identity_distance1.Analysis_Type = 'Distance_1'
AND SAFE_CAST(f.dist1 AS STRING) = identity_distance1.Segment

-- =====================================================
-- M JOINS
-- =====================================================
LEFT JOIN fraud_detection.m_risk_score m1
ON m1.Analysis_Type = 'M1'
AND f.M1 = m1.Segment

LEFT JOIN fraud_detection.m_risk_score m2
ON m2.Analysis_Type = 'M2'
AND f.M2 = m2.Segment

LEFT JOIN fraud_detection.m_risk_score m3
ON m3.Analysis_Type = 'M3'
AND f.M3 = m3.Segment

LEFT JOIN fraud_detection.m_risk_score m4
ON m4.Analysis_Type = 'M4'
AND f.M4 = m4.Segment

LEFT JOIN fraud_detection.m_risk_score m5
ON m5.Analysis_Type = 'M5'
AND f.M5 = m5.Segment

LEFT JOIN fraud_detection.m_risk_score m6
ON m6.Analysis_Type = 'M6'
AND f.M6 = m6.Segment

LEFT JOIN fraud_detection.m_risk_score m7
ON m7.Analysis_Type = 'M7'
AND f.M7 = m7.Segment

LEFT JOIN fraud_detection.m_risk_score m8
ON m8.Analysis_Type = 'M8'
AND f.M8 = m8.Segment

LEFT JOIN fraud_detection.m_risk_score m9
ON m9.Analysis_Type = 'M9'
AND f.M9 = m9.Segment

-- =====================================================
-- M4 Frequency Band
-- =====================================================
LEFT JOIN fraud_detection.m_risk_score m4_frequency
ON m4_frequency.Analysis_Type = 'M4_Frequency'
AND SAFE_CAST(f.M4_Frequency_Band AS STRING) = m4_frequency.Segment

-- =====================================================
-- Total M True Flags Band
-- =====================================================
LEFT JOIN fraud_detection.m_risk_score total_m_true
ON total_m_true.Analysis_Type = 'Total_M_True_Flags'
AND SAFE_CAST(f.Total_M_True_Flags AS STRING) = total_m_true.Segment

-- =====================================================
-- Total M Unknown Flags Band
-- =====================================================
LEFT JOIN fraud_detection.m_risk_score total_m_unknown
ON total_m_unknown.Analysis_Type = 'Total_M_Unknown_Flags'
AND SAFE_CAST(f.Total_M_Unknown_Flags AS STRING) = total_m_unknown.Segment;