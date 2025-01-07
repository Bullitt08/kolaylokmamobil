-- Restoranlar tablosundan categories sütununu kaldır
ALTER TABLE restaurants
DROP COLUMN IF EXISTS categories; 