CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.fuel_sales (
    id           BIGSERIAL PRIMARY KEY,
    station_id   VARCHAR(10)   NOT NULL,
    sale_date    DATE          NOT NULL,
    fuel_type    VARCHAR(20)   NOT NULL,
    liters       NUMERIC(10,2) NOT NULL,
    unit_price   NUMERIC(6,2)  NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    operator     VARCHAR(50),
    loaded_at    TIMESTAMP     DEFAULT NOW(),
    source_file  VARCHAR(255)
);

CREATE UNIQUE INDEX IF NOT EXISTS uix_fuel_sales
    ON raw.fuel_sales(station_id, sale_date, fuel_type);

CREATE SCHEMA IF NOT EXISTS mart;

CREATE TABLE IF NOT EXISTS mart.daily_station_summary (
    station_id      VARCHAR(10),
    sale_date       DATE,
    total_liters    NUMERIC(12,2),
    total_revenue   NUMERIC(14,2),
    top_fuel        VARCHAR(20),
    transaction_cnt INT,
    updated_at      TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (station_id, sale_date)
);

CREATE OR REPLACE VIEW mart.weekly_revenue AS
SELECT
    station_id,
    DATE_TRUNC('week', sale_date)::DATE AS week_start,
    SUM(total_revenue)                  AS weekly_revenue,
    SUM(total_liters)                   AS weekly_liters
FROM mart.daily_station_summary
GROUP BY 1, 2
ORDER BY 2 DESC, 3 DESC;