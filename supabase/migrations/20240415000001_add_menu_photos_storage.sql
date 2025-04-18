-- Create menu-photos storage bucket
DO $$ 
BEGIN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('menu-photos', 'menu-photos', true);
EXCEPTION 
    WHEN unique_violation THEN 
        NULL;
END $$;

-- Allow restaurant owners and admins to upload menu photos
CREATE POLICY "Restaurant owners can upload menu photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'menu-photos'
    AND EXISTS (
        SELECT 1 FROM menu_items mi
        JOIN restaurants r ON mi.restaurant_id = r.id
        JOIN users u ON r.owner_id = u.id
        WHERE u.id = auth.uid()
        AND (
            u.user_type = 'admin'
            OR (u.user_type = 'restaurant' AND mi.restaurant_id::text = (storage.foldername(objects.name))[2])
        )
    )
);

-- Allow anyone to view menu photos
CREATE POLICY "Menu photos are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'menu-photos');

-- Allow owners to delete their menu photos
CREATE POLICY "Owners can delete their menu photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'menu-photos'
    AND EXISTS (
        SELECT 1 FROM menu_items mi
        JOIN restaurants r ON mi.restaurant_id = r.id
        JOIN users u ON r.owner_id = u.id
        WHERE u.id = auth.uid()
        AND (
            u.user_type = 'admin'
            OR (u.user_type = 'restaurant' AND mi.restaurant_id::text = (storage.foldername(objects.name))[2])
        )
    )
);
