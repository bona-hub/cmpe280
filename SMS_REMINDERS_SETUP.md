# 📱 SMS Workout Reminders Setup Guide

This guide will help you set up SMS text message reminders for your Gymcyclopedia users using Twilio and Supabase Edge Functions.

## Prerequisites

- Supabase project with user authentication set up
- Twilio account (free trial available)
- Basic familiarity with Supabase Dashboard

## Step 1: Set Up Twilio Account

### 1.1 Create Twilio Account
1. Go to [https://www.twilio.com/try-twilio](https://www.twilio.com/try-twilio)
2. Sign up for a free account
3. Verify your email and phone number
4. You'll get $15.50 in free trial credits

### 1.2 Get Twilio Credentials
1. Go to your [Twilio Console Dashboard](https://console.twilio.com/)
2. Note down these values:
   - **Account SID** (starts with "AC...")
   - **Auth Token** (click the eye icon to reveal)

### 1.3 Get a Twilio Phone Number
1. In Twilio Console, go to **Phone Numbers** > **Manage** > **Buy a number**
2. Choose a number from your country
3. Make sure it has SMS capabilities
4. Purchase the number (free with trial credits)

## Step 2: Update Database Schema

### 2.1 Run SMS Schema Update
Run the `supabase-sms-reminders-schema.sql` file in your Supabase SQL Editor:

```sql
-- This adds phone number and SMS preference columns to user_profiles
-- Plus creates SMS logs and verification tables
```

### 2.2 Update User Profile Trigger
Run the updated `supabase-fix-trigger.sql` to handle phone numbers in user registration.

## Step 3: Set Up Supabase Edge Functions

### 3.1 Install Supabase CLI
```bash
npm install -g supabase
```

### 3.2 Login to Supabase
```bash
supabase login
```

### 3.3 Link Your Project
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

### 3.4 Deploy Edge Functions
```bash
# Deploy the SMS sending function
supabase functions deploy send-sms

# Deploy the scheduled reminder function
supabase functions deploy schedule-sms-reminders
```

## Step 4: Configure Environment Variables

### 4.1 Set Twilio Environment Variables
In your Supabase Dashboard, go to **Settings** > **Edge Functions** and add these secrets:

```bash
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=your_twilio_phone_number_here
```

Example:
```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_secret_auth_token_here
TWILIO_PHONE_NUMBER=+1555XXXXXXX
```

## Step 5: Set Up Scheduled Reminders

### 5.1 Using Supabase Cron (Recommended)
Create a cron job in your Supabase Dashboard:

1. Go to **Database** > **Functions**
2. Create a new function:

```sql
-- Create a function to call the Edge Function every minute
CREATE OR REPLACE FUNCTION trigger_sms_scheduler()
RETURNS void AS $$
BEGIN
  -- Call the Edge Function
  PERFORM net.http_post(
    url := 'https://your-project-ref.supabase.co/functions/v1/schedule-sms-reminders',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.settings.service_role_key') || '"}'::jsonb
  );
END;
$$ LANGUAGE plpgsql;
```

3. Create a cron job:
```sql
-- Run every minute to check for scheduled reminders
SELECT cron.schedule('sms-reminders', '* * * * *', 'SELECT trigger_sms_scheduler();');
```

### 5.2 Alternative: External Cron Service
You can also use external services like:
- GitHub Actions with scheduled workflows
- Vercel Cron Jobs
- Railway Cron Jobs
- Traditional cron on a server

Example cURL command for external cron:
```bash
curl -X POST \
  https://your-project-ref.supabase.co/functions/v1/schedule-sms-reminders \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json"
```

## Step 6: Test the Setup

### 6.1 Test SMS Sending
1. Log into your app
2. Go to Workouts page > Smart Notifications tab
3. Enter your phone number
4. Click "Verify Phone" (in development, you'll see the code in a modal)
5. Enable SMS workout reminders
6. Save settings

### 6.2 Test Manual SMS
You can test sending an SMS manually by calling the Edge Function:

```bash
curl -X POST \
  https://your-project-ref.supabase.co/functions/v1/send-sms \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+1234567890",
    "message": "Test workout reminder! 💪",
    "message_type": "test"
  }'
```

### 6.3 Test Scheduled Reminders
Manually trigger the scheduler:

```bash
curl -X POST \
  https://your-project-ref.supabase.co/functions/v1/schedule-sms-reminders \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

## Step 7: Customize Message Content

### 7.1 Workout Reminders
Edit the message in `schedule-sms-reminders/index.ts`:
```typescript
message = `🏋️ Hi ${user.name}! Time for your workout! 💪 Open Gymcyclopedia now! 🔥`
```

### 7.2 Motivation Messages
Add more motivational messages to the array in the scheduler function.

### 7.3 Timing
Modify the reminder times in the scheduler:
- Workout reminders: Currently 6 PM (18:00)
- Motivation messages: Currently 9 AM
- Progress check-ins: Currently Sunday 7 PM

## Step 8: Monitor and Analytics

### 8.1 View SMS Logs
Check the `sms_logs` table in your Supabase database to monitor:
- Messages sent
- Delivery status
- Costs
- Error messages

### 8.2 Check Edge Function Logs
In Supabase Dashboard, go to **Edge Functions** > **Logs** to see function execution logs.

## Cost Considerations

### Twilio Pricing (as of 2024)
- **US/Canada SMS**: ~$0.0075 per message
- **International SMS**: Varies by country ($0.05-$0.15 per message)
- **Phone number rental**: ~$1.15/month

### Cost Estimation
For 100 users getting daily reminders:
- 100 users × 30 days × $0.0075 = ~$22.50/month
- Plus phone number: $1.15/month
- **Total**: ~$23.65/month

## Troubleshooting

### Common Issues

1. **SMS not sending**
   - Check Twilio credentials are correct
   - Verify phone number format (include country code)
   - Check Twilio Console for error messages

2. **Function deployment fails**
   - Ensure Supabase CLI is updated
   - Check function syntax
   - Verify project linking

3. **Scheduled reminders not working**
   - Check cron job is created
   - Verify Edge Function is deployed
   - Check function logs for errors

4. **Phone verification issues**
   - Ensure SMS schema is applied
   - Check user is logged in
   - Verify phone number format

### Support Resources
- [Twilio Documentation](https://www.twilio.com/docs)
- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Supabase Discord Community](https://discord.supabase.com)

## Security Best Practices

1. **Never commit Twilio credentials** to version control
2. **Use environment variables** for all sensitive data
3. **Implement rate limiting** to prevent SMS abuse
4. **Validate phone numbers** before sending
5. **Provide easy opt-out mechanism** for users
6. **Store SMS logs** for audit purposes

## Next Steps

Once SMS reminders are working:
1. Add user preference for reminder timing
2. Implement more sophisticated scheduling (user timezones)
3. Add SMS delivery status webhooks
4. Create admin dashboard for SMS analytics
5. Implement A/B testing for message content

---

🎉 **Congratulations!** You now have a complete SMS reminder system for your fitness app!

Users can receive personalized workout reminders, motivation messages, and progress check-ins directly on their phones, increasing engagement and helping them stay consistent with their fitness goals. 