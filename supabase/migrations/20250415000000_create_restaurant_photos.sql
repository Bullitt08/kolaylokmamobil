-- Add user_type column to auth.users if it doesn't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'auth' 
        AND table_name = 'users' 
        AND column_name = 'user_type'
    ) THEN
        ALTER TABLE auth.users ADD COLUMN user_type TEXT DEFAULT 'user';
    END IF;
END $$;

-- Drop table if exists
DROP TABLE IF EXISTS restaurant_photos CASCADE;

-- Create restaurant_photos table
CREATE TABLE restaurant_photos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    active BOOLEAN DEFAULT true
);

-- Enable RLS
ALTER TABLE restaurant_photos ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Görüntüleme politikası" ON restaurant_photos;
DROP POLICY IF EXISTS "Ekleme politikası" ON restaurant_photos;
DROP POLICY IF EXISTS "Güncelleme politikası" ON restaurant_photos;
DROP POLICY IF EXISTS "Silme politikası" ON restaurant_photos;
DROP POLICY IF EXISTS "Admin silme politikası" ON restaurant_photos;

-- Create new policies
-- Allow anyone to view photos
CREATE POLICY "Görüntüleme politikası" ON restaurant_photos
    FOR SELECT USING (true);

-- Allow restaurant owners to insert photos
CREATE POLICY "Ekleme politikası" ON restaurant_photos
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM restaurants 
            WHERE id = restaurant_photos.restaurant_id 
            AND owner_id = auth.uid()
        )
    );

-- Allow restaurant owners to update photos
CREATE POLICY "Güncelleme politikası" ON restaurant_photos
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 
            FROM restaurants 
            WHERE id = restaurant_photos.restaurant_id 
            AND owner_id = auth.uid()
        )
    );

-- Allow restaurant owners to delete photos
CREATE POLICY "Silme politikası" ON restaurant_photos
    FOR DELETE USING (
        EXISTS (
            SELECT 1 
            FROM restaurants r
            WHERE r.id = restaurant_photos.restaurant_id 
            AND r.owner_id = auth.uid()
        )
    );

-- Create index for better performance
CREATE INDEX idx_restaurant_photos_restaurant_id ON restaurant_photos(restaurant_id);

-- First disable RLS for storage.objects
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Create or update storage bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('restaurant-photos', 'restaurant-photos', true)
ON CONFLICT (id) DO NOTHING;
