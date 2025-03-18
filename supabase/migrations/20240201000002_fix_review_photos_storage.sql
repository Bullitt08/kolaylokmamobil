-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can upload review photos" ON storage.objects;
DROP POLICY IF EXISTS "Review photos are publicly viewable" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own review photos" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete any review photos" ON storage.objects;

-- Create the bucket if it doesn't exist
DO $$
BEGIN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('review-photos', 'review-photos', true)
    ON CONFLICT (id) DO NOTHING;
END
$$;

-- Allow authenticated users to upload review photos
CREATE POLICY "Users can upload review photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'review-photos'
);

-- Allow anyone to view review photos
CREATE POLICY "Review photos are publicly viewable"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'review-photos');

-- Allow users to delete their own review photos
CREATE POLICY "Users can delete their own review photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'review-photos' AND
    (auth.uid() = ANY (SELECT user_id FROM reviews WHERE photos @> ARRAY[storage.foldername(name)]) OR
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid() AND user_type = 'admin'
    ))
);