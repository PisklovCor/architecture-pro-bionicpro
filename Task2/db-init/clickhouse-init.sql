-- Инициализация ClickHouse базы данных

CREATE DATABASE IF NOT EXISTS reports_db;

USE reports_db;

-- Витрина отчётности
CREATE TABLE IF NOT EXISTS user_prosthesis_reports (
    user_id String,
    prosthesis_id String,
    report_date Date,
    usage_count UInt32,
    total_usage_minutes UInt32,
    avg_battery_level Float32,
    commands_executed UInt32,
    last_activity DateTime,
    data_period_start DateTime,
    data_period_end DateTime,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(report_date)
ORDER BY (user_id, prosthesis_id, report_date);

-- Индекс для быстрого поиска по user_id
-- В ClickHouse индексы создаются автоматически на основе ORDER BY

