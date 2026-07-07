-- ============================================================
-- TravelIQ OTA — Business Intelligence Views
-- Author: Firuz Tahsin Rodshi
-- ============================================================

-- View 1: Monthly Revenue Summary
CREATE VIEW IF NOT EXISTS v_monthly_revenue AS
SELECT
    SUBSTR(CAST(arrival_date_id + 16617 AS TEXT), 1, 7) AS year_month,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_cancelled = 0 THEN 1 ELSE 0 END) AS completed_bookings,
    SUM(CASE WHEN is_cancelled = 1 THEN 1 ELSE 0 END) AS cancelled_bookings,
    ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancellation_rate_pct,
    ROUND(SUM(total_revenue), 2) AS net_revenue,
    ROUND(AVG(CASE WHEN is_cancelled = 0 THEN adr END), 2) AS avg_daily_rate,
    ROUND(AVG(CASE WHEN is_cancelled = 0 THEN total_nights END), 1) AS avg_stay_length
FROM fact_bookings
GROUP BY year_month
ORDER BY year_month;

-- View 2: Market Segment Performance
CREATE VIEW IF NOT EXISTS v_segment_performance AS
SELECT
    market_segment,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_cancelled = 0 THEN 1 ELSE 0 END) AS completed,
    ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancel_rate_pct,
    ROUND(AVG(adr), 2) AS avg_adr,
    ROUND(AVG(lead_time), 1) AS avg_lead_days,
    ROUND(AVG(total_nights), 1) AS avg_nights,
    ROUND(SUM(total_revenue), 2) AS total_revenue
FROM fact_bookings
GROUP BY market_segment
ORDER BY total_bookings DESC;

-- View 3: Lead Time Cancellation Risk
CREATE VIEW IF NOT EXISTS v_lead_time_risk AS
SELECT
    CASE
        WHEN lead_time = 0    THEN '1. Same Day'
        WHEN lead_time <= 7   THEN '2. 1-7 Days'
        WHEN lead_time <= 30  THEN '3. 8-30 Days'
        WHEN lead_time <= 90  THEN '4. 31-90 Days'
        WHEN lead_time <= 180 THEN '5. 91-180 Days'
        ELSE                       '6. 180+ Days'
    END AS lead_time_bucket,
    COUNT(*) AS bookings,
    ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancel_rate_pct,
    ROUND(AVG(adr), 2) AS avg_adr,
    ROUND(AVG(total_nights), 1) AS avg_nights,
    MIN(lead_time) AS sort_order
FROM fact_bookings
GROUP BY lead_time_bucket
ORDER BY sort_order;

-- View 4: Marketing Channel ROI
CREATE VIEW IF NOT EXISTS v_marketing_roi AS
SELECT
    channel,
    COUNT(*) AS campaigns,
    SUM(budget_usd) AS total_spend,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(bookings_attributed) AS total_bookings,
    ROUND(SUM(revenue_attributed), 2) AS total_revenue,
    ROUND(AVG(roas), 2) AS avg_roas,
    ROUND(AVG(cac), 2) AS avg_cac,
    ROUND(100.0 * SUM(clicks) / SUM(impressions), 2) AS avg_ctr_pct
FROM fact_marketing
GROUP BY channel
ORDER BY avg_roas DESC;

-- View 5: Booking Funnel by Device
CREATE VIEW IF NOT EXISTS v_funnel_by_device AS
SELECT
    CASE device_id
        WHEN 1 THEN 'Mobile'
        WHEN 2 THEN 'Desktop'
        ELSE        'Tablet'
    END AS device_type,
    SUM(searches) AS total_searches,
    SUM(hotel_views) AS total_views,
    SUM(booking_started) AS total_started,
    SUM(booking_completed) AS total_completed,
    ROUND(100.0 * SUM(hotel_views) /
          NULLIF(SUM(searches), 0), 2) AS search_to_view_pct,
    ROUND(100.0 * SUM(booking_started) /
          NULLIF(SUM(hotel_views), 0), 2) AS view_to_start_pct,
    ROUND(100.0 * SUM(booking_completed) /
          NULLIF(SUM(booking_started), 0), 2) AS checkout_completion_pct,
    ROUND(100.0 * SUM(booking_completed) /
          NULLIF(SUM(searches), 0), 3) AS overall_cvr_pct
FROM fact_funnel
GROUP BY device_id
ORDER BY overall_cvr_pct DESC;

-- View 6: Review Sentiment Summary
CREATE VIEW IF NOT EXISTS v_review_sentiment AS
SELECT
    sentiment_label,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) /
          (SELECT COUNT(*) FROM fact_reviews
           WHERE sentiment_label IS NOT NULL
             AND sentiment_label != 'nan'), 2) AS pct_of_total,
    ROUND(AVG(reviewer_score), 2) AS avg_score,
    ROUND(AVG(review_word_count), 1) AS avg_word_count
FROM fact_reviews
WHERE sentiment_label IS NOT NULL
  AND sentiment_label != 'nan'
GROUP BY sentiment_label
ORDER BY avg_score DESC;

-- View 7: Distribution Channel Quality
CREATE VIEW IF NOT EXISTS v_channel_quality AS
SELECT
    distribution_channel,
    COUNT(*) AS total_bookings,
    ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancel_rate_pct,
    ROUND(AVG(adr), 2) AS avg_adr,
    ROUND(AVG(total_nights), 1) AS avg_nights,
    ROUND(SUM(total_revenue), 2) AS net_revenue,
    ROUND(AVG(special_requests), 2) AS avg_special_requests
FROM fact_bookings
GROUP BY distribution_channel
ORDER BY net_revenue DESC;

-- View 8: Hotel Type Comparison
CREATE VIEW IF NOT EXISTS v_hotel_comparison AS
SELECT
    CASE hotel_id
        WHEN 1 THEN 'Resort Hotel'
        ELSE        'City Hotel'
    END AS hotel_type,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_cancelled = 0 THEN 1 ELSE 0 END) AS completed,
    ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancel_rate_pct,
    ROUND(AVG(CASE WHEN is_cancelled = 0 THEN adr END), 2) AS avg_adr,
    ROUND(AVG(CASE WHEN is_cancelled = 0 THEN total_nights END), 1) AS avg_stay,
    ROUND(SUM(total_revenue), 2) AS net_revenue,
    ROUND(AVG(CASE WHEN is_cancelled = 0 THEN
        nights_weekend * 1.0 / NULLIF(total_nights, 0)
    END), 2) AS weekend_night_ratio
FROM fact_bookings
GROUP BY hotel_id;
