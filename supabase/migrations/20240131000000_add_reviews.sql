-- Reviews tablosunu oluştur
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    photos TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Review raporlarını oluştur
CREATE TABLE IF NOT EXISTS review_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID REFERENCES reviews(id) ON DELETE CASCADE,
    reporter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin bildirimlerini oluştur
CREATE TABLE IF NOT EXISTS admin_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type TEXT NOT NULL,
    content JSONB NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS politikaları
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;

-- Reviews için RLS politikaları
CREATE POLICY "Herkes yorumları görebilir" ON reviews
    FOR SELECT USING (true);

CREATE POLICY "Kullanıcılar yorum ekleyebilir" ON reviews
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi yorumlarını düzenleyebilir" ON reviews
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi yorumlarını silebilir" ON reviews
    FOR DELETE
    USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.user_type = 'admin'
    ));

-- Review reports için RLS politikaları
CREATE POLICY "Kullanıcılar rapor oluşturabilir" ON review_reports
    FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Adminler raporları görebilir" ON review_reports
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.user_type = 'admin'
    ));

-- Admin notifications için RLS politikaları
CREATE POLICY "Sadece adminler bildirimleri görebilir" ON admin_notifications
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.user_type = 'admin'
    ));

-- Trigger fonksiyonu - yorum puanını restoran puanına yansıt
CREATE OR REPLACE FUNCTION update_restaurant_rating()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE restaurants
        SET rating = (
            SELECT ROUND(AVG(rating)::numeric, 1)
            FROM reviews
            WHERE restaurant_id = NEW.restaurant_id
        ),
        rating_count = (
            SELECT COUNT(*)
            FROM reviews
            WHERE restaurant_id = NEW.restaurant_id
        )
        WHERE id = NEW.restaurant_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE restaurants
        SET rating = COALESCE((
            SELECT ROUND(AVG(rating)::numeric, 1)
            FROM reviews
            WHERE restaurant_id = OLD.restaurant_id
        ), 0),
        rating_count = (
            SELECT COUNT(*)
            FROM reviews
            WHERE restaurant_id = OLD.restaurant_id
        )
        WHERE id = OLD.restaurant_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ları oluştur
CREATE TRIGGER after_review_change
    AFTER INSERT OR DELETE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_restaurant_rating();

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_reviews_restaurant ON reviews(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_review_reports_review ON review_reports(review_id);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_type ON admin_notifications(type);