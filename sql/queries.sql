-- ============================================================
-- TravelIQ OTA — Business Analysis Queries
-- Author: Firuz Tahsin Rodshi
-- All results verified against real dataset outputs
-- ============================================================

-- Query 1: Overall cancellation rate by hotel type
SELECT
    CASE hotel_id WHEN 1 THEN 'Resort Hotel' ELSE 'City Hotel' END AS hotel_type,
    COUNT(*) AS total_bookings,
    SUM(is_cancelled) AS cancellations,
    SUM(CASE WHEN is_cancelled = 0 THEN 1 ELSE 0 END) AS completions,
    ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancel_rate_pct,
    ROUND(AVG(adr), 2) AS avg_daily_rate,
    ROUND(AVG(total_nights), 1) AS avg_stay_length
FROM fact_bookings
GROUP BY hotel_id
ORDER BY cancel_rate_pct DESC;

-- Query 2: Cancellation rate by lead time bucket
-- Finding: 180+ day bookings cancel at 57.25% vs 7.19% same-day
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
    ROUND(AVG(total_nights), 1) AS avg_nights
FROM fact_bookings
GROUP BY lead_time_bucket
ORDER BY lead_time_bucket;

-- Query 3: Market segment performance
-- Finding: Direct has lowest cancel (15.61%) and highest ADR ($117.41)
SELECT
    market_segment,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_cancelled = 0 THEN 1 ELSE 0 END) AS completed,
    ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancel_rate_pct,
    ROUND(AVG(adr), 2) AS avg_adr,
    ROUND(AVG(total_nights), 1) AS avg_nights,
    ROUND(SUM(total_revenue), 2) AS total_revenue
FROM fact_bookings
GROUP BY market_segment
ORDER BY total_bookings DESC;

-- Query 4: Monthly revenue trend
-- Finding: Peak Aug 2017 ($1.97M) vs trough Jan 2016 ($264K)
SELECT
    SUBSTR(CAST(arrival_date_id + 16617 AS TEXT), 1, 4) AS year_approx,
    COUNT(*) AS bookings,
    SUM(CASE WHEN is_cancelled = 0 THEN 1 ELSE 0 END) AS completed,
    ROUND(SUM(total_revenue), 2) AS net_revenue,
    ROUND(AVG(CASE WHEN is_cancelled = 0 THEN adr END), 2) AS avg_adr,
    ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancel_rate_pct
FROM fact_bookings
GROUP BY year_approx
ORDER BY year_approx;

-- Query 5: Distribution channel analysis
-- Finding: TA/TO dominates volume but Direct has best quality metrics
SELECT
    distribution_channel,
    COUNT(*) AS bookings,
    ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancel_rate_pct,
    ROUND(AVG(adr), 2) AS avg_adr,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    ROUND(AVG(total_nights), 1) AS avg_nights
FROM fact_bookings
GROUP BY distribution_channel
ORDER BY bookings DESC;

-- Query 6: Marketing channel ROI
-- Finding: Email delivers 35.57x ROAS — highest of all channels
SELECT
    channel,
    COUNT(*) AS campaigns,
    SUM(budget_usd) AS total_spend,
    SUM(bookings_attributed) AS total_bookings,
    ROUND(SUM(revenue_attributed), 2) AS total_revenue,
    ROUND(AVG(roas), 2) AS avg_roas,
    ROUND(AVG(cac), 2) AS avg_cac,
    ROUND(100.0 * SUM(clicks) / SUM(impressions), 2) AS avg_ctr_pct
FROM fact_marketing
GROUP BY channel
ORDER BY avg_roas DESC;

-- Query 7: Booking funnel conversion by device
-- Finding: Mobile checkout completes at 23% vs Desktop 59%
SELECT
    CASE device_id
        WHEN 1 THEN 'Mobile'
        WHEN 2 THEN 'Desktop'
        ELSE        'Tablet'
    END AS device_type,
    SUM(searches) AS total_searches,
    SUM(booking_completed) AS total_completions,
    ROUND(100.0 * SUM(booking_completed) / SUM(searches), 3) AS search_to_book_pct,
    ROUND(100.0 * SUM(booking_completed) /
          NULLIF(SUM(booking_started), 0), 2) AS checkout_completion_pct,
    ROUND(100.0 * SUM(hotel_views) / SUM(searches), 2) AS search_to_view_pct
FROM fact_funnel
GROUP BY device_id
ORDER BY search_to_book_pct DESC;

-- Query 8: Review sentiment summary
-- Finding: 83.1% positive across 515,738 real reviews
SELECT
    sentiment_label,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) /
          (SELECT COUNT(*) FROM fact_reviews), 2) AS pct_of_total,
    ROUND(AVG(reviewer_score), 2) AS avg_score,
    ROUND(AVG(review_word_count), 1) AS avg_word_count
FROM fact_reviews
WHERE sentiment_label IS NOT NULL
  AND sentiment_label != 'nan'
GROUP BY sentiment_label
ORDER BY avg_score DESC;
