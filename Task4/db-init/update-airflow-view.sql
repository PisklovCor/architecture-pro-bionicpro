-- SQL скрипт для обновления Airflow DAG
-- Этот скрипт создает представление, которое Airflow может использовать
-- для объединения данных из CRM (через CDC) и телеметрии

USE reports_db;

-- Представление для получения актуальных данных из CRM через CDC
CREATE VIEW IF NOT EXISTS crm_data_view AS
SELECT
    user_id,
    user_email,
    user_name,
    prosthesis_id,
    prosthesis_model,
    manufacture_date
FROM crm_data_mart
FINAL;

-- Представление для объединения CRM данных и телеметрии
-- Airflow будет использовать это представление для создания отчётов
CREATE VIEW IF NOT EXISTS combined_data_view AS
SELECT
    crm.user_id,
    crm.user_email,
    crm.user_name,
    crm.prosthesis_id,
    crm.prosthesis_model,
    crm.manufacture_date,
    tel.report_date,
    tel.usage_count,
    tel.total_usage_minutes,
    tel.avg_battery_level,
    tel.commands_executed,
    tel.last_activity,
    tel.data_period_start,
    tel.data_period_end
FROM crm_data_view AS crm
INNER JOIN user_prosthesis_reports AS tel ON crm.prosthesis_id = tel.prosthesis_id;

