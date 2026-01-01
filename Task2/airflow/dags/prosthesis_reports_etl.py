"""
ETL DAG для подготовки витрины отчётности по протезам.

Процесс:
1. Извлечение данных из CRM (PostgreSQL)
2. Извлечение данных телеметрии из БД (PostgreSQL)
3. Объединение и агрегация данных
4. Загрузка в витрину ClickHouse
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
try:
    from airflow.providers.clickhouse.hooks.clickhouse import ClickHouseHook
    CLICKHOUSE_AVAILABLE = True
except ImportError:
    # Если провайдер ClickHouse не установлен, используем HTTP запросы
    CLICKHOUSE_AVAILABLE = False
    import requests
import logging

# Параметры подключения
CRM_DB_CONN_ID = 'crm_postgres'
TELEMETRY_DB_CONN_ID = 'telemetry_postgres'
CLICKHOUSE_CONN_ID = 'clickhouse_default'

default_args = {
    'owner': 'bionicpro',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'prosthesis_reports_etl',
    default_args=default_args,
    description='ETL процесс для подготовки витрины отчётности по протезам',
    schedule_interval='0 2 * * *',  # Ежедневно в 02:00 UTC
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['etl', 'reports', 'prosthesis'],
)


def extract_crm_data(**context):
    """Извлечение данных о клиентах из CRM."""
    logging.info("Извлечение данных из CRM...")
    
    postgres_hook = PostgresHook(postgres_conn_id=CRM_DB_CONN_ID)
    
    # Получаем данные за последние 24 часа
    execution_date = context['execution_date']
    start_date = execution_date - timedelta(days=1)
    
    query = """
    SELECT 
        u.id as user_id,
        u.email,
        u.name,
        p.id as prosthesis_id,
        p.model,
        p.manufacture_date
    FROM users u
    LEFT JOIN prostheses p ON p.user_id = u.id
    WHERE p.created_at >= %s OR p.updated_at >= %s
    """
    
    records = postgres_hook.get_records(query, parameters=(start_date, start_date))
    logging.info(f"Извлечено {len(records)} записей из CRM")
    
    return records


def extract_telemetry_data(**context):
    """Извлечение данных телеметрии."""
    logging.info("Извлечение данных телеметрии...")
    
    postgres_hook = PostgresHook(postgres_conn_id=TELEMETRY_DB_CONN_ID)
    
    execution_date = context['execution_date']
    start_date = execution_date - timedelta(days=1)
    
    query = """
    SELECT 
        prosthesis_id,
        timestamp,
        sensor_data,
        actuator_commands,
        battery_level
    FROM telemetry_data
    WHERE timestamp >= %s AND timestamp < %s
    ORDER BY prosthesis_id, timestamp
    """
    
    records = postgres_hook.get_records(
        query, 
        parameters=(start_date, execution_date)
    )
    logging.info(f"Извлечено {len(records)} записей телеметрии")
    
    return records


def transform_and_aggregate(**context):
    """Объединение и агрегация данных."""
    logging.info("Трансформация и агрегация данных...")
    
    ti = context['ti']
    crm_data = ti.xcom_pull(task_ids='extract_crm_data')
    telemetry_data = ti.xcom_pull(task_ids='extract_telemetry_data')
    
    # Преобразуем списки записей в словари для удобства
    crm_dict = {}
    for record in crm_data:
        user_id = record[0]
        if user_id not in crm_dict:
            crm_dict[user_id] = []
        crm_dict[user_id].append({
            'user_id': record[0],
            'email': record[1],
            'name': record[2],
            'prosthesis_id': record[3],
            'model': record[4],
            'manufacture_date': record[5]
        })
    
    # Группируем телеметрию по протезам
    telemetry_dict = {}
    for record in telemetry_data:
        prosthesis_id = record[0]
        if prosthesis_id not in telemetry_dict:
            telemetry_dict[prosthesis_id] = []
        telemetry_dict[prosthesis_id].append({
            'prosthesis_id': record[0],
            'timestamp': record[1],
            'sensor_data': record[2],
            'actuator_commands': record[3],
            'battery_level': record[4]
        })
    
    # Агрегируем данные
    aggregated_data = []
    execution_date = context['execution_date']
    report_date = execution_date.date() - timedelta(days=1)
    
    for user_id, prostheses in crm_dict.items():
        for prosthesis_info in prostheses:
            prosthesis_id = prosthesis_info['prosthesis_id']
            if not prosthesis_id:
                continue
                
            telemetry_records = telemetry_dict.get(prosthesis_id, [])
            
            if not telemetry_records:
                continue
            
            # Агрегация метрик
            usage_count = len(telemetry_records)
            total_minutes = usage_count * 5  # Предполагаем 5 минут на использование
            battery_levels = [r['battery_level'] for r in telemetry_records if r['battery_level']]
            avg_battery = sum(battery_levels) / len(battery_levels) if battery_levels else 0.0
            
            commands_count = sum(
                1 for r in telemetry_records 
                if r['actuator_commands'] and len(r['actuator_commands']) > 0
            )
            
            timestamps = [r['timestamp'] for r in telemetry_records]
            last_activity = max(timestamps) if timestamps else execution_date
            first_activity = min(timestamps) if timestamps else execution_date
            
            aggregated_data.append({
                'user_id': str(user_id),
                'prosthesis_id': str(prosthesis_id),
                'report_date': report_date.strftime('%Y-%m-%d'),
                'usage_count': usage_count,
                'total_usage_minutes': total_minutes,
                'avg_battery_level': round(avg_battery, 2),
                'commands_executed': commands_count,
                'last_activity': last_activity.strftime('%Y-%m-%d %H:%M:%S'),
                'data_period_start': first_activity.strftime('%Y-%m-%d %H:%M:%S'),
                'data_period_end': last_activity.strftime('%Y-%m-%d %H:%M:%S'),
            })
    
    logging.info(f"Агрегировано {len(aggregated_data)} записей")
    return aggregated_data


def load_to_clickhouse(**context):
    """Загрузка агрегированных данных в ClickHouse."""
    logging.info("Загрузка данных в ClickHouse...")
    
    ti = context['ti']
    aggregated_data = ti.xcom_pull(task_ids='transform_and_aggregate')
    
    if not aggregated_data:
        logging.info("Нет данных для загрузки")
        return
    
    # Подготовка данных для вставки
    values = []
    for record in aggregated_data:
        values.append((
            record['user_id'],
            record['prosthesis_id'],
            record['report_date'],
            record['usage_count'],
            record['total_usage_minutes'],
            record['avg_battery_level'],
            record['commands_executed'],
            record['last_activity'],
            record['data_period_start'],
            record['data_period_end'],
        ))
    
    # Вставка данных
    insert_query = """
    INSERT INTO user_prosthesis_reports 
    (user_id, prosthesis_id, report_date, usage_count, total_usage_minutes, 
     avg_battery_level, commands_executed, last_activity, 
     data_period_start, data_period_end)
    VALUES
    """
    
    # Формируем значения с экранированием
    value_strings = []
    for val in values:
        value_strings.append(
            f"('{val[0].replace(\"'\", \"''\")}', '{val[1].replace(\"'\", \"''\")}', '{val[2]}', "
            f"{val[3]}, {val[4]}, {val[5]}, {val[6]}, '{val[7]}', '{val[8]}', '{val[9]}')"
        )
    
    full_query = insert_query + ', '.join(value_strings)
    
    if CLICKHOUSE_AVAILABLE:
        clickhouse_hook = ClickHouseHook(clickhouse_conn_id=CLICKHOUSE_CONN_ID)
        clickhouse_hook.run(full_query)
    else:
        # Альтернативный способ через HTTP API
        from airflow.hooks.base import BaseHook
        conn = BaseHook.get_connection(CLICKHOUSE_CONN_ID)
        host = conn.host or 'clickhouse'
        port = conn.port or 8123
        user = conn.login or 'clickhouse_user'
        password = conn.password or 'clickhouse_password'
        
        url = f"http://{host}:{port}/"
        response = requests.post(url, data=full_query, auth=(user, password))
        response.raise_for_status()
    
    logging.info(f"Загружено {len(values)} записей в ClickHouse")


def create_clickhouse_table(**context):
    """Создание таблицы в ClickHouse если не существует."""
    logging.info("Создание таблицы в ClickHouse...")
    
    if CLICKHOUSE_AVAILABLE:
        clickhouse_hook = ClickHouseHook(clickhouse_conn_id=CLICKHOUSE_CONN_ID)
        create_sql = """
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
        """
        clickhouse_hook.run(create_sql)
    else:
        # Альтернативный способ через HTTP API
        from airflow.hooks.base import BaseHook
        conn = BaseHook.get_connection(CLICKHOUSE_CONN_ID)
        host = conn.host or 'clickhouse'
        port = conn.port or 8123
        user = conn.login or 'clickhouse_user'
        password = conn.password or 'clickhouse_password'
        
        create_sql = """
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
        """
        
        url = f"http://{host}:{port}/"
        response = requests.post(url, data=create_sql, auth=(user, password))
        response.raise_for_status()
    
    logging.info("Таблица создана успешно")

create_table_task = PythonOperator(
    task_id='create_clickhouse_table',
    python_callable=create_clickhouse_table,
    dag=dag,
)

# Задачи ETL
extract_crm_task = PythonOperator(
    task_id='extract_crm_data',
    python_callable=extract_crm_data,
    dag=dag,
)

extract_telemetry_task = PythonOperator(
    task_id='extract_telemetry_data',
    python_callable=extract_telemetry_data,
    dag=dag,
)

transform_task = PythonOperator(
    task_id='transform_and_aggregate',
    python_callable=transform_and_aggregate,
    dag=dag,
)

load_task = PythonOperator(
    task_id='load_to_clickhouse',
    python_callable=load_to_clickhouse,
    dag=dag,
)

# Определение зависимостей
create_table_task >> [extract_crm_task, extract_telemetry_task]
[extract_crm_task, extract_telemetry_task] >> transform_task
transform_task >> load_task

