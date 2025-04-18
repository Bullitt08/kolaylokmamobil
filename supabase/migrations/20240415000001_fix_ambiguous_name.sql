-- Fix ambiguous name column reference in restaurant photos policy
DROP POLICY IF EXISTS "Restaurant owners can upload photos" ON storage.objects;

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
            OR (u.user_type = 'restaurant' AND r.id = (storage.foldername(objects.name))[2])
        )
    )
);

-- Fix ambiguous name column reference in restaurant photos delete policy
DROP POLICY IF EXISTS "Owners can delete their restaurant photos" ON storage.objects;

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
            OR (u.user_type = 'restaurant' AND r.id = (storage.foldername(objects.name))[2])
        )
    )
);
