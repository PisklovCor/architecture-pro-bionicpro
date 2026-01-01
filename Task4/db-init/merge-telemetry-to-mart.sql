-- SQL скрипт для объединения данных телеметрии с данными CRM в витрину prosthesis_reports_mart
-- Этот скрипт можно запустить вручную или использовать в Airflow DAG

USE reports_db;

-- Вставка данных в витрину prosthesis_reports_mart
-- Объединяем данные из CRM (через CDC) и телеметрии
INSERT INTO prosthesis_reports_mart (
    user_id,
    user_email,
    user_name,
    prosthesis_id,
    prosthesis_model,
    manufacture_date,
    report_date,
    usage_count,
    total_usage_minutes,
    avg_battery_level,
    commands_executed,
    last_activity,
    data_period_start,
    data_period_end
)
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
FROM crm_data_mart FINAL AS crm
INNER JOIN user_prosthesis_reports AS tel ON crm.prosthesis_id = tel.prosthesis_id
WHERE NOT EXISTS (
    SELECT 1 FROM prosthesis_reports_mart AS existing
    WHERE existing.user_id = crm.user_id
    AND existing.prosthesis_id = crm.prosthesis_id
    AND existing.report_date = tel.report_date
);

