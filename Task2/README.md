# Задание 2: Разработка сервиса отчётов

## Описание

Реализован сервис отчётов для системы BionicPRO, который позволяет пользователям получать данные о работе своих протезов в виде отчётов.

## Структура решения

### Документация

- **ARCHITECTURE.md** - Архитектурная документация решения
- **IMPLEMENTATION.md** - Описание реализации компонентов
- **SETUP.md** - Инструкция по настройке и запуску
- **CHECKLIST.md** - Чеклист для проверки перед отправкой задания
- **README.md** - Этот файл

### Код

- **airflow/dags/prosthesis_reports_etl.py** - Airflow DAG для ETL процесса
- **db-init/** - SQL скрипты для инициализации баз данных:
  - `crm-init.sql` - Инициализация CRM базы данных
  - `telemetry-init.sql` - Инициализация базы телеметрии
  - `clickhouse-init.sql` - Инициализация ClickHouse

### Сервисы

- **bionicpro-reports/** - Java Spring Boot сервис для API отчётов
- Обновлён **docker-compose.yaml** - добавлены все необходимые сервисы
- Обновлён **frontend/src/components/ReportPage.tsx** - UI для получения отчётов

## Компоненты системы

1. **ETL-процесс (Apache Airflow)**
   - Извлечение данных из CRM и телеметрии
   - Агрегация данных по пользователям
   - Загрузка в витрину ClickHouse
   - Расписание: ежедневно в 02:00 UTC

2. **Витрина данных (ClickHouse)**
   - Таблица `user_prosthesis_reports`
   - Оптимизирована для быстрого доступа
   - Партиционирование по месяцам

3. **API сервис (bionicpro-reports)**
   - Эндпоинт `GET /api/reports`
   - Авторизация через JWT токен
   - Ограничение доступа (только свой отчёт)
   - Валидация периода данных

4. **Frontend**
   - Кнопка для получения отчёта
   - Автоматическая авторизация
   - Скачивание отчёта в формате JSON

## Быстрый старт

1. Запустить все сервисы:
   ```bash
   docker-compose up -d
   ```

2. Настроить подключения в Airflow (см. SETUP.md)

3. Запустить DAG в Airflow UI (http://localhost:8082)

4. Открыть Frontend (http://localhost:3000) и получить отчёт

Подробные инструкции см. в **SETUP.md**

## Проверка перед отправкой

Используйте **CHECKLIST.md** для проверки всех требований задания.

## Основные файлы для проверки

- Архитектура: `Task2/ARCHITECTURE.md`
- DAG: `Task2/airflow/dags/prosthesis_reports_etl.py`
- API сервис: `bionicpro-reports/src/main/java/com/bionicpro/reports/`
- UI: `frontend/src/components/ReportPage.tsx`
- Docker Compose: `docker-compose.yaml`

