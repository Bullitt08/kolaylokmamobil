-- Önce index'i kaldır
DROP INDEX IF EXISTS idx_restaurants_average_price;

-- average_price sütununu kaldır
ALTER TABLE restaurants
DROP COLUMN IF EXISTS average_price; 