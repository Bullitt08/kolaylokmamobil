-- Add gin index for photos array and update column type
DROP INDEX IF EXISTS idx_reviews_photos;
ALTER TABLE reviews 
    ALTER COLUMN photos SET DEFAULT ARRAY[]::text[],
    ALTER COLUMN photos TYPE text[] USING CASE 
        WHEN photos IS NULL THEN ARRAY[]::text[] 
        ELSE photos 
    END;
CREATE INDEX idx_reviews_photos ON reviews USING gin(photos);

-- Add trigger to validate photo URLs
CREATE OR REPLACE FUNCTION validate_photo_urls()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure photos array contains valid URLs from our storage
    IF EXISTS (
        SELECT 1 
        FROM unnest(NEW.photos) AS photo_url 
        WHERE photo_url NOT LIKE '%/storage/v1/object/public/review-photos/%'
    ) THEN
        RAISE EXCEPTION 'Invalid photo URL found. All photos must be from review-photos bucket.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to validate photos before insert/update
DROP TRIGGER IF EXISTS validate_photos_trigger ON reviews;
CREATE TRIGGER validate_photos_trigger
    BEFORE INSERT OR UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION validate_photo_urls();