-- Инициализация базы данных телеметрии

CREATE TABLE IF NOT EXISTS telemetry_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prosthesis_id UUID NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    sensor_data JSONB,
    actuator_commands JSONB,
    battery_level FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание индексов для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_telemetry_prosthesis_id ON telemetry_data(prosthesis_id);
CREATE INDEX IF NOT EXISTS idx_telemetry_timestamp ON telemetry_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_telemetry_prosthesis_timestamp ON telemetry_data(prosthesis_id, timestamp);

-- Вставка тестовых данных за последние 7 дней
DO $$
DECLARE
    prosthesis_ids UUID[] := ARRAY[
        '660e8400-e29b-41d4-a716-446655440000',
        '660e8400-e29b-41d4-a716-446655440001',
        '660e8400-e29b-41d4-a716-446655440002'
    ];
    prosthesis_id UUID;
    i INTEGER;
    current_time TIMESTAMP;
BEGIN
    FOR i IN 1..array_length(prosthesis_ids, 1) LOOP
        prosthesis_id := prosthesis_ids[i];
        
        -- Генерируем данные за последние 7 дней
        FOR current_time IN 
            SELECT generate_series(
                CURRENT_TIMESTAMP - INTERVAL '7 days',
                CURRENT_TIMESTAMP,
                INTERVAL '1 hour'
            )::TIMESTAMP
        LOOP
            -- Вставляем запись с вероятностью 30% (чтобы не было слишком много данных)
            IF random() < 0.3 THEN
                INSERT INTO telemetry_data (
                    prosthesis_id,
                    timestamp,
                    sensor_data,
                    actuator_commands,
                    battery_level
                ) VALUES (
                    prosthesis_id,
                    current_time,
                    jsonb_build_object(
                        'sensor1', (random() * 100)::INTEGER,
                        'sensor2', (random() * 100)::INTEGER,
                        'sensor3', (random() * 100)::INTEGER
                    ),
                    jsonb_build_object(
                        'command', CASE WHEN random() < 0.5 THEN 'grasp' ELSE 'release' END,
                        'intensity', (random() * 100)::INTEGER
                    ),
                    (random() * 100)::FLOAT
                );
            END IF;
        END LOOP;
    END LOOP;
END $$;

