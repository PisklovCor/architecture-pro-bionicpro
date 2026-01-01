#!/bin/bash

# Скрипт для настройки и регистрации Debezium connector
# Использование: ./setup-debezium.sh

DEBEZIUM_URL="http://localhost:8084"
CONNECTOR_NAME="crm-postgres-connector"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONNECTOR_CONFIG="${SCRIPT_DIR}/debezium/connectors/crm-connector.json"

echo "Проверка доступности Debezium Connect..."
until curl -s -f "${DEBEZIUM_URL}/connectors" > /dev/null; do
    echo "Ожидание запуска Debezium Connect..."
    sleep 5
done

echo "Debezium Connect доступен!"

# Проверка существования коннектора
EXISTING=$(curl -s "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}")

if [ "$EXISTING" != "null" ] && [ -n "$EXISTING" ]; then
    echo "Коннектор ${CONNECTOR_NAME} уже существует. Удаление старого коннектора..."
    curl -X DELETE "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}"
    sleep 2
fi

echo "Регистрация нового коннектора ${CONNECTOR_NAME}..."
RESPONSE=$(curl -s -X POST "${DEBEZIUM_URL}/connectors" \
    -H "Content-Type: application/json" \
    -d @${CONNECTOR_CONFIG})

if echo "$RESPONSE" | grep -q "error"; then
    echo "Ошибка при регистрации коннектора:"
    echo "$RESPONSE"
    exit 1
fi

echo "Коннектор успешно зарегистрирован!"

# Проверка статуса
sleep 3
echo "Проверка статуса коннектора..."
STATUS=$(curl -s "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}/status" | jq -r '.connector.state')

if [ "$STATUS" = "RUNNING" ]; then
    echo "✓ Коннектор работает (RUNNING)"
else
    echo "⚠ Статус коннектора: $STATUS"
    echo "Детали:"
    curl -s "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}/status" | jq '.'
fi

echo ""
echo "Проверка топиков Kafka..."
echo "Должны появиться топики:"
echo "  - crm_db.public.users"
echo "  - crm_db.public.prostheses"

