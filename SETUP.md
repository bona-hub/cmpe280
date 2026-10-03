# 🚀 Gymcyclopedia Setup Guide

This guide will help you set up Gymcyclopedia with your own database and API credentials.

## 📋 Prerequisites

- Web browser (Chrome, Firefox, Safari, Edge)
- Supabase account (free tier available)
- Optional: Twilio account for SMS notifications

## 🔧 Quick Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/Sandyhub007/summer-project.git
cd summer-project
```

### Step 2: Set Up Supabase Database

1. **Create Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Click "Start your project" and sign up
   - Create a new project

2. **Get Your Credentials**
   - Go to Settings → API
   - Copy your:
     - Project URL (e.g., `https://xyz.supabase.co`)
     - Anon/public key (starts with `eyJhbGci...`)

3. **Set Up Database Schema**
   - Go to SQL Editor in your Supabase dashboard
   - Run each of these SQL files in order:
     ```sql
     -- Copy and paste contents from:
     supabase-setup.sql
     supabase-workouts-schema.sql
     supabase-progress-tracking-schema.sql
     supabase-nutrition-recovery-schema.sql
     contact-messages-schema.sql
     ```

### Step 3: Configure Your Application

Replace the placeholder credentials in ALL HTML files:

**Find and replace in each file:**
- `index.html`
- `workouts.html`
- `ai-coaching.html`
- `nutrition-recovery.html`
- `blog.html`
- `support.html`
- `reset-password.html`

**Replace these lines:**
```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_PROJECT_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

**With your actual credentials:**
```javascript
const SUPABASE_URL = 'https://your-project-id.supabase.co';
const SUPABASE_ANON_KEY = 'your-actual-anon-key-here';
```

### Step 4: Test Your Setup

1. **Start Local Server**
   ```bash
   python3 -m http.server 8000
   ```

2. **Open Application**
   - Navigate to `http://localhost:8000`
   - Try creating an account
   - Test login/logout functionality

## 🔧 Advanced Features (Optional)

### SMS Notifications Setup

1. **Create Twilio Account**
   - Go to [twilio.com](https://www.twilio.com/try-twilio)
   - Get free trial credits

2. **Configure Supabase Edge Functions**
   - Follow instructions in `SMS_REMINDERS_SETUP.md`
   - Set environment variables in Supabase dashboard

### Email Notifications

- Email notifications work automatically through Supabase Auth
- Customize email templates in Supabase dashboard → Authentication → Email Templates

## 🚨 Security Notes

⚠️ **Important Security Considerations:**

1. **Supabase RLS (Row Level Security)**
   - The SQL schemas include RLS policies
   - Users can only access their own data

2. **API Keys**
   - The anon key is safe to expose in frontend code
   - Never expose your service_role key in frontend

3. **Environment Variables**
   - For production deployment, use environment variables
   - Never commit real credentials to version control

## 🌐 Deployment Options

### GitHub Pages
```bash
# After configuring credentials
git add .
git commit -m "Configure with my credentials"
git push origin main

# Enable GitHub Pages in repository settings
```

### Netlify
1. Connect your GitHub repository
2. Build command: (none needed)
3. Publish directory: `/`

### Vercel
1. Import from GitHub
2. Framework: Other
3. Build command: (none needed)

## 🛠️ Troubleshooting

### Common Issues

1. **"Cannot read properties of undefined"**
   - Check if Supabase credentials are correct
   - Ensure all placeholders are replaced

2. **Database connection errors**
   - Verify Supabase project is active
   - Check if SQL schemas were run successfully

3. **Authentication not working**
   - Confirm email confirmation is set up in Supabase
   - Check browser console for detailed errors

### Getting Help

- Check browser console (F12) for detailed error messages
- Review Supabase dashboard logs
- Ensure all SQL files were executed successfully

## 📱 Features Overview

Once set up, your Gymcyclopedia will include:

✅ **User Authentication** - Secure login/signup with email verification  
✅ **Workout Tracking** - Custom workout creation and progress tracking  
✅ **Exercise Library** - Comprehensive exercise database with videos  
✅ **AI Coaching** - Personalized workout recommendations  
✅ **Nutrition & Recovery** - Meal tracking and sleep monitoring  
✅ **Progress Analytics** - Charts and achievement tracking  
✅ **Blog System** - Fitness articles and tips  
✅ **Notification System** - Email and optional SMS reminders  
✅ **Support System** - Contact forms and user support  

## 🎉 You're Ready!

Your Gymcyclopedia is now ready to use. Create an account and start your fitness journey!

For questions or issues, check the troubleshooting section above or review the console logs for detailed error information. 