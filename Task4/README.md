# Задание 4: Повышение оперативности и стабильности работы CRM

## Описание

Реализация механизма Change Data Capture (CDC) для разделения потоков операций: запросы на выгрузку данных не должны влиять на транзакционные операции в CRM.

## Решение

Использование Debezium для отслеживания изменений в PostgreSQL CRM и репликации данных в ClickHouse через Kafka в реальном времени.

## Структура проекта

```
Task4/
├── README.md                          # Этот файл
├── IMPLEMENTATION.md                  # Подробная документация по реализации
├── CHECKLIST.md                      # Чеклист для проверки перед отправкой
├── setup-debezium.sh                 # Скрипт для настройки Debezium connector
├── db-init/
│   ├── clickhouse-cdc-init.sql       # Инициализация ClickHouse для CDC
│   ├── update-airflow-view.sql       # Представления для Airflow
│   └── merge-telemetry-to-mart.sql   # Скрипт объединения данных телеметрии
└── debezium/
    └── connectors/
        └── crm-connector.json        # Конфигурация Debezium connector
```

## Быстрый старт

### 1. Запуск сервисов

```bash
docker-compose up -d
```

### 2. Регистрация Debezium connector

```bash
cd Task4
chmod +x setup-debezium.sh
./setup-debezium.sh
```

Или вручную:

```bash
curl -X POST http://localhost:8084/connectors \
  -H "Content-Type: application/json" \
  -d @Task4/debezium/connectors/crm-connector.json
```

### 3. Проверка работы

```bash
# Проверка статуса connector
curl http://localhost:8084/connectors/crm-postgres-connector/status

# Проверка данных в ClickHouse
docker exec -it <clickhouse-container> clickhouse-client -q "SELECT COUNT(*) FROM reports_db.users_target"
```

## Компоненты решения

1. **PostgreSQL CRM** - источник данных с логическим реплицированием
2. **Debezium Connect** - CDC коннектор
3. **Kafka** - брокер сообщений
4. **ClickHouse** - OLAP база данных с KafkaEngine
5. **MaterializedView** - витрина данных для отчётности

## Поток данных

```
PostgreSQL CRM → Debezium → Kafka → ClickHouse (KafkaEngine) → MaterializedView → Витрина данных
```

## Документация

- [IMPLEMENTATION.md](IMPLEMENTATION.md) - подробная документация по реализации
- [CHECKLIST.md](CHECKLIST.md) - чеклист для проверки перед отправкой

## Изменения в проекте

### docker-compose.yaml
- Добавлены сервисы: Kafka, Zookeeper, Debezium Connect
- Настроен PostgreSQL CRM для логического реплицирования
- Настроен ClickHouse с зависимостью от Kafka

### bionicpro-reports
- Обновлен `ReportService.java` для использования новой витрины `prosthesis_reports_mart`

## Проверка работы

См. подробные инструкции в [CHECKLIST.md](CHECKLIST.md)

