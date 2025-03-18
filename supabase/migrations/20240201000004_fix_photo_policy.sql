-- Drop existing policy
DROP POLICY IF EXISTS "Users can delete their own review photos" ON storage.objects;

-- Create updated policy for photo deletion
CREATE POLICY "Users can delete their own review photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'review-photos' AND
    (
        auth.uid() = ANY (
            SELECT user_id 
            FROM reviews 
            WHERE photos && ARRAY[name]
        )
        OR EXISTS (
            SELECT 1 
            FROM users
            WHERE id = auth.uid() 
            AND user_type = 'admin'
        )
    )
);