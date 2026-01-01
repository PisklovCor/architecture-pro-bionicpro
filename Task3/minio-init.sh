#!/bin/bash

# Скрипт инициализации Minio для настройки публичного доступа к bucket reports
# Этот скрипт должен быть запущен после старта Minio

echo "Waiting for Minio to be ready..."
sleep 10

# Настройка Minio Client
export MC_HOST_minio=http://minioadmin:minioadmin@localhost:9000

# Создание bucket, если не существует
mc mb minio/reports --ignore-existing || true

# Настройка публичного доступа на чтение для объектов в bucket reports
mc anonymous set download minio/reports || true

echo "Minio bucket 'reports' configured with public read access"

