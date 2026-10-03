-- =============================================
-- GYMCYCLOPEDIA SUPABASE DATABASE SETUP (SAFE VERSION)
-- =============================================
-- Run this script in your Supabase SQL Editor
-- This version avoids DROP statements to prevent warnings

-- Create user_profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  current_weight_kg DECIMAL(5,2) DEFAULT 70.0,
  goal_weight_kg DECIMAL(5,2) DEFAULT 65.0,
  height_cm INTEGER DEFAULT 170,
  months_to_goal INTEGER DEFAULT 6,
  daily_calories INTEGER DEFAULT 2000,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies so users can only access their own data
-- Using DO block to handle "already exists" errors gracefully
DO $$
BEGIN
  -- Policy for SELECT
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_profiles' 
    AND policyname = 'Users can view own profile'
  ) THEN
    CREATE POLICY "Users can view own profile" ON public.user_profiles
      FOR SELECT USING (auth.uid() = id);
  END IF;

  -- Policy for UPDATE  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_profiles' 
    AND policyname = 'Users can update own profile'
  ) THEN
    CREATE POLICY "Users can update own profile" ON public.user_profiles
      FOR UPDATE USING (auth.uid() = id);
  END IF;

  -- Policy for INSERT
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_profiles' 
    AND policyname = 'Users can insert own profile'
  ) THEN
    CREATE POLICY "Users can insert own profile" ON public.user_profiles
      FOR INSERT WITH CHECK (auth.uid() = id);
  END IF;

  -- Policy for DELETE
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_profiles' 
    AND policyname = 'Users can delete own profile'
  ) THEN
    CREATE POLICY "Users can delete own profile" ON public.user_profiles
      FOR DELETE USING (auth.uid() = id);
  END IF;
END
$$;

-- Create function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, name)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to call the function on user signup (only if it doesn't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'on_auth_user_created'
  ) THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
  END IF;
END
$$;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at (only if it doesn't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'handle_updated_at' 
    AND tgrelid = 'public.user_profiles'::regclass
  ) THEN
    CREATE TRIGGER handle_updated_at
      BEFORE UPDATE ON public.user_profiles
      FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
  END IF;
END
$$;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.user_profiles TO anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Show success message
DO $$
BEGIN
  RAISE NOTICE '✅ Gymcyclopedia database setup completed successfully!';
  RAISE NOTICE '🚀 Your app is now ready to use with Supabase authentication';
  RAISE NOTICE '📊 User profiles table created with RLS policies';
  RAISE NOTICE '🔧 Automatic triggers set up for new user creation';
  RAISE NOTICE '👤 Create users through your app signup - not manually!';
  RAISE NOTICE '🔒 No destructive operations were performed';
END
$$; 