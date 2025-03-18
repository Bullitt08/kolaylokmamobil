-- Add photos column to reviews table
ALTER TABLE reviews 
ADD COLUMN IF NOT EXISTS photos TEXT[] DEFAULT ARRAY[]::TEXT[];

-- Create index for photos array
CREATE INDEX IF NOT EXISTS idx_reviews_photos ON reviews USING gin(photos);