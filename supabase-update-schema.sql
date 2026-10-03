-- =============================================
-- GYMCYCLOPEDIA PROGRESS TRACKING SCHEMA UPDATE
-- =============================================
-- Run this script in your Supabase SQL Editor after the initial setup

-- Add new columns to user_profiles for better progress tracking
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS start_weight_kg DECIMAL(5,2);

ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS streak_days INTEGER DEFAULT 0;

ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS last_log_date DATE;

-- Update existing users to set start_weight_kg = current_weight_kg if not set
UPDATE public.user_profiles 
SET start_weight_kg = current_weight_kg 
WHERE start_weight_kg IS NULL;

-- Create weight_logs table for tracking weight over time
CREATE TABLE IF NOT EXISTS public.weight_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  weight_kg DECIMAL(5,2) NOT NULL,
  log_date DATE DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for weight_logs
ALTER TABLE public.weight_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for weight_logs
CREATE POLICY "Users can view own weight logs" ON public.weight_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own weight logs" ON public.weight_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own weight logs" ON public.weight_logs
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own weight logs" ON public.weight_logs
  FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions for weight_logs
GRANT ALL ON public.weight_logs TO anon, authenticated;

-- Create function to update streak when logging weight
CREATE OR REPLACE FUNCTION public.update_streak_on_weight_log()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.user_profiles 
  SET 
    last_log_date = NEW.log_date,
    streak_days = CASE 
      WHEN last_log_date IS NULL THEN 1
      WHEN last_log_date = NEW.log_date - INTERVAL '1 day' THEN streak_days + 1
      WHEN last_log_date = NEW.log_date THEN streak_days -- Same day, no change
      ELSE 1 -- Reset streak if gap > 1 day
    END,
    current_weight_kg = NEW.weight_kg
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for streak updates
DROP TRIGGER IF EXISTS update_streak_on_weight_log ON public.weight_logs;
CREATE TRIGGER update_streak_on_weight_log
  AFTER INSERT ON public.weight_logs
  FOR EACH ROW EXECUTE PROCEDURE public.update_streak_on_weight_log();

-- Show success message
DO $$
BEGIN
  RAISE NOTICE '✅ Progress tracking schema updated successfully!';
  RAISE NOTICE '📊 Added start_weight_kg, streak_days, last_log_date columns';
  RAISE NOTICE '📈 Created weight_logs table for tracking over time';
  RAISE NOTICE '🔥 Added automatic streak calculation triggers';
  RAISE NOTICE '🎯 Ready for enhanced progress tracking features!';
END
$$; 