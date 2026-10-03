-- =============================================
-- FIX GYMCYCLOPEDIA USER PROFILE CREATION
-- =============================================
-- Run this script in your Supabase SQL Editor to fix the duplicate data issue

-- Update the trigger function to use personalized data from signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (
    id, 
    email, 
    name,
    phone_number,
    sms_reminders_enabled,
    height_cm,
    current_weight_kg,
    goal_weight_kg,
    start_weight_kg,
    months_to_goal,
    daily_calories
  )
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'phone_number',
    COALESCE((NEW.raw_user_meta_data->>'sms_reminders_enabled')::BOOLEAN, FALSE),
    COALESCE((NEW.raw_user_meta_data->>'height_cm')::INTEGER, 170),
    COALESCE((NEW.raw_user_meta_data->>'current_weight_kg')::DECIMAL, 70.0),
    COALESCE((NEW.raw_user_meta_data->>'goal_weight_kg')::DECIMAL, 65.0),
    COALESCE((NEW.raw_user_meta_data->>'start_weight_kg')::DECIMAL, 
             (NEW.raw_user_meta_data->>'current_weight_kg')::DECIMAL, 70.0),
    COALESCE((NEW.raw_user_meta_data->>'months_to_goal')::INTEGER, 6),
    COALESCE((NEW.raw_user_meta_data->>'daily_calories')::INTEGER, 2000)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Show success message
DO $$
BEGIN
  RAISE NOTICE '✅ User profile creation trigger updated successfully!';
  RAISE NOTICE '🎯 Now uses personalized data from signup form';
  RAISE NOTICE '🚫 No more duplicate default values for new users';
  RAISE NOTICE '📊 Each user gets their own unique fitness profile';
END
$$; 