# Инструкция по настройке Keycloak

## Настройка LDAP

После запуска Keycloak выполните скрипт настройки LDAP:

```bash
chmod +x keycloak/setup-ldap.sh
./keycloak/setup-ldap.sh
```

После выполнения скрипта:
1. Зайдите в Keycloak Admin Console (http://localhost:8080)
2. Перейдите в Realm Settings → User Federation
3. Найдите созданный LDAP провайдер "openldap"
4. Нажмите "Synchronize all users" для синхронизации пользователей из LDAP

## Настройка MFA

MFA уже настроен в realm-export.json:
- OTP обязателен для всех пользователей
- Алгоритм: TOTP (Time-based OTP)
- Период: 30 секунд
- 6 цифр

Для каждого пользователя:
1. Зайдите в Users → выберите пользователя
2. Перейдите на вкладку "Credentials"
3. Нажмите "Set up OTP"
4. Отсканируйте QR-код в Google Authenticator или FreeOTP

## Настройка Яндекс ID

1. Зарегистрируйте приложение на https://oauth.yandex.ru/
2. Получите Client ID и Client Secret
3. Установите переменные окружения:
   ```bash
   export YANDEX_CLIENT_ID="your-client-id"
   export YANDEX_CLIENT_SECRET="your-client-secret"
   ```
4. Выполните скрипт:
   ```bash
   chmod +x keycloak/setup-yandex-id.sh
   ./keycloak/setup-yandex-id.sh
   ```

Или настройте вручную через Admin Console:
1. Identity Providers → Add provider → OpenID Connect v1.0
2. Alias: `yandex`
3. Authorization URL: `https://oauth.yandex.ru/authorize`
4. Token URL: `https://oauth.yandex.ru/token`
5. User Info URL: `https://login.yandex.ru/info`
6. Client ID и Client Secret из шага 2
7. Default Scopes: `openid profile email`

## Настройка PKCE

PKCE уже настроен для клиента `reports-frontend` в realm-export.json:
- Метод: S256 (SHA256)
- Включён для стандартного flow

## Настройка токенов

Настройки токенов в realm-export.json:
- Access Token Lifespan: 120 секунд (2 минуты)
- SSO Session Idle Timeout: 7200 секунд (2 часа)
- SSO Session Max Lifespan: 7200 секунд (2 часа)

