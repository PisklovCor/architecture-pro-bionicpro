# Список изменений

## Новые компоненты

### 1. bionicpro-auth сервис
Новый Spring Boot сервис для управления аутентификацией:
- Интеграция с Keycloak через PKCE
- Управление сессиями через Redis
- Шифрование refresh_token
- Ротация сессий
- HTTP-only Secure cookies

### 2. Redis
Добавлен Redis для хранения сессий и токенов

### 3. OpenLDAP
Добавлен LDAP сервер для хранения пользователей представительств

## Изменения в существующих компонентах

### Keycloak (keycloak/realm-export.json)
- ✅ Настроен PKCE для клиента reports-frontend
- ✅ Добавлен клиент bionicpro-auth
- ✅ Настроен access token TTL: 120 секунд
- ✅ Настроен обязательный MFA (OTP)
- ✅ Добавлена конфигурация для Яндекс ID Identity Provider
- ✅ Настроены authentication flows с OTP

### Frontend
- ✅ Удалена прямая интеграция с Keycloak
- ✅ Реализован PKCE flow
- ✅ Интеграция с bionicpro-auth сервисом
- ✅ Использование HTTP-only cookies для сессий
- ✅ Удалены зависимости от @react-keycloak/web и keycloak-js

### Docker Compose
- ✅ Добавлен сервис redis
- ✅ Добавлен сервис openldap
- ✅ Добавлен сервис bionicpro-auth
- ✅ Настроена сеть bionicpro-network

## Новые файлы

### Документация
- `Task1/README.md` - Главный README
- `Task1/ARCHITECTURE.md` - Архитектурное решение
- `Task1/TASK1_SOLUTION.md` - Описание решения задач
- `Task1/KEYCLOAK_SETUP.md` - Инструкция по настройке Keycloak
- `Task1/SETUP_INSTRUCTIONS.md` - Инструкция по запуску
- `Task1/CHANGES.md` - Этот файл

### Скрипты
- `keycloak/setup-ldap.sh` - Скрипт настройки LDAP
- `keycloak/setup-yandex-id.sh` - Скрипт настройки Яндекс ID

### Код
- `bionicpro-auth/` - Весь код нового сервиса
- `frontend/src/utils/pkce.ts` - Утилиты для PKCE
- `frontend/src/context/AuthContext.tsx` - Контекст аутентификации

## Безопасность

### Улучшения
1. **Токены не передаются фронтенду** - все токены хранятся только на бэкенде
2. **HTTP-only cookies** - защита от XSS атак
3. **PKCE** - защита authorization code flow
4. **MFA обязателен** - двухфакторная аутентификация для всех
5. **Ротация сессий** - защита от session fixation
6. **Шифрование refresh_token** - дополнительная защита чувствительных данных
7. **Короткий TTL access_token** - минимизация риска при компрометации

### Конфигурация безопасности
- Access token TTL: 2 минуты
- Session TTL: 2 часа
- Refresh token: зашифрован в Redis
- Cookies: HTTP-only, Secure (в продакшене)

## Миграция

### Для разработчиков
1. Обновите зависимости фронтенда: `npm install`
2. Используйте новый AuthContext вместо useKeycloak
3. Все запросы к API должны включать credentials: 'include'

### Для администраторов
1. Запустите docker-compose up
2. Выполните скрипты настройки LDAP и Яндекс ID
3. Настройте OTP для каждого пользователя
4. Измените все секреты и ключи шифрования

## Известные ограничения

1. **MFA настройка**: Требуется ручная настройка OTP для каждого пользователя через Keycloak Admin Console
2. **Яндекс ID**: Требуется регистрация приложения на oauth.yandex.ru
3. **HTTPS**: В текущей конфигурации используется HTTP (для продакшена необходимо настроить HTTPS)

