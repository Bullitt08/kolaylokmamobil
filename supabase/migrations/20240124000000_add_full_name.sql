-- Users tablosuna name ve surname kolonlarını ekle
DO $$ BEGIN
    ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(100);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS surname VARCHAR(100);
EXCEPTION
    WHEN duplicate_column THEN null;
END $$; 