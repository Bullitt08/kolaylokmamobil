-- Kullanıcı tipleri için enum oluştur
DO $$ BEGIN
    CREATE TYPE user_type AS ENUM ('normal', 'restaurant', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Restoranlar tablosunu oluştur (owner_id olmadan)
CREATE TABLE IF NOT EXISTS restaurants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    address TEXT NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    logo_url TEXT,
    cover_photo_url TEXT,
    rating DECIMAL(2,1) DEFAULT 0.0,
    total_ratings INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    working_hours JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Users tablosunu güncelle
DO $$ BEGIN
    ALTER TABLE users ADD COLUMN user_type user_type NOT NULL DEFAULT 'normal';
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE users ADD COLUMN restaurant_id uuid REFERENCES restaurants(id);
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE users ADD COLUMN favorites UUID[] DEFAULT ARRAY[]::UUID[];
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Şimdi owner_id kolonunu ekle
DO $$ BEGIN
    ALTER TABLE restaurants ADD COLUMN owner_id UUID REFERENCES users(id) ON DELETE SET NULL;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- RLS (Row Level Security) politikaları
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;

-- Herkes restoranları görüntüleyebilir
DO $$ BEGIN
    CREATE POLICY "Restoranları herkes görüntüleyebilir" ON restaurants
        FOR SELECT
        USING (true);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Sadece admin ve restoran sahibi düzenleyebilir
DO $$ BEGIN
    CREATE POLICY "Restoran düzenleme politikası" ON restaurants
        FOR ALL
        USING (
            EXISTS (
                SELECT 1 FROM users
                WHERE users.id = auth.uid() AND (
                    users.user_type = 'admin' OR 
                    (users.user_type = 'restaurant' AND users.restaurant_id = restaurants.id)
                )
            )
        );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Trigger fonksiyonu: Restoran hesabı oluşturulduğunda restaurant_id güncelleme
CREATE OR REPLACE FUNCTION update_restaurant_user()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_type = 'restaurant' THEN
        UPDATE users
        SET restaurant_id = NEW.id
        WHERE id = NEW.owner_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı oluştur (eğer yoksa)
DO $$ BEGIN
    CREATE TRIGGER update_restaurant_user_trigger
    AFTER INSERT ON restaurants
    FOR EACH ROW
    EXECUTE FUNCTION update_restaurant_user();
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Index'ler (en son oluşturulacak)
DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_restaurants_owner ON restaurants(owner_id);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_users_restaurant ON users(restaurant_id);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE INDEX IF NOT EXISTS idx_users_type ON users(user_type);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$; 