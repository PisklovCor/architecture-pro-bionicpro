-- Инициализация CRM базы данных

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS prostheses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    model VARCHAR(100) NOT NULL,
    manufacture_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание индексов
CREATE INDEX IF NOT EXISTS idx_prostheses_user_id ON prostheses(user_id);
CREATE INDEX IF NOT EXISTS idx_prostheses_created_at ON prostheses(created_at);
CREATE INDEX IF NOT EXISTS idx_prostheses_updated_at ON prostheses(updated_at);

-- Вставка тестовых данных
INSERT INTO users (id, email, name) VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'user1@example.com', 'Иван Иванов'),
    ('550e8400-e29b-41d4-a716-446655440001', 'user2@example.com', 'Петр Петров'),
    ('550e8400-e29b-41d4-a716-446655440002', 'user3@example.com', 'Мария Сидорова')
ON CONFLICT (email) DO NOTHING;

INSERT INTO prostheses (id, user_id, model, manufacture_date) VALUES
    ('660e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440000', 'BionicPRO-2024', '2024-01-15'),
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'BionicPRO-2024', '2024-02-20'),
    ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'BionicPRO-2023', '2023-12-10')
ON CONFLICT (id) DO NOTHING;

