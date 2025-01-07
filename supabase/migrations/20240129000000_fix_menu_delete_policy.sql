-- Mevcut silme politikasını kaldır
DROP POLICY IF EXISTS "Menü öğesi silme politikası" ON menu_items;

-- Yeni silme politikası ekle
CREATE POLICY "Menü öğesi silme politikası" ON menu_items
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users u
            JOIN restaurants r ON r.owner_id = u.id
            WHERE u.id = auth.uid()
            AND (
                u.user_type = 'admin'
                OR (
                    u.user_type = 'restaurant'
                    AND r.id = menu_items.restaurant_id
                )
            )
        )
    ); 