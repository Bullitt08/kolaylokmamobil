-- Create restaurant-photos storage bucket
DO $$ 
BEGIN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('restaurant-photos', 'restaurant-photos', true);
EXCEPTION 
    WHEN unique_violation THEN 
        NULL;
END $$;

-- Allow restaurant owners and admins to upload restaurant photos
CREATE POLICY "Restaurant owners can upload photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'restaurant-photos'
    AND EXISTS (
        SELECT 1 FROM restaurants r
        JOIN users u ON r.owner_id = u.id
        WHERE u.id = auth.uid()
        AND (
            u.user_type = 'admin'
            OR (u.user_type = 'restaurant' AND r.id::text = (storage.foldername(objects.name))[2])
        )
    )
);

-- Allow anyone to view restaurant photos
CREATE POLICY "Restaurant photos are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'restaurant-photos');

-- Allow owners to delete their restaurant photos
CREATE POLICY "Owners can delete their restaurant photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'restaurant-photos'
    AND EXISTS (
        SELECT 1 FROM restaurants r
        JOIN users u ON r.owner_id = u.id
        WHERE u.id = auth.uid()
        AND (
            u.user_type = 'admin'
            OR (u.user_type = 'restaurant' AND r.id::text = (storage.foldername(objects.name))[2])
        )
    )
);
