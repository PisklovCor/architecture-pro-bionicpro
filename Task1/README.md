# Решение задания 1: Повышение безопасности системы

## Обзор

Это решение включает все 6 задач по повышению безопасности системы BionicPRO:
1. Архитектурное решение и C4 диаграмма
2. PKCE вместо Code Grant
3. Безопасное хранение токенов (bionicpro-auth сервис)
4. LDAP интеграция
5. MFA (Multi-Factor Authentication)
6. OAuth 2.0 от Яндекс ID

## Структура решения

```
Task1/
├── README.md                    # Этот файл
├── ARCHITECTURE.md              # Архитектурное решение
├── TASK1_SOLUTION.md           # Описание решения всех задач
├── KEYCLOAK_SETUP.md           # Инструкция по настройке Keycloak
└── SETUP_INSTRUCTIONS.md       # Подробная инструкция по запуску

bionicpro-auth/                  # Новый бэкенд-сервис аутентификации
├── src/
│   └── main/
│       ├── java/
│       │   └── com/bionicpro/auth/
│       │       ├── config/     # Конфигурация Spring
│       │       ├── controller/ # REST контроллеры
│       │       ├── model/      # Модели данных
│       │       ├── service/    # Бизнес-логика
│       │       └── util/       # Утилиты (шифрование)
│       └── resources/
│           └── application.yml # Конфигурация приложения
└── Dockerfile

keycloak/
├── realm-export.json            # Обновлённая конфигурация Keycloak
├── setup-ldap.sh               # Скрипт настройки LDAP
└── setup-yandex-id.sh         # Скрипт настройки Яндекс ID

frontend/                       # Обновлённый фронтенд
├── src/
│   ├── App.tsx                 # Обновлён для работы с bionicpro-auth
│   ├── components/
│   │   └── ReportPage.tsx      # Обновлён для работы с новым auth
│   ├── context/
│   │   └── AuthContext.tsx     # Новый контекст аутентификации
│   └── utils/
│       └── pkce.ts             # Утилиты для PKCE

docker-compose.yaml             # Обновлён с новыми сервисами
```

## Быстрый старт

1. **Запустите все сервисы:**
   ```bash
   docker-compose up -d
   ```

2. **Настройте LDAP в Keycloak:**
   ```bash
   chmod +x keycloak/setup-ldap.sh
   ./keycloak/setup-ldap.sh
   ```

3. **Откройте фронтенд:**
   http://localhost:3000

Подробные инструкции см. в [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)

## Реализованные функции

### ✅ Задача 1: Архитектурное решение
- Создана архитектура с централизованным auth-сервисом
- Документированы потоки аутентификации
- Описана безопасность токенов и сессий

### ✅ Задача 2: PKCE
- Реализован PKCE flow во фронтенде
- Настроен в Keycloak для клиента reports-frontend
- Используется S256 метод

### ✅ Задача 3: Безопасное хранение токенов
- Создан сервис bionicpro-auth на Spring Boot
- Токены хранятся в Redis (refresh_token зашифрован)
- HTTP-only Secure cookies для сессий
- Автоматическое обновление access_token
- Ротация сессий для предотвращения session fixation

### ✅ Задача 4: LDAP
- Развёрнут OpenLDAP через docker-compose
- Настроена интеграция с Keycloak
- Реализован маппинг ролей из LDAP групп

### ✅ Задача 5: MFA
- Настроен обязательный OTP для всех пользователей
- Поддержка Google Authenticator и FreeOTP
- TOTP с периодом 30 секунд

### ✅ Задача 6: Яндекс ID
- Настроен Identity Brokering в Keycloak
- Поддержка OAuth 2.0 от Яндекс ID
- Скрипт для автоматической настройки

## Технологии

- **Backend**: Spring Boot 3.2, Java 17
- **Frontend**: React 18, TypeScript
- **Auth**: Keycloak 21.1
- **Cache**: Redis 7
- **LDAP**: OpenLDAP
- **Database**: PostgreSQL 14

## Безопасность

- ✅ Токены не передаются фронтенду
- ✅ HTTP-only Secure cookies
- ✅ Шифрование refresh_token
- ✅ Ротация сессий
- ✅ PKCE для защиты authorization code
- ✅ MFA обязателен для всех
- ✅ Access token TTL: 2 минуты
- ✅ Session TTL: больше access token TTL

## Документация

- [ARCHITECTURE.md](ARCHITECTURE.md) - Архитектурное решение
- [TASK1_SOLUTION.md](TASK1_SOLUTION.md) - Детальное описание решения
- [KEYCLOAK_SETUP.md](KEYCLOAK_SETUP.md) - Настройка Keycloak
- [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) - Инструкция по запуску

## Тестирование

### Пользователи для тестирования

**LDAP:**
- `john.doe` / `password` (prothetic_user)
- `jane.smith` / `password` (user)
- `alex.johnson` / `password` (prothetic_user)

**Keycloak:**
- `user1` / `password123` (user)
- `admin1` / `admin123` (administrator)
- `prothetic1` / `prothetic123` (prothetic_user)

**Важно**: Для всех пользователей необходимо настроить OTP через Keycloak Admin Console.

## Порты

- **Frontend**: 3000
- **Keycloak**: 8080
- **bionicpro-auth**: 8081
- **Redis**: 6379
- **LDAP**: 389
- **PostgreSQL**: 5433

## Примечания

1. В продакшене необходимо:
   - Изменить все секреты и ключи шифрования
   - Включить HTTPS
   - Настроить Secure flag для cookies
   - Использовать переменные окружения для чувствительных данных

2. Для Яндекс ID требуется регистрация приложения на https://oauth.yandex.ru/

3. MFA настраивается индивидуально для каждого пользователя через Keycloak Admin Console

