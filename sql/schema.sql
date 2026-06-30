-- ============================================================
-- TravelIQ OTA Business Intelligence — Database Schema
-- Author: Firuz Tahsin Rodshi
-- Version: 1.0
-- ============================================================

-- DIMENSION TABLES (reference data)

CREATE TABLE IF NOT EXISTS dim_date (
    date_id INTEGER PRIMARY KEY,
    full_date TEXT NOT NULL,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name TEXT,
    week_of_year INTEGER,
    day_of_month INTEGER,
    day_of_week INTEGER,
    day_name TEXT,
    is_weekend INTEGER,
    is_holiday INTEGER DEFAULT 0,
    season TEXT
);

CREATE TABLE IF NOT EXISTS dim_country (
    country_id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_code TEXT NOT NULL UNIQUE,
    country_name TEXT,
    region TEXT,
    subregion TEXT,
    is_eu INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS dim_hotel (
    hotel_id INTEGER PRIMARY KEY AUTOINCREMENT,
    hotel_name TEXT,
    hotel_type TEXT,        -- 'City Hotel' or 'Resort Hotel'
    country_id INTEGER,
    star_rating REAL,
    total_rooms INTEGER,
    amenity_score REAL,
    FOREIGN KEY (country_id) REFERENCES dim_country(country_id)
);

CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_id INTEGER,
    customer_type TEXT,
    is_repeated_guest INTEGER DEFAULT 0,
    total_previous_bookings INTEGER DEFAULT 0,
    total_previous_cancellations INTEGER DEFAULT 0,
    customer_segment TEXT,  -- assigned by ML later
    FOREIGN KEY (country_id) REFERENCES dim_country(country_id)
);

CREATE TABLE IF NOT EXISTS dim_room (
    room_id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_type TEXT NOT NULL,
    room_category TEXT,
    max_occupancy INTEGER,
    base_rate REAL
);

CREATE TABLE IF NOT EXISTS dim_device (
    device_id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_type TEXT,       -- 'Mobile', 'Desktop', 'Tablet'
    os_type TEXT,
    browser TEXT
);

-- FACT TABLES (transactional data)

CREATE TABLE IF NOT EXISTS fact_bookings (
    booking_id INTEGER PRIMARY KEY AUTOINCREMENT,
    hotel_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    room_id INTEGER,
    arrival_date_id INTEGER,
    booking_date_id INTEGER,
    lead_time INTEGER,
    nights_weekend INTEGER DEFAULT 0,
    nights_weekday INTEGER DEFAULT 0,
    total_nights INTEGER,
    adults INTEGER DEFAULT 1,
    children INTEGER DEFAULT 0,
    babies INTEGER DEFAULT 0,
    total_guests INTEGER,
    meal_plan TEXT,
    market_segment TEXT,
    distribution_channel TEXT,
    is_cancelled INTEGER DEFAULT 0,
    adr REAL,
    total_revenue REAL,
    required_parking INTEGER DEFAULT 0,
    special_requests INTEGER DEFAULT 0,
    reservation_status TEXT,
    deposit_type TEXT,
    agent_id INTEGER,
    FOREIGN KEY (hotel_id) REFERENCES dim_hotel(hotel_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (arrival_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (room_id) REFERENCES dim_room(room_id)
);

CREATE TABLE IF NOT EXISTS fact_reviews (
    review_id INTEGER PRIMARY KEY AUTOINCREMENT,
    hotel_id INTEGER,
    reviewer_nationality TEXT,
    reviewer_score REAL,
    positive_review TEXT,
    negative_review TEXT,
    review_word_count INTEGER,
    total_reviews_by_reviewer INTEGER,
    review_date TEXT,
    sentiment_label TEXT,   -- 'Positive', 'Neutral', 'Negative'
    sentiment_score REAL,
    FOREIGN KEY (hotel_id) REFERENCES dim_hotel(hotel_id)
);

CREATE TABLE IF NOT EXISTS fact_marketing (
    campaign_id INTEGER PRIMARY KEY AUTOINCREMENT,
    campaign_name TEXT,
    channel TEXT,
    start_date TEXT,
    end_date TEXT,
    target_segment TEXT,
    budget_usd REAL,
    impressions INTEGER,
    clicks INTEGER,
    bookings_attributed INTEGER,
    revenue_attributed REAL,
    cac REAL,
    roas REAL
);

CREATE TABLE IF NOT EXISTS fact_funnel (
    funnel_id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_date TEXT,
    device_id INTEGER,
    market_segment TEXT,
    country_id INTEGER,
    searches INTEGER,
    hotel_views INTEGER,
    wishlists INTEGER,
    booking_started INTEGER,
    payment_reached INTEGER,
    booking_completed INTEGER,
    search_to_view_rate REAL,
    view_to_book_rate REAL,
    overall_conversion_rate REAL,
    FOREIGN KEY (device_id) REFERENCES dim_device(device_id),
    FOREIGN KEY (country_id) REFERENCES dim_country(country_id)
);

CREATE TABLE IF NOT EXISTS fact_payments (
    payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    booking_id INTEGER,
    payment_method TEXT,
    payment_status TEXT,
    amount_usd REAL,
    currency TEXT DEFAULT 'USD',
    payment_date TEXT,
    refund_amount REAL DEFAULT 0,
    is_refunded INTEGER DEFAULT 0,
    FOREIGN KEY (booking_id) REFERENCES fact_bookings(booking_id)
);
