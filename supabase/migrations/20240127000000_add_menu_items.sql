-- Menü kategorileri için enum oluştur
DO $$ BEGIN
    CREATE TYPE menu_category AS ENUM ('food', 'drink');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Menü öğeleri tablosunu oluştur
CREATE TABLE IF NOT EXISTS menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category menu_category NOT NULL,
    image_url TEXT,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- RLS politikaları
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;

-- Mevcut politikaları temizle
DROP POLICY IF EXISTS "Menü öğelerini herkes görüntüleyebilir" ON menu_items;
DROP POLICY IF EXISTS "Menü öğesi düzenleme politikası" ON menu_items;
DROP POLICY IF EXISTS "Restoran sahipleri menü yönetimi" ON menu_items;
DROP POLICY IF EXISTS "Admin menü yönetimi" ON menu_items;
DROP POLICY IF EXISTS "Menü öğesi yönetimi" ON menu_items;
DROP POLICY IF EXISTS "Menü öğesi ekleme politikası" ON menu_items;
DROP POLICY IF EXISTS "Menü öğesi güncelleme politikası" ON menu_items;
DROP POLICY IF EXISTS "Menü öğesi silme politikası" ON menu_items;

-- Herkes menü öğelerini görüntüleyebilir
CREATE POLICY "Menü öğelerini herkes görüntüleyebilir" ON menu_items
    FOR SELECT
    USING (true);

-- Menü öğesi ekleme politikası
CREATE POLICY "Menü öğesi ekleme politikası" ON menu_items
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND (
                users.user_type = 'admin'
                OR (
                    users.user_type = 'restaurant'
                    AND users.restaurant_id = restaurant_id
                )
            )
        )
    );

-- Menü öğesi güncelleme politikası
CREATE POLICY "Menü öğesi güncelleme politikası" ON menu_items
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND (
                users.user_type = 'admin'
                OR (
                    users.user_type = 'restaurant'
                    AND users.restaurant_id = menu_items.restaurant_id
                )
            )
        )
    );

-- Menü öğesi silme politikası
CREATE POLICY "Menü öğesi silme politikası" ON menu_items
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND (
                users.user_type = 'admin'
                OR (
                    users.user_type = 'restaurant'
                    AND users.restaurant_id = menu_items.restaurant_id
                )
            )
        )
    );

-- Index'ler
CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant ON menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category); 