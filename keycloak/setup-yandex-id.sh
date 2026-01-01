#!/bin/bash

# Скрипт для настройки Яндекс ID в Keycloak
# Требует переменные окружения YANDEX_CLIENT_ID и YANDEX_CLIENT_SECRET

KEYCLOAK_URL="http://localhost:8080"
REALM="reports-realm"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

if [ -z "$YANDEX_CLIENT_ID" ] || [ -z "$YANDEX_CLIENT_SECRET" ]; then
  echo "Error: YANDEX_CLIENT_ID and YANDEX_CLIENT_SECRET must be set"
  exit 1
fi

# Получаем access token администратора
TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "Failed to get admin token"
  exit 1
fi

# Создаём Identity Provider для Яндекс ID
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/identity-provider/instances" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"alias\": \"yandex\",
    \"providerId\": \"oidc\",
    \"enabled\": true,
    \"updateProfileFirstLoginMode\": \"on\",
    \"trustEmail\": false,
    \"storeToken\": false,
    \"addReadTokenRoleOnCreate\": false,
    \"authenticateByDefault\": false,
    \"linkOnly\": false,
    \"firstBrokerLoginFlowAlias\": \"first broker login\",
    \"config\": {
      \"clientId\": \"${YANDEX_CLIENT_ID}\",
      \"clientSecret\": \"${YANDEX_CLIENT_SECRET}\",
      \"authorizationUrl\": \"https://oauth.yandex.ru/authorize\",
      \"tokenUrl\": \"https://oauth.yandex.ru/token\",
      \"userInfoUrl\": \"https://login.yandex.ru/info\",
      \"issuer\": \"https://oauth.yandex.ru\",
      \"defaultScope\": \"openid profile email\",
      \"useJwksUrl\": \"true\",
      \"jwksUrl\": \"https://oauth.yandex.ru/.well-known/jwks.json\",
      \"validateSignature\": \"true\",
      \"backchannelSupported\": \"false\"
    }
  }"

echo ""
echo "Yandex ID Identity Provider configured"

