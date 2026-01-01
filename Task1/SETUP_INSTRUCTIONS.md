# Инструкция по запуску системы

## Предварительные требования

- Docker и Docker Compose
- Java 17+ (для локальной разработки bionicpro-auth)
- Maven 3.6+ (для локальной разработки bionicpro-auth)
- Node.js 16+ и npm (для локальной разработки фронтенда)

## Запуск через Docker Compose

### 1. Клонирование и подготовка

```bash
# Перейдите в директорию проекта
cd architecture-pro-bionicpro

# Убедитесь, что все файлы на месте
ls -la
```

### 2. Настройка переменных окружения (опционально)

Создайте файл `.env` в корне проекта (опционально):

```env
ENCRYPTION_KEY=your-secure-encryption-key-here
YANDEX_CLIENT_ID=your-yandex-client-id
YANDEX_CLIENT_SECRET=your-yandex-client-secret
```

### 3. Запуск всех сервисов

```bash
docker-compose up -d
```

Это запустит:
- PostgreSQL для Keycloak
- Keycloak (порт 8080)
- Redis (порт 6379)
- OpenLDAP (порт 389)
- bionicpro-auth (порт 8081)
- Frontend (порт 3000)

### 4. Ожидание готовности сервисов

Подождите 30-60 секунд, пока все сервисы запустятся. Проверьте логи:

```bash
docker-compose logs -f
```

### 5. Настройка Keycloak

#### 5.1. Настройка LDAP

После запуска Keycloak выполните:

```bash
# Сделайте скрипт исполняемым
chmod +x keycloak/setup-ldap.sh

# Запустите скрипт настройки LDAP
./keycloak/setup-ldap.sh
```

Затем:
1. Откройте Keycloak Admin Console: http://localhost:8080
2. Войдите: admin / admin
3. Перейдите в Realm Settings → User Federation
4. Найдите "openldap" и нажмите "Synchronize all users"

#### 5.2. Настройка MFA

MFA уже настроен в конфигурации. Для каждого пользователя:

1. Зайдите в Users → выберите пользователя
2. Перейдите на вкладку "Credentials"
3. Нажмите "Set up OTP"
4. Отсканируйте QR-код в Google Authenticator или FreeOTP

#### 5.3. Настройка Яндекс ID (опционально)

Если у вас есть Client ID и Secret от Яндекс ID:

```bash
export YANDEX_CLIENT_ID="your-client-id"
export YANDEX_CLIENT_SECRET="your-client-secret"
chmod +x keycloak/setup-yandex-id.sh
./keycloak/setup-yandex-id.sh
```

Или настройте вручную через Admin Console (см. `KEYCLOAK_SETUP.md`).

### 6. Проверка работы

1. Откройте фронтенд: http://localhost:3000
2. Нажмите "Login"
3. Войдите через Keycloak (используйте пользователя из LDAP или локального)
4. После ввода OTP вы должны быть авторизованы

## Локальная разработка

### Запуск bionicpro-auth локально

```bash
cd bionicpro-auth
mvn clean install
mvn spring-boot:run
```

Убедитесь, что Redis запущен:
```bash
docker run -d -p 6379:6379 redis:7-alpine
```

### Запуск фронтенда локально

```bash
cd frontend
npm install
npm start
```

## Тестирование

### Проверка health endpoints

```bash
# Проверка bionicpro-auth
curl http://localhost:8081/api/health

# Проверка Keycloak
curl http://localhost:8080/health
```

### Тестирование аутентификации

1. Откройте http://localhost:3000
2. Нажмите "Login"
3. Введите credentials пользователя из LDAP:
   - Username: `john.doe` или `jane.smith` или `alex.johnson`
   - Password: `password`
4. Введите OTP из приложения-аутентификатора
5. После успешной авторизации вы должны увидеть страницу с кнопкой "Download Report"

### Проверка сессий

```bash
# Проверка сессии (должен вернуть 401 без cookie)
curl http://localhost:8081/api/auth/session

# После авторизации через браузер, cookie будет установлена автоматически
```

## Остановка сервисов

```bash
docker-compose down
```

Для полной очистки данных:

```bash
docker-compose down -v
```

## Устранение проблем

### Keycloak не запускается

1. Проверьте логи: `docker-compose logs keycloak`
2. Убедитесь, что PostgreSQL запущен: `docker-compose ps keycloak_db`
3. Проверьте, что порт 8080 свободен

### LDAP не синхронизируется

1. Проверьте подключение к LDAP: `docker-compose logs openldap`
2. Убедитесь, что скрипт setup-ldap.sh выполнен успешно
3. Проверьте настройки в Keycloak Admin Console

### bionicpro-auth не может подключиться к Redis

1. Проверьте, что Redis запущен: `docker-compose ps redis`
2. Проверьте логи: `docker-compose logs bionicpro-auth`
3. Убедитесь, что переменные окружения установлены правильно

### Фронтенд не может подключиться к auth-сервису

1. Проверьте переменные окружения в docker-compose.yaml
2. Убедитесь, что bionicpro-auth запущен: `docker-compose ps bionicpro-auth`
3. Проверьте CORS настройки в SecurityConfig

## Пользователи для тестирования

### LDAP пользователи:
- `john.doe` / `password` (роль: prothetic_user)
- `jane.smith` / `password` (роль: user)
- `alex.johnson` / `password` (роль: prothetic_user)

### Локальные пользователи Keycloak:
- `user1` / `password123` (роль: user)
- `admin1` / `admin123` (роль: administrator)
- `prothetic1` / `prothetic123` (роль: prothetic_user)

**Важно**: Для всех пользователей необходимо настроить OTP через Keycloak Admin Console.

