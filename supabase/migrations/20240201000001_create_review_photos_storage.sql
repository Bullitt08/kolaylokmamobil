-- Create review-photos storage bucket
DO $$ 
BEGIN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('review-photos', 'review-photos', true);
EXCEPTION 
    WHEN unique_violation THEN 
        -- Bucket already exists, ignore
        NULL;
END $$;

-- Allow authenticated users to upload review photos
CREATE POLICY "Users can upload review photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'review-photos'
    AND (storage.foldername(name))[1] = 'review-photos'
);

-- Allow anyone to view review photos
CREATE POLICY "Review photos are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'review-photos');

-- Allow users to delete their own review photos
CREATE POLICY "Users can delete their own review photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'review-photos'
    AND auth.uid()::text = (storage.foldername(name))[2]
);

-- Allow admins to delete any review photos
CREATE POLICY "Admins can delete any review photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'review-photos'
    AND EXISTS (
        SELECT 1 FROM auth.users au
        JOIN public.users pu ON au.id = pu.id
        WHERE au.id = auth.uid()
        AND pu.user_type = 'admin'
    )
);