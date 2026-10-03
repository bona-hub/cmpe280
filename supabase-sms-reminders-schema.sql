-- =============================================
-- SMS REMINDERS SCHEMA UPDATE
-- =============================================
-- Run this script in your Supabase SQL Editor to add SMS functionality

-- Add phone number and SMS preferences to user_profiles
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20),
ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sms_reminders_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sms_workout_reminders BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS sms_motivation_messages BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sms_progress_reminders BOOLEAN DEFAULT FALSE;

-- Create SMS logs table to track sent messages
CREATE TABLE IF NOT EXISTS sms_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  phone_number VARCHAR(20) NOT NULL,
  message_type VARCHAR(50) NOT NULL, -- 'workout_reminder', 'motivation', 'progress', etc.
  message_content TEXT NOT NULL,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'delivered')),
  error_message TEXT,
  cost_cents INTEGER, -- Track SMS costs
  provider VARCHAR(20) DEFAULT 'twilio'
);

-- Create SMS verification codes table
CREATE TABLE IF NOT EXISTS sms_verification_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  phone_number VARCHAR(20) NOT NULL,
  verification_code VARCHAR(6) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '10 minutes'),
  verified_at TIMESTAMP WITH TIME ZONE,
  attempts INTEGER DEFAULT 0,
  UNIQUE(user_id, phone_number)
);

-- Enable RLS on new tables
ALTER TABLE sms_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_verification_codes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for SMS logs
CREATE POLICY "Users can view own SMS logs" ON sms_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage SMS logs" ON sms_logs
  FOR ALL USING (auth.role() = 'service_role');

-- Create RLS policies for SMS verification codes
CREATE POLICY "Users can view own verification codes" ON sms_verification_codes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own verification codes" ON sms_verification_codes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role can manage verification codes" ON sms_verification_codes
  FOR ALL USING (auth.role() = 'service_role');

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_sms_logs_user_id ON sms_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_sms_logs_sent_at ON sms_logs(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_sms_verification_user_phone ON sms_verification_codes(user_id, phone_number);

-- Grant permissions
GRANT ALL ON sms_logs TO anon, authenticated;
GRANT ALL ON sms_verification_codes TO anon, authenticated;

-- Function to clean up old verification codes
CREATE OR REPLACE FUNCTION cleanup_old_verification_codes()
RETURNS VOID AS $$
BEGIN
  DELETE FROM sms_verification_codes 
  WHERE expires_at < NOW() - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ SMS reminders schema updated successfully!';
  RAISE NOTICE '📱 Added phone number and SMS preferences to user profiles';
  RAISE NOTICE '📊 Created SMS logs and verification tables';
  RAISE NOTICE '🔒 Applied Row Level Security policies';
  RAISE NOTICE '🚀 Ready for SMS integration with Twilio or other providers!';
END
$$; 