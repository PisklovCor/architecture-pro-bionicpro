# Решение задач задания 1

## Задача 1: Архитектурное решение

См. файл `ARCHITECTURE.md` для детального описания архитектуры.

### Ключевые компоненты:
- **bionicpro-auth**: Бэкенд-сервис для управления аутентификацией и сессиями
- **Keycloak**: Identity Provider с поддержкой LDAP, Identity Brokering, MFA
- **LDAP**: Хранилище учётных данных для представительств
- **Redis**: Кеш для токенов и сессий

## Задача 2: PKCE вместо Code Grant

### Изменения в Keycloak:
- Включён PKCE для публичного клиента `reports-frontend`
- Обновлена конфигурация клиента в `realm-export.json`

### Изменения во фронтенде:
- Использование PKCE flow вместо Authorization Code flow
- Генерация code_verifier и code_challenge

## Задача 3: Безопасное хранение токенов

### Реализовано в bionicpro-auth:
1. **Получение токенов**: Интеграция с Keycloak через PKCE
2. **Хранение**: Redis с шифрованием для refresh_token
3. **Сессии**: HTTP-only Secure cookies
4. **Обновление токенов**: Автоматическое обновление через refresh_token
5. **Ротация сессий**: Новая session ID при каждом запросе

### Конфигурация:
- Access token TTL: 2 минуты
- Refresh token: зашифрован в Redis
- Session TTL: больше access token TTL

## Задача 4: LDAP интеграция

### Реализовано:
1. **OpenLDAP**: Развёрнут через docker-compose
2. **Keycloak LDAP Provider**: Настроен для синхронизации пользователей
3. **Маппинг ролей**: Синхронизация ролей из LDAP групп в Keycloak

### Конфигурация:
- LDAP сервер: `ldap://openldap:389`
- Base DN: `dc=example,dc=com`
- Маппинг групп: `cn=user` → `user`, `cn=prothetic_user` → `prothetic_user`

## Задача 5: MFA

### Реализовано:
1. **OTP Authenticator**: Настроен в Keycloak
2. **Обязательный MFA**: Включён для всех пользователей
3. **Поддержка**: Google Authenticator и FreeOTP

### Настройки:
- Тип: Time-based OTP (TOTP)
- Алгоритм: SHA1
- Период: 30 секунд
- Цифр: 6

## Задача 6: OAuth 2.0 от Яндекс ID

### Реализовано:
1. **Identity Brokering**: Настроен в Keycloak
2. **Яндекс ID Provider**: Добавлен как внешний IdP
3. **Consent Screen**: Запрос разрешения на использование данных
4. **Профиль пользователя**: Сохранение данных из Яндекса

### Настройки:
- Client ID: Настраивается через переменные окружения
- Client Secret: Настраивается через переменные окружения
- Scopes: `openid`, `profile`, `email`

