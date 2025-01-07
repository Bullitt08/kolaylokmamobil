-- Önce mevcut tabloyu yedekleyelim
CREATE TABLE IF NOT EXISTS restaurants_backup AS SELECT * FROM restaurants;

-- Reviews tablosunu yedekleyelim
CREATE TABLE IF NOT EXISTS reviews_backup AS SELECT * FROM reviews;

-- Mevcut tabloyu ve bağımlılıkları düşürelim
DROP TABLE IF EXISTS restaurants CASCADE;

-- Yeni tabloyu oluşturalım
CREATE TABLE restaurants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    address TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    image_url TEXT DEFAULT '',
    location POINT NOT NULL,
    categories TEXT[] DEFAULT ARRAY[]::TEXT[],
    rating DOUBLE PRECISION DEFAULT 0.0,
    rating_count INTEGER DEFAULT 0,
    is_open BOOLEAN DEFAULT true,
    working_hours JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    owner_id UUID REFERENCES auth.users(id) NOT NULL
);

-- İlişkili tabloları yeniden oluşturalım
ALTER TABLE users 
    ADD CONSTRAINT users_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurants(id);

ALTER TABLE reviews 
    ADD CONSTRAINT reviews_restaurant_id_fkey 
    FOREIGN KEY (restaurant_id) 
    REFERENCES restaurants(id);

-- Yedekten verileri geri yükleyelim
INSERT INTO restaurants 
SELECT 
    id,
    name,
    description,
    address,
    phone_number,
    image_url,
    location,
    categories,
    rating,
    rating_count,
    is_open,
    working_hours,
    created_at,
    owner_id
FROM restaurants_backup;

-- Reviews verilerini geri yükleyelim
INSERT INTO reviews SELECT * FROM reviews_backup;

-- Yedek tabloları silelim
DROP TABLE IF EXISTS restaurants_backup;
DROP TABLE IF EXISTS reviews_backup; 