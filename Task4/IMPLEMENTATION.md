# Реализация задания 4: Повышение оперативности и стабильности работы CRM

## Цель задания

Обеспечить разделение потоков операций: запросы на выгрузку данных не должны влиять на транзакционные операции в CRM. Решение основано на использовании Change Data Capture (CDC) через Debezium для репликации данных из CRM в ClickHouse в реальном времени.

## Архитектура решения

### Компоненты системы

1. **PostgreSQL CRM** - источник данных с включенным логическим реплицированием
2. **Debezium Connect** - CDC-коннектор для отслеживания изменений в PostgreSQL
3. **Kafka** - брокер сообщений для передачи изменений
4. **ClickHouse** - OLAP база данных с KafkaEngine для приема данных
5. **MaterializedView** - витрина данных для отчётности

### Поток данных

```
PostgreSQL CRM → Debezium → Kafka → ClickHouse (KafkaEngine) → MaterializedView → Витрина данных
```

## Реализованные компоненты

### 1. Настройка PostgreSQL для CDC

В `docker-compose.yaml` настроен PostgreSQL с параметрами:
- `wal_level=logical` - включено логическое реплицирование
- `max_replication_slots=4` - максимальное количество слотов репликации
- `max_wal_senders=4` - максимальное количество отправителей WAL

### 2. Debezium Connector

Создан конфигурационный файл `Task4/debezium/connectors/crm-connector.json`:
- Отслеживает таблицы `users` и `prostheses` в схеме `public`
- Использует плагин `pgoutput` для логического реплицирования
- Настраивает публикацию `debezium_publication`
- Преобразует данные в JSON формат без схем

### 3. Kafka и Zookeeper

Добавлены сервисы в `docker-compose.yaml`:
- **Zookeeper** - координатор для Kafka
- **Kafka** - брокер сообщений на порту 9092
- Настроена репликация топиков с фактором 1 (для разработки)

### 4. ClickHouse KafkaEngine

Созданы таблицы в `Task4/db-init/clickhouse-cdc-init.sql`:

#### Таблицы KafkaEngine:
- `users_kafka` - прием данных о пользователях из Kafka
- `prostheses_kafka` - прием данных о протезах из Kafka

#### Целевые таблицы:
- `users_target` - хранение данных о пользователях (ReplacingMergeTree)
- `prostheses_target` - хранение данных о протезах (ReplacingMergeTree)

#### MaterializedView:
- `users_mv` - автоматическая загрузка данных из `users_kafka` в `users_target`
- `prostheses_mv` - автоматическая загрузка данных из `prostheses_kafka` в `prostheses_target`

### 5. Витрина данных

Создана витрина `crm_data_mart`:
- Объединяет данные из `users_target` и `prostheses_target`
- Использует MaterializedView `crm_data_mart_mv` для автоматического обновления
- Хранит актуальные данные о пользователях и их протезах

### 6. Обновленная витрина для отчётов

Создана таблица `prosthesis_reports_mart`:
- Объединяет данные из CRM (через CDC) и телеметрии
- Заменяет старую таблицу `user_prosthesis_reports` для API запросов
- Партиционирована по месяцам для оптимизации запросов

### 7. Обновление ReportService

Обновлен `ReportService.java`:
- Изменены запросы для использования новой витрины `prosthesis_reports_mart`
- Методы `getReportsForUser()` и `isDataProcessedForPeriod()` работают с новой витриной

## Настройка и запуск

### 1. Запуск сервисов

```bash
docker-compose up -d
```

### 2. Регистрация Debezium Connector

После запуска всех сервисов зарегистрируйте Debezium connector:

```bash
curl -X POST http://localhost:8084/connectors \
  -H "Content-Type: application/json" \
  -d @Task4/debezium/connectors/crm-connector.json
```

Проверка статуса коннектора:

```bash
curl http://localhost:8084/connectors/crm-postgres-connector/status
```

### 3. Проверка работы CDC

#### Проверка топиков Kafka:

```bash
docker exec -it <kafka-container> kafka-topics --list --bootstrap-server localhost:9092
```

Должны появиться топики:
- `crm_db.public.users`
- `crm_db.public.prostheses`

#### Проверка данных в ClickHouse:

```sql
-- Проверка данных о пользователях
SELECT * FROM reports_db.users_target FINAL LIMIT 10;

-- Проверка данных о протезах
SELECT * FROM reports_db.prostheses_target FINAL LIMIT 10;

-- Проверка витрины данных
SELECT * FROM reports_db.crm_data_mart FINAL LIMIT 10;
```

### 4. Объединение данных телеметрии

Для объединения данных телеметрии с данными CRM выполните скрипт:

```bash
# Подключитесь к ClickHouse
docker exec -it <clickhouse-container> clickhouse-client

# Выполните скрипт
source Task4/db-init/merge-telemetry-to-mart.sql
```

Или обновите Airflow DAG для автоматического объединения данных.

## Преимущества решения

1. **Разделение нагрузок**: Запросы на выгрузку данных выполняются из ClickHouse, не нагружая OLTP базу данных CRM
2. **Реальное время**: Изменения в CRM реплицируются в ClickHouse в реальном времени через CDC
3. **Масштабируемость**: Kafka позволяет масштабировать обработку данных
4. **Надёжность**: Использование Kafka гарантирует доставку сообщений
5. **Гибкость**: Легко добавить новые таблицы для отслеживания

## Мониторинг

### Проверка работы Debezium:

```bash
# Логи Debezium
docker logs debezium-connect

# Статус коннектора
curl http://localhost:8084/connectors/crm-postgres-connector/status
```

### Проверка Kafka:

```bash
# Список топиков
docker exec -it <kafka-container> kafka-topics --list --bootstrap-server localhost:9092

# Просмотр сообщений в топике
docker exec -it <kafka-container> kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic crm_db.public.users \
  --from-beginning
```

### Проверка ClickHouse:

```sql
-- Количество записей в целевых таблицах
SELECT COUNT(*) FROM reports_db.users_target;
SELECT COUNT(*) FROM reports_db.prostheses_target;

-- Проверка витрины
SELECT COUNT(*) FROM reports_db.crm_data_mart;
```

## Обновление Airflow DAG

Для полной интеграции рекомендуется обновить Airflow DAG `prosthesis_reports_etl.py`:

1. Использовать `crm_data_mart` вместо прямых запросов к PostgreSQL CRM
2. Объединять данные из `crm_data_mart` с телеметрией
3. Загружать результаты в `prosthesis_reports_mart`

Пример запроса:

```python
# Вместо запроса к PostgreSQL CRM
query = """
SELECT 
    user_id,
    user_email,
    user_name,
    prosthesis_id,
    prosthesis_model,
    manufacture_date
FROM crm_data_mart FINAL
"""
```

## Устранение неполадок

### Проблема: Debezium не подключается к PostgreSQL

**Решение**: Проверьте, что PostgreSQL запущен с параметрами `wal_level=logical`

### Проблема: Данные не появляются в ClickHouse

**Решение**: 
1. Проверьте логи Kafka: `docker logs kafka`
2. Проверьте логи ClickHouse: `docker logs clickhouse`
3. Убедитесь, что MaterializedView созданы корректно

### Проблема: Дублирование данных

**Решение**: Используйте `FINAL` в запросах к таблицам с движком ReplacingMergeTree

## Дальнейшие улучшения

1. Настройка репликации Kafka для production
2. Добавление мониторинга метрик Kafka и Debezium
3. Настройка retention policy для Kafka топиков
4. Оптимизация партиционирования в ClickHouse
5. Добавление обработки ошибок и retry механизмов

