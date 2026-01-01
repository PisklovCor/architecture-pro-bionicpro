-- Инициализация ClickHouse для CDC из Kafka
-- Этот скрипт создает таблицы KafkaEngine и MaterializedView для витрины данных

USE reports_db;

-- Таблица для приема данных о пользователях из Kafka
CREATE TABLE IF NOT EXISTS users_kafka (
    id String,
    email String,
    name String,
    created_at DateTime,
    updated_at DateTime,
    _kafka_offset UInt64,
    _kafka_topic String,
    _kafka_partition UInt64,
    _kafka_timestamp DateTime
) ENGINE = Kafka()
SETTINGS
    kafka_broker_list = 'kafka:29092',
    kafka_topic_list = 'crm_db.public.users',
    kafka_group_name = 'clickhouse_users_consumer',
    kafka_format = 'JSONEachRow',
    kafka_row_delimiter = '\n',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

-- Таблица для приема данных о протезах из Kafka
CREATE TABLE IF NOT EXISTS prostheses_kafka (
    id String,
    user_id String,
    model String,
    manufacture_date Date,
    created_at DateTime,
    updated_at DateTime,
    _kafka_offset UInt64,
    _kafka_topic String,
    _kafka_partition UInt64,
    _kafka_timestamp DateTime
) ENGINE = Kafka()
SETTINGS
    kafka_broker_list = 'kafka:29092',
    kafka_topic_list = 'crm_db.public.prostheses',
    kafka_group_name = 'clickhouse_prostheses_consumer',
    kafka_format = 'JSONEachRow',
    kafka_row_delimiter = '\n',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

-- Целевые таблицы для хранения данных из Kafka
CREATE TABLE IF NOT EXISTS users_target (
    id String,
    email String,
    name String,
    created_at DateTime,
    updated_at DateTime,
    _kafka_offset UInt64,
    _kafka_topic String,
    _kafka_partition UInt64,
    _kafka_timestamp DateTime
) ENGINE = ReplacingMergeTree(updated_at)
ORDER BY (id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS prostheses_target (
    id String,
    user_id String,
    model String,
    manufacture_date Date,
    created_at DateTime,
    updated_at DateTime,
    _kafka_offset UInt64,
    _kafka_topic String,
    _kafka_partition UInt64,
    _kafka_timestamp DateTime
) ENGINE = ReplacingMergeTree(updated_at)
ORDER BY (id, user_id)
SETTINGS index_granularity = 8192;

-- MaterializedView для автоматической загрузки данных из Kafka в целевые таблицы
CREATE MATERIALIZED VIEW IF NOT EXISTS users_mv TO users_target AS
SELECT
    id,
    email,
    name,
    created_at,
    updated_at,
    _kafka_offset,
    _kafka_topic,
    _kafka_partition,
    _kafka_timestamp
FROM users_kafka;

CREATE MATERIALIZED VIEW IF NOT EXISTS prostheses_mv TO prostheses_target AS
SELECT
    id,
    user_id,
    model,
    manufacture_date,
    created_at,
    updated_at,
    _kafka_offset,
    _kafka_topic,
    _kafka_partition,
    _kafka_timestamp
FROM prostheses_kafka;

-- Витрина данных для отчётности (объединяет users и prostheses из CRM)
CREATE TABLE IF NOT EXISTS crm_data_mart (
    user_id String,
    user_email String,
    user_name String,
    prosthesis_id String,
    prosthesis_model String,
    manufacture_date Date,
    prosthesis_created_at DateTime,
    prosthesis_updated_at DateTime,
    user_created_at DateTime,
    user_updated_at DateTime
) ENGINE = ReplacingMergeTree(prosthesis_updated_at)
ORDER BY (user_id, prosthesis_id)
SETTINGS index_granularity = 8192;

-- MaterializedView для создания витрины данных из CDC
CREATE MATERIALIZED VIEW IF NOT EXISTS crm_data_mart_mv TO crm_data_mart AS
SELECT
    p.user_id,
    u.email AS user_email,
    u.name AS user_name,
    p.id AS prosthesis_id,
    p.model AS prosthesis_model,
    p.manufacture_date,
    p.created_at AS prosthesis_created_at,
    p.updated_at AS prosthesis_updated_at,
    u.created_at AS user_created_at,
    u.updated_at AS user_updated_at
FROM prostheses_target AS p
INNER JOIN users_target AS u ON p.user_id = u.id;

-- Обновленная витрина для отчётности, объединяющая CRM данные (через CDC) и телеметрию
-- Эта витрина заменяет старую user_prosthesis_reports и использует данные из CRM через CDC
CREATE TABLE IF NOT EXISTS prosthesis_reports_mart (
    user_id String,
    user_email String,
    user_name String,
    prosthesis_id String,
    prosthesis_model String,
    manufacture_date Date,
    report_date Date,
    usage_count UInt32,
    total_usage_minutes UInt32,
    avg_battery_level Float32,
    commands_executed UInt32,
    last_activity DateTime,
    data_period_start DateTime,
    data_period_end DateTime,
    created_at DateTime DEFAULT now()
) ENGINE = ReplacingMergeTree(created_at)
PARTITION BY toYYYYMM(report_date)
ORDER BY (user_id, prosthesis_id, report_date)
SETTINGS index_granularity = 8192;

