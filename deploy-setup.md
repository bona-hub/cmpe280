# 🚀 Netlify Deployment Setup Guide

## Quick Fix for Current Deployment Issues

Your Netlify deployment is failing because it's using placeholder credentials instead of your actual Supabase credentials. Here's how to fix it:

## Option 1: Direct Credential Replacement (Fastest)

### Step 1: Update Your Local Files

Replace the placeholder values in ALL HTML files with your actual credentials:

**Find this in each HTML file:**
```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_PROJECT_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

**Replace with your actual credentials:**
```javascript
const SUPABASE_URL = 'https://stojhqobywrvkjaabcvq.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0b2pocW9ieXdydmtqYWFiY3ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyMDcwMDEsImV4cCI6MjA2NTc4MzAwMX0.JQeFsT3nUFMpQ1Tz9uYBnZ3IuE_gBK9P9Du0Igo7Hsg';
```

**Files to update:**
- index.html
- workouts.html
- ai-coaching.html
- nutrition-recovery.html
- blog.html
- support.html
- reset-password.html

### Step 2: Commit and Push
```bash
git add .
git commit -m "Add production credentials for Netlify deployment"
git push
```

### Step 3: Redeploy on Netlify
- Go to your Netlify dashboard
- Click "Trigger deploy" → "Deploy site"
- Wait for deployment to complete

## Option 2: Environment Variables (More Secure)

### Step 1: Set Environment Variables in Netlify
1. Go to your Netlify site dashboard
2. Click **Site settings** → **Environment variables**
3. Add these variables:
   - `SUPABASE_URL` = `https://stojhqobywrvkjaabcvq.supabase.co`
   - `SUPABASE_ANON_KEY` = `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0b2pocW9ieXdydmtqYWFiY3ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyMDcwMDEsImV4cCI6MjA2NTc4MzAwMX0.JQeFsT3nUFMpQ1Tz9uYBnZ3IuE_gBK9P9Du0Igo7Hsg`

### Step 2: Update HTML Files to Use Environment Variables
Replace the config sections with:
```javascript
const SUPABASE_URL = window.ENV?.SUPABASE_URL || 'https://stojhqobywrvkjaabcvq.supabase.co';
const SUPABASE_ANON_KEY = window.ENV?.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0b2pocW9ieXdydmtqYWFiY3ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyMDcwMDEsImV4cCI6MjA2NTc4MzAwMX0.JQeFsT3nUFMpQ1Tz9uYBnZ3IuE_gBK9P9Du0Igo7Hsg';
```

## Quick Command to Replace All Files

Run this command to replace placeholders in all files at once:

```bash
# Replace URL
find . -name "*.html" -exec sed -i 's/YOUR_SUPABASE_PROJECT_URL/https:\/\/stojhqobywrvkjaabcvq.supabase.co/g' {} \;

# Replace API Key  
find . -name "*.html" -exec sed -i 's/YOUR_SUPABASE_ANON_KEY/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0b2pocW9ieXdydmtqYWFiY3ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyMDcwMDEsImV4cCI6MjA2NTc4MzAwMX0.JQeFsT3nUFMpQ1Tz9uYBnZ3IuE_gBK9P9Du0Igo7Hsg/g' {} \;
```

## Authentication Issues Fix

If users can access pages without logging in, add this to the top of each protected page's script section:

```javascript
// Immediate redirect for unauthenticated users
(async function() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session && window.location.pathname !== '/' && window.location.pathname !== '/index.html') {
    window.location.href = '/';
  }
})();
```

## Troubleshooting

### Issue: "Loading workout templates..." stuck
**Solution:** Database connection failed - check Supabase credentials

### Issue: Can access pages without login
**Solution:** Add authentication guards to each page

### Issue: 404 errors on refresh
**Solution:** Add this to netlify.toml:
```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

## Recommended Approach

For immediate deployment, use **Option 1** (Direct Credential Replacement). It's the fastest way to get your site working on Netlify right now.

After deployment works, you can implement Option 2 for better security if needed. 