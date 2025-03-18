-- Create function to delete photos from storage
CREATE OR REPLACE FUNCTION delete_review_photos()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete photos from storage
    IF OLD.photos IS NOT NULL AND array_length(OLD.photos, 1) > 0 THEN
        PERFORM net.http_post(
            url := current_setting('app.settings.supabase_url') || '/storage/v1/object/review-photos/' || photo_name,
            headers := jsonb_build_object(
                'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
                'Content-Type', 'application/json'
            )
        ) 
        FROM unnest(OLD.photos) AS photo_name;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS before_review_delete ON reviews;
CREATE TRIGGER before_review_delete
    BEFORE DELETE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION delete_review_photos();