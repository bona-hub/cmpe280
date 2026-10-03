-- =====================================================
-- GYMCYCLOPEDIA WORKOUT TABLES SETUP
-- =====================================================
-- This script creates the workout management system tables
-- Run this in your Supabase SQL editor to enable workout functionality

-- Create exercises table (reference data)
CREATE TABLE IF NOT EXISTS exercises (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    equipment VARCHAR(100),
    difficulty VARCHAR(20) DEFAULT 'Beginner',
    instructions TEXT,
    muscle_groups TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create workouts table (user's custom workout routines)
CREATE TABLE IF NOT EXISTS workouts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create workout_exercises table (exercises in each workout with sets/reps)
CREATE TABLE IF NOT EXISTS workout_exercises (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    workout_id UUID REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_id INTEGER REFERENCES exercises(id) ON DELETE CASCADE,
    exercise_order INTEGER NOT NULL DEFAULT 1,
    sets INTEGER DEFAULT 3,
    reps VARCHAR(20) DEFAULT '10', -- Can be "10", "8-12", "30 seconds", etc.
    weight_kg DECIMAL(5,2),
    rest_seconds INTEGER DEFAULT 60,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create workout_sessions table (completed workout instances)
CREATE TABLE IF NOT EXISTS workout_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    workout_name VARCHAR(100) NOT NULL, -- Store name in case workout is deleted
    start_time TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    notes TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5), -- 1-5 star rating
    completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create workout_session_exercises table (actual performance data)
CREATE TABLE IF NOT EXISTS workout_session_exercises (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES workout_sessions(id) ON DELETE CASCADE,
    exercise_id INTEGER REFERENCES exercises(id) ON DELETE CASCADE,
    exercise_name VARCHAR(100) NOT NULL, -- Store name in case exercise is deleted
    exercise_order INTEGER NOT NULL,
    sets_completed INTEGER DEFAULT 0,
    target_sets INTEGER DEFAULT 3,
    target_reps VARCHAR(20),
    target_weight_kg DECIMAL(5,2),
    actual_performance JSONB, -- Store actual sets: [{"set": 1, "reps": 10, "weight": 50}, ...]
    completed BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all workout tables
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_session_exercises ENABLE ROW LEVEL SECURITY;

-- Workouts policies (users can only see/modify their own workouts)
CREATE POLICY "Users can view own workouts" ON workouts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own workouts" ON workouts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workouts" ON workouts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workouts" ON workouts
    FOR DELETE USING (auth.uid() = user_id);

-- Workout exercises policies
CREATE POLICY "Users can view own workout exercises" ON workout_exercises
    FOR SELECT USING (
        workout_id IN (SELECT id FROM workouts WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can create own workout exercises" ON workout_exercises
    FOR INSERT WITH CHECK (
        workout_id IN (SELECT id FROM workouts WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update own workout exercises" ON workout_exercises
    FOR UPDATE USING (
        workout_id IN (SELECT id FROM workouts WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can delete own workout exercises" ON workout_exercises
    FOR DELETE USING (
        workout_id IN (SELECT id FROM workouts WHERE user_id = auth.uid())
    );

-- Workout sessions policies
CREATE POLICY "Users can view own workout sessions" ON workout_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own workout sessions" ON workout_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workout sessions" ON workout_sessions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workout sessions" ON workout_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- Workout session exercises policies
CREATE POLICY "Users can view own session exercises" ON workout_session_exercises
    FOR SELECT USING (
        session_id IN (SELECT id FROM workout_sessions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can create own session exercises" ON workout_session_exercises
    FOR INSERT WITH CHECK (
        session_id IN (SELECT id FROM workout_sessions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update own session exercises" ON workout_session_exercises
    FOR UPDATE USING (
        session_id IN (SELECT id FROM workout_sessions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can delete own session exercises" ON workout_session_exercises
    FOR DELETE USING (
        session_id IN (SELECT id FROM workout_sessions WHERE user_id = auth.uid())
    );

-- Exercises table is public (everyone can read reference data)
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view exercises" ON exercises FOR SELECT USING (true);

-- =====================================================
-- POPULATE EXERCISE LIBRARY
-- =====================================================

-- Insert the exercise library data
INSERT INTO exercises (name, category, description, equipment, difficulty, muscle_groups) VALUES
-- Chest exercises
('Push-ups', 'chest', 'Classic bodyweight chest exercise', 'None', 'Beginner', '{"chest", "triceps", "shoulders"}'),
('Bench Press', 'chest', 'Barbell chest press', 'Barbell', 'Intermediate', '{"chest", "triceps", "shoulders"}'),
('Dumbbell Flyes', 'chest', 'Chest isolation exercise', 'Dumbbells', 'Intermediate', '{"chest"}'),

-- Back exercises
('Pull-ups', 'back', 'Upper body pulling exercise', 'Pull-up Bar', 'Intermediate', '{"back", "biceps"}'),
('Deadlifts', 'back', 'Compound pulling movement', 'Barbell', 'Advanced', '{"back", "glutes", "hamstrings"}'),
('Bent-over Rows', 'back', 'Horizontal pulling exercise', 'Barbell', 'Intermediate', '{"back", "biceps"}'),

-- Shoulder exercises
('Overhead Press', 'shoulders', 'Vertical pressing movement', 'Barbell', 'Intermediate', '{"shoulders", "triceps"}'),
('Lateral Raises', 'shoulders', 'Side deltoid isolation', 'Dumbbells', 'Beginner', '{"shoulders"}'),
('Face Pulls', 'shoulders', 'Rear deltoid exercise', 'Cable', 'Beginner', '{"shoulders", "upper_back"}'),

-- Arm exercises
('Bicep Curls', 'arms', 'Bicep isolation exercise', 'Dumbbells', 'Beginner', '{"biceps"}'),
('Tricep Dips', 'arms', 'Tricep bodyweight exercise', 'Bench', 'Intermediate', '{"triceps"}'),
('Hammer Curls', 'arms', 'Neutral grip bicep curls', 'Dumbbells', 'Beginner', '{"biceps", "forearms"}'),

-- Leg exercises
('Squats', 'legs', 'Fundamental leg exercise', 'Bodyweight/Barbell', 'Beginner', '{"quadriceps", "glutes"}'),
('Lunges', 'legs', 'Unilateral leg exercise', 'Bodyweight/Dumbbells', 'Beginner', '{"quadriceps", "glutes", "hamstrings"}'),
('Romanian Deadlifts', 'legs', 'Hip hinge movement', 'Barbell', 'Intermediate', '{"hamstrings", "glutes"}'),

-- Core exercises
('Plank', 'core', 'Isometric core exercise', 'None', 'Beginner', '{"core"}'),
('Russian Twists', 'core', 'Rotational core exercise', 'Medicine Ball', 'Beginner', '{"core", "obliques"}'),
('Mountain Climbers', 'core', 'Dynamic core exercise', 'None', 'Intermediate', '{"core", "shoulders"}'),

-- Cardio exercises
('Burpees', 'cardio', 'Full body cardio exercise', 'None', 'Intermediate', '{"full_body"}'),
('Jumping Jacks', 'cardio', 'Basic cardio movement', 'None', 'Beginner', '{"full_body"}'),
('High Knees', 'cardio', 'Running in place variation', 'None', 'Beginner', '{"legs", "core"}')

ON CONFLICT (name) DO NOTHING; -- Avoid duplicates if running multiple times

-- =====================================================
-- USEFUL VIEWS
-- =====================================================

-- View for complete workout details with exercises
CREATE OR REPLACE VIEW workout_details WITH (security_invoker = true) AS
SELECT 
    w.id,
    w.user_id,
    w.name,
    w.category,
    w.description,
    w.is_active,
    w.created_at,
    w.updated_at,
    COUNT(we.id) as exercise_count,
    ARRAY_AGG(
        JSON_BUILD_OBJECT(
            'exercise_id', e.id,
            'exercise_name', e.name,
            'category', e.category,
            'sets', we.sets,
            'reps', we.reps,
            'weight_kg', we.weight_kg,
            'order', we.exercise_order
        ) ORDER BY we.exercise_order
    ) as exercises
FROM workouts w
LEFT JOIN workout_exercises we ON w.id = we.workout_id
LEFT JOIN exercises e ON we.exercise_id = e.id
GROUP BY w.id, w.user_id, w.name, w.category, w.description, w.is_active, w.created_at, w.updated_at;

-- View for workout session history
CREATE OR REPLACE VIEW workout_history WITH (security_invoker = true) AS
SELECT 
    ws.id,
    ws.user_id,
    ws.workout_name,
    ws.start_time,
    ws.end_time,
    ws.duration_minutes,
    ws.rating,
    ws.completed,
    COUNT(wse.id) as exercises_completed,
    SUM(CASE WHEN wse.completed THEN 1 ELSE 0 END) as exercises_finished
FROM workout_sessions ws
LEFT JOIN workout_session_exercises wse ON ws.id = wse.session_id
GROUP BY ws.id, ws.user_id, ws.workout_name, ws.start_time, ws.end_time, ws.duration_minutes, ws.rating, ws.completed
ORDER BY ws.start_time DESC;

-- =====================================================
-- FUNCTIONS FOR WORKOUT STATS
-- =====================================================

-- Function to get user workout statistics
CREATE OR REPLACE FUNCTION get_user_workout_stats(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
    total_workouts INTEGER;
    this_week_workouts INTEGER;
    total_sessions INTEGER;
    avg_rating DECIMAL(3,2);
    favorite_category TEXT;
BEGIN
    -- Total workouts created
    SELECT COUNT(*) INTO total_workouts
    FROM workouts 
    WHERE user_id = user_uuid AND is_active = true;
    
    -- This week's completed sessions
    SELECT COUNT(*) INTO this_week_workouts
    FROM workout_sessions 
    WHERE user_id = user_uuid 
    AND completed = true
    AND start_time >= DATE_TRUNC('week', NOW());
    
    -- Total completed sessions
    SELECT COUNT(*) INTO total_sessions
    FROM workout_sessions 
    WHERE user_id = user_uuid AND completed = true;
    
    -- Average workout rating
    SELECT AVG(rating) INTO avg_rating
    FROM workout_sessions 
    WHERE user_id = user_uuid AND completed = true AND rating IS NOT NULL;
    
    -- Most frequent workout category
    SELECT w.category INTO favorite_category
    FROM workout_sessions ws
    JOIN workouts w ON ws.workout_id = w.id
    WHERE ws.user_id = user_uuid AND ws.completed = true
    GROUP BY w.category
    ORDER BY COUNT(*) DESC
    LIMIT 1;
    
    RETURN JSON_BUILD_OBJECT(
        'total_workouts', COALESCE(total_workouts, 0),
        'this_week_workouts', COALESCE(this_week_workouts, 0),
        'total_sessions', COALESCE(total_sessions, 0),
        'avg_rating', COALESCE(avg_rating, 0),
        'favorite_category', COALESCE(favorite_category, 'none')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_workouts_category ON workouts(category);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout_id ON workout_exercises(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_start_time ON workout_sessions(start_time);
CREATE INDEX IF NOT EXISTS idx_exercises_category ON exercises(category);

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE workouts IS 'User-created workout routines';
COMMENT ON TABLE workout_exercises IS 'Exercises within each workout with sets/reps/weight targets';
COMMENT ON TABLE workout_sessions IS 'Instances of completed workouts';
COMMENT ON TABLE workout_session_exercises IS 'Actual performance data for each exercise in a session';
COMMENT ON TABLE exercises IS 'Reference library of available exercises';

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Workout tables created successfully!';
    RAISE NOTICE '📊 Exercise library populated with % exercises', (SELECT COUNT(*) FROM exercises);
    RAISE NOTICE '🔒 Row Level Security policies applied';
    RAISE NOTICE '🚀 Ready to save and track workouts!';
END $$; 