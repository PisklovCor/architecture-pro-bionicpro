# Инструкция по настройке и запуску

## Предварительные требования

- Docker и Docker Compose установлены
- Maven 3.6+ (для локальной сборки, опционально)
- Java 17+ (для локальной разработки, опционально)

## Запуск системы

### 1. Запуск всех сервисов

```bash
docker-compose up -d
```

Это запустит:
- Keycloak (порт 8080)
- Redis (порт 6379)
- PostgreSQL для Keycloak (порт 5433)
- PostgreSQL для CRM (порт 5434)
- PostgreSQL для телеметрии (порт 5435)
- ClickHouse (порты 8123, 9000)
- Airflow (порт 8082)
- bionicpro-auth (порт 8081)
- bionicpro-reports (порт 8000)
- Frontend (порт 3000)

### 2. Инициализация баз данных

Базы данных инициализируются автоматически при первом запуске через SQL скрипты в `Task2/db-init/`.

### 3. Настройка Airflow

1. Откройте Airflow UI: http://localhost:8082
2. Войдите с учётными данными:
   - Username: `airflow`
   - Password: `airflow`
3. Найдите DAG `prosthesis_reports_etl`
4. Включите DAG (переключите переключатель слева)
5. Запустите DAG вручную для первого выполнения

### 4. Настройка подключений в Airflow

В Airflow UI перейдите в Admin → Connections и создайте следующие подключения:

#### CRM PostgreSQL
- Connection Id: `crm_postgres`
- Connection Type: `Postgres`
- Host: `crm_db`
- Schema: `crm_db`
- Login: `crm_user`
- Password: `crm_password`
- Port: `5432`

#### Telemetry PostgreSQL
- Connection Id: `telemetry_postgres`
- Connection Type: `Postgres`
- Host: `telemetry_db`
- Schema: `telemetry_db`
- Login: `telemetry_user`
- Password: `telemetry_password`
- Port: `5432`

#### ClickHouse
- Connection Id: `clickhouse_default`
- Connection Type: `HTTP`
- Host: `clickhouse`
- Login: `clickhouse_user`
- Password: `clickhouse_password`
- Port: `8123`

### 5. Проверка работы

#### Проверка API
```bash
# Health check
curl http://localhost:8000/api/reports/health

# Получение отчёта (требует авторизации)
curl -H "Authorization: Bearer <token>" http://localhost:8000/api/reports
```

#### Проверка ClickHouse
```bash
docker exec -it architecture-pro-bionicpro-clickhouse-1 clickhouse-client --user clickhouse_user --password clickhouse_password

# В консоли ClickHouse:
USE reports_db;
SELECT * FROM user_prosthesis_reports LIMIT 10;
```

#### Проверка Frontend
1. Откройте http://localhost:3000
2. Нажмите "Login"
3. Авторизуйтесь через Keycloak
4. Нажмите "Download Report"

## Структура проекта

```
Task2/
├── ARCHITECTURE.md          # Архитектурная документация
├── CHECKLIST.md             # Чеклист для проверки
├── SETUP.md                 # Этот файл
├── Task2.md                 # Описание задания
├── airflow/
│   └── dags/
│       └── prosthesis_reports_etl.py  # Airflow DAG
└── db-init/
    ├── crm-init.sql         # Инициализация CRM БД
    ├── telemetry-init.sql   # Инициализация телеметрии
    └── clickhouse-init.sql  # Инициализация ClickHouse
```

## Устранение проблем

### Airflow не запускается
- Проверьте логи: `docker-compose logs airflow_webserver`
- Убедитесь, что `airflow_db` запущена
- Проверьте, что все volumes созданы

### DAG не виден в Airflow
- Проверьте, что файл DAG находится в `Task2/airflow/dags/`
- Проверьте логи scheduler: `docker-compose logs airflow_scheduler`
- Убедитесь, что нет синтаксических ошибок в DAG

### API возвращает 401
- Проверьте, что токен передаётся в заголовке `Authorization: Bearer <token>`
- Проверьте, что токен валидный и не истёк
- Проверьте логи сервиса: `docker-compose logs bionicpro-reports`

### API возвращает 404 для данных
- Убедитесь, что Airflow DAG выполнился успешно
- Проверьте, что данные есть в ClickHouse
- Проверьте, что запрашиваемый период обработан

### ClickHouse недоступен
- Проверьте логи: `docker-compose logs clickhouse`
- Убедитесь, что порты 8123 и 9000 не заняты
- Проверьте подключение: `docker exec -it <clickhouse-container> clickhouse-client`

## Остановка системы

```bash
docker-compose down
```

Для полной очистки данных (включая volumes):

```bash
docker-compose down -v
```

## Разработка

### Локальная разработка сервиса отчётов

```bash
cd bionicpro-reports
mvn clean install
mvn spring-boot:run
```

### Локальная разработка фронтенда

```bash
cd frontend
npm install
npm start
```

## Примечания

- Все пароли и секреты в docker-compose.yaml должны быть изменены в production
- ClickHouse данные хранятся в `./clickhouse-data`
- Airflow логи хранятся в `./Task2/airflow/logs`
- Для production необходимо настроить HTTPS и использовать реальные сертификаты

