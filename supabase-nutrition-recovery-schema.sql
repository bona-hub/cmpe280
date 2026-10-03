-- =============================================
-- GYMCYCLOPEDIA NUTRITION & RECOVERY SCHEMA
-- =============================================

-- Sleep Tracking Table
CREATE TABLE IF NOT EXISTS sleep_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  hours_slept DECIMAL(3,1) NOT NULL CHECK (hours_slept >= 0 AND hours_slept <= 24),
  sleep_quality INTEGER CHECK (sleep_quality >= 1 AND sleep_quality <= 5),
  bedtime TIME,
  wake_time TIME,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Daily Nutrition Summary Table
CREATE TABLE IF NOT EXISTS daily_nutrition (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_calories INTEGER DEFAULT 0,
  total_protein DECIMAL(6,2) DEFAULT 0,
  total_carbs DECIMAL(6,2) DEFAULT 0,
  total_fat DECIMAL(6,2) DEFAULT 0,
  water_intake_ml INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Meal Logs Table
CREATE TABLE IF NOT EXISTS meal_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  description TEXT NOT NULL,
  estimated_calories INTEGER,
  estimated_protein DECIMAL(5,2),
  estimated_carbs DECIMAL(5,2),
  estimated_fat DECIMAL(5,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recovery Assessments Table
CREATE TABLE IF NOT EXISTS recovery_assessments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  recovery_score INTEGER CHECK (recovery_score >= 1 AND recovery_score <= 10),
  stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 10),
  energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 10),
  muscle_soreness INTEGER CHECK (muscle_soreness >= 1 AND muscle_soreness <= 10),
  motivation_level INTEGER CHECK (motivation_level >= 1 AND motivation_level <= 10),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Water Intake Logs Table (for detailed tracking)
CREATE TABLE IF NOT EXISTS water_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  amount_ml INTEGER NOT NULL,
  logged_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_date ON sleep_logs(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_nutrition_user_date ON daily_nutrition(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_meal_logs_user_date ON meal_logs(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_recovery_assessments_user_date ON recovery_assessments(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_water_logs_user_date ON water_logs(user_id, date DESC);

-- =============================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================

-- Enable RLS on all tables
ALTER TABLE sleep_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_nutrition ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE recovery_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE water_logs ENABLE ROW LEVEL SECURITY;

-- Sleep Logs Policies
CREATE POLICY "Users can manage their own sleep logs" ON sleep_logs
  FOR ALL USING (auth.uid() = user_id);

-- Daily Nutrition Policies
CREATE POLICY "Users can manage their own daily nutrition" ON daily_nutrition
  FOR ALL USING (auth.uid() = user_id);

-- Meal Logs Policies
CREATE POLICY "Users can manage their own meal logs" ON meal_logs
  FOR ALL USING (auth.uid() = user_id);

-- Recovery Assessments Policies
CREATE POLICY "Users can manage their own recovery assessments" ON recovery_assessments
  FOR ALL USING (auth.uid() = user_id);

-- Water Logs Policies
CREATE POLICY "Users can manage their own water logs" ON water_logs
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_nutrition_recovery_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_sleep_logs_updated_at BEFORE UPDATE ON sleep_logs
    FOR EACH ROW EXECUTE FUNCTION update_nutrition_recovery_updated_at();

CREATE TRIGGER update_daily_nutrition_updated_at BEFORE UPDATE ON daily_nutrition
    FOR EACH ROW EXECUTE FUNCTION update_nutrition_recovery_updated_at();

CREATE TRIGGER update_meal_logs_updated_at BEFORE UPDATE ON meal_logs
    FOR EACH ROW EXECUTE FUNCTION update_nutrition_recovery_updated_at();

CREATE TRIGGER update_recovery_assessments_updated_at BEFORE UPDATE ON recovery_assessments
    FOR EACH ROW EXECUTE FUNCTION update_nutrition_recovery_updated_at();

-- Function to automatically update daily nutrition totals when meals are logged
CREATE OR REPLACE FUNCTION update_daily_nutrition_totals()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert or update daily nutrition summary
    INSERT INTO daily_nutrition (user_id, date, total_calories, total_protein, total_carbs, total_fat)
    VALUES (
        NEW.user_id,
        NEW.date,
        COALESCE(NEW.estimated_calories, 0),
        COALESCE(NEW.estimated_protein, 0),
        COALESCE(NEW.estimated_carbs, 0),
        COALESCE(NEW.estimated_fat, 0)
    )
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        total_calories = daily_nutrition.total_calories + COALESCE(NEW.estimated_calories, 0),
        total_protein = daily_nutrition.total_protein + COALESCE(NEW.estimated_protein, 0),
        total_carbs = daily_nutrition.total_carbs + COALESCE(NEW.estimated_carbs, 0),
        total_fat = daily_nutrition.total_fat + COALESCE(NEW.estimated_fat, 0),
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update daily nutrition when meals are logged
CREATE TRIGGER update_daily_nutrition_on_meal_insert 
    AFTER INSERT ON meal_logs
    FOR EACH ROW EXECUTE FUNCTION update_daily_nutrition_totals();

-- Function to update water intake in daily nutrition
CREATE OR REPLACE FUNCTION update_daily_water_intake()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert or update daily nutrition summary with water intake
    INSERT INTO daily_nutrition (user_id, date, water_intake_ml)
    VALUES (NEW.user_id, NEW.date, NEW.amount_ml)
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        water_intake_ml = daily_nutrition.water_intake_ml + NEW.amount_ml,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update daily water intake when water is logged
CREATE TRIGGER update_daily_water_on_log_insert 
    AFTER INSERT ON water_logs
    FOR EACH ROW EXECUTE FUNCTION update_daily_water_intake();

-- =============================================
-- SAMPLE DATA FOR TESTING (Optional)
-- =============================================

-- Sample sleep log (uncomment for testing)
-- INSERT INTO sleep_logs (user_id, date, hours_slept, sleep_quality, notes)
-- VALUES (
--     auth.uid(),
--     CURRENT_DATE,
--     8.0,
--     4,
--     'Good night sleep, woke up refreshed'
-- ); 