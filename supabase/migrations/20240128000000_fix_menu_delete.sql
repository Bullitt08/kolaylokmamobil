-- Mevcut silme politikasını kaldır
DROP POLICY IF EXISTS "Menü öğesi silme politikası" ON menu_items;

-- Yeni silme politikası ekle
CREATE POLICY "Menü öğesi silme politikası" ON menu_items
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND (
                users.user_type = 'admin'
                OR (
                    users.user_type = 'restaurant'
                    AND users.restaurant_id = menu_items.restaurant_id
                )
            )
        )
    ); 