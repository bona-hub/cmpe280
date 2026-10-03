-- =============================================
-- GYMCYCLOPEDIA PROGRESS TRACKING SCHEMA
-- =============================================

-- Progress Photos Table
CREATE TABLE IF NOT EXISTS progress_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  storage_path TEXT, -- Made optional for base64 storage
  date DATE NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('front', 'side', 'back', 'pose')),
  notes TEXT,
  file_name TEXT, -- Added for better file tracking
  file_size INTEGER, -- Added for file size tracking
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Body Measurements Table
CREATE TABLE IF NOT EXISTS body_measurements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  weight_lbs DECIMAL(5,2),
  body_fat_percentage DECIMAL(4,2),
  muscle_mass_lbs DECIMAL(5,2),
  chest_inches DECIMAL(4,2),
  waist_inches DECIMAL(4,2),
  arms_inches DECIMAL(4,2),
  thighs_inches DECIMAL(4,2),
  neck_inches DECIMAL(4,2),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Personal Records Table
CREATE TABLE IF NOT EXISTS personal_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_name TEXT NOT NULL,
  weight_lbs DECIMAL(6,2) NOT NULL,
  reps INTEGER NOT NULL,
  date DATE NOT NULL,
  notes TEXT,
  is_current_pr BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Achievements Table
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  achievement_name TEXT NOT NULL,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

CREATE INDEX IF NOT EXISTS idx_progress_photos_user_date ON progress_photos(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_body_measurements_user_date ON body_measurements(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_personal_records_user_exercise ON personal_records(user_id, exercise_name, date DESC);
CREATE INDEX IF NOT EXISTS idx_personal_records_current_pr ON personal_records(user_id, exercise_name, is_current_pr) WHERE is_current_pr = TRUE;
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id);

-- =============================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================

-- Enable RLS on all tables
ALTER TABLE progress_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Progress Photos Policies
DROP POLICY IF EXISTS "Users can view their own progress photos" ON progress_photos;
CREATE POLICY "Users can view their own progress photos" ON progress_photos
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own progress photos" ON progress_photos;
CREATE POLICY "Users can insert their own progress photos" ON progress_photos
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own progress photos" ON progress_photos;
CREATE POLICY "Users can update their own progress photos" ON progress_photos
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own progress photos" ON progress_photos;
CREATE POLICY "Users can delete their own progress photos" ON progress_photos
  FOR DELETE USING (auth.uid() = user_id);

-- Body Measurements Policies
DROP POLICY IF EXISTS "Users can view their own body measurements" ON body_measurements;
CREATE POLICY "Users can view their own body measurements" ON body_measurements
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own body measurements" ON body_measurements;
CREATE POLICY "Users can insert their own body measurements" ON body_measurements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own body measurements" ON body_measurements;
CREATE POLICY "Users can update their own body measurements" ON body_measurements
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own body measurements" ON body_measurements;
CREATE POLICY "Users can delete their own body measurements" ON body_measurements
  FOR DELETE USING (auth.uid() = user_id);

-- Personal Records Policies
DROP POLICY IF EXISTS "Users can view their own personal records" ON personal_records;
CREATE POLICY "Users can view their own personal records" ON personal_records
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own personal records" ON personal_records;
CREATE POLICY "Users can insert their own personal records" ON personal_records
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own personal records" ON personal_records;
CREATE POLICY "Users can update their own personal records" ON personal_records
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own personal records" ON personal_records;
CREATE POLICY "Users can delete their own personal records" ON personal_records
  FOR DELETE USING (auth.uid() = user_id);

-- User Achievements Policies
DROP POLICY IF EXISTS "Users can view their own achievements" ON user_achievements;
CREATE POLICY "Users can view their own achievements" ON user_achievements
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own achievements" ON user_achievements;
CREATE POLICY "Users can insert their own achievements" ON user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_progress_photos_updated_at ON progress_photos;
CREATE TRIGGER update_progress_photos_updated_at BEFORE UPDATE ON progress_photos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_body_measurements_updated_at ON body_measurements;
CREATE TRIGGER update_body_measurements_updated_at BEFORE UPDATE ON body_measurements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_personal_records_updated_at ON personal_records;
CREATE TRIGGER update_personal_records_updated_at BEFORE UPDATE ON personal_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to manage personal records (mark previous as not current when new PR is set)
CREATE OR REPLACE FUNCTION manage_personal_records()
RETURNS TRIGGER AS $$
BEGIN
    -- Mark all previous records for this exercise as not current PR
    UPDATE personal_records 
    SET is_current_pr = FALSE 
    WHERE user_id = NEW.user_id 
      AND exercise_name = NEW.exercise_name 
      AND id != NEW.id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for personal records management
DROP TRIGGER IF EXISTS manage_personal_records_trigger ON personal_records;
CREATE TRIGGER manage_personal_records_trigger 
    AFTER INSERT ON personal_records
    FOR EACH ROW EXECUTE FUNCTION manage_personal_records();

-- =============================================
-- STORAGE BUCKETS SETUP
-- =============================================

-- Create storage bucket for progress photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('progress-photos', 'progress-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for progress photos
DROP POLICY IF EXISTS "Users can upload their own progress photos" ON storage.objects;
CREATE POLICY "Users can upload their own progress photos" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'progress-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can view their own progress photos" ON storage.objects;
CREATE POLICY "Users can view their own progress photos" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'progress-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can delete their own progress photos" ON storage.objects;
CREATE POLICY "Users can delete their own progress photos" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'progress-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- =============================================
-- SAMPLE DATA FOR TESTING (Optional)
-- =============================================

-- Note: Sample data will be inserted by the application when users interact with it
-- This ensures proper user authentication and RLS policy enforcement

COMMENT ON TABLE progress_photos IS 'Stores user progress photos with cloud storage references';
COMMENT ON TABLE body_measurements IS 'Tracks user body measurements over time';
COMMENT ON TABLE personal_records IS 'Records personal bests for exercises';
COMMENT ON TABLE user_achievements IS 'Tracks unlocked achievements for gamification';
