# 🔍 Progress Photo Troubleshooting Guide

## Issue: Photos Disappearing After Page Reload

### Quick Diagnostic Steps

#### 1. **Open Browser Console**
- Press `F12` or `Right-click` → `Inspect` → `Console` tab
- Look for these messages when you upload a photo:
  - `📸 Starting photo upload...`
  - `📸 Photo saved to localStorage`
  - `✅ Photo saved to Supabase Storage and database` ← **Most important!**
  - `✅ Photo upload completed successfully`

#### 2. **Check What Message You Got**

**If you see:**
```
✅ Photo saved to Supabase Storage and database
```
✅ **Good!** Photo is in database, should persist after reload.

**If you see:**
```
⚠️ Supabase Storage not available, trying database with base64...
✅ Photo saved to database with base64
```
✅ **Also good!** Photo is in database as base64.

**If you see:**
```
Photo saved locally! 📸 (Will sync to database when available)
```
⚠️ **Problem!** Photo only in localStorage, will disappear on reload.

#### 3. **Check After Page Reload**

Open console and look for:
```
📸 Loaded progress photos from database: X
```

**If X = 0:** Photos aren't being saved to database
**If X > 0:** Photos are in database but might not be displaying

### Common Issues & Solutions

#### Issue 1: Storage Bucket Not Set Up
**Symptom:** Error message about storage bucket

**Solution:**
1. Go to your Supabase Dashboard
2. Navigate to **Storage** section
3. Check if `progress-photos` bucket exists
4. If not, run this SQL in Supabase SQL Editor:

```sql
-- Create storage bucket for progress photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('progress-photos', 'progress-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for progress photos
CREATE POLICY "Users can upload their own progress photos" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'progress-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view their own progress photos" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'progress-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own progress photos" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'progress-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

#### Issue 2: Photos Table Not Set Up
**Symptom:** Error about `progress_photos` table not existing

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Run the schema file: `supabase-progress-tracking-schema.sql`

#### Issue 3: Photo Too Large
**Symptom:** Upload fails or takes too long

**Solution:**
- Keep photos under 5MB
- Use compressed/resized images
- The app will automatically compress images over 1MB

#### Issue 4: LocalStorage Only
**Symptom:** Photo shows up initially but disappears after reload

**What's happening:**
- Photo saved to browser's localStorage only
- Not saved to Supabase database
- LocalStorage gets cleared or photo ID conflicts

**Solution:**
1. Check browser console for Supabase errors
2. Verify you're logged in (check for session)
3. Check database connection

### Manual Check: View Your Photos in Database

#### Method 1: Browser Console
After logging in, paste this in the console:

```javascript
// Check localStorage
console.log('LocalStorage photos:', JSON.parse(localStorage.getItem('progressPhotos') || '[]'));

// Check if logged in
supabase.auth.getSession().then(({data: {session}}) => {
  console.log('Logged in as:', session?.user?.email);
  
  // Load from database
  if (session) {
    supabase
      .from('progress_photos')
      .select('*')
      .eq('user_id', session.user.id)
      .then(({data, error}) => {
        console.log('Database photos:', data);
        console.log('Error:', error);
      });
  }
});
```

#### Method 2: Supabase Dashboard
1. Go to Supabase Dashboard
2. Click **Table Editor**
3. Select `progress_photos` table
4. Check if your photos are there
5. Look for your `user_id`

### Testing the Fix

1. **Clear everything first:**
```javascript
// In browser console
localStorage.removeItem('progressPhotos');
console.log('LocalStorage cleared');
```

2. **Reload the page**

3. **Upload a NEW photo**

4. **Watch the console messages**

5. **Reload the page again**

6. **Check if photo persists**

### Expected Console Output (Successful Upload)

```
📸 Starting photo upload...
📸 Photo data prepared: {size: "245KB", category: "front", date: "2025-11-13"}
📸 Photo saved to localStorage
✅ Photo saved to Supabase Storage and database
✅ Photo upload completed successfully
📸 Current photos count: 1
```

### After Reload, Expected Output:

```
📊 Loading progress data...
📊 Syncing with database...
📸 Loaded progress photos from database: 1
📸 Total photos after merge: 1
✅ Progress tracking initialized
```

### Still Having Issues?

Check these:
1. ✅ Supabase credentials are correct in HTML files
2. ✅ You're logged in (session exists)
3. ✅ `progress_photos` table exists in database
4. ✅ `progress-photos` storage bucket exists
5. ✅ No console errors
6. ✅ Internet connection is active

### Quick Fix Command

If photos are in localStorage but not database, run this in console:

```javascript
// Force sync localStorage photos to database
async function syncPhotosToDatabase() {
  const localPhotos = JSON.parse(localStorage.getItem('progressPhotos') || '[]');
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    console.error('Not logged in!');
    return;
  }
  
  console.log('Found', localPhotos.length, 'photos in localStorage');
  
  for (const photo of localPhotos) {
    // Skip if already has database ID (UUID format)
    if (photo.id && typeof photo.id === 'string' && photo.id.includes('-')) {
      console.log('Skipping photo', photo.id, '- already in database');
      continue;
    }
    
    try {
      const { data, error } = await supabase
        .from('progress_photos')
        .insert({
          user_id: session.user.id,
          image_url: photo.image_url,
          date: photo.date,
          category: photo.category,
          notes: photo.notes || null
        })
        .select()
        .single();
      
      if (error) {
        console.error('Error syncing photo:', error);
      } else {
        console.log('✅ Synced photo to database:', data.id);
      }
    } catch (e) {
      console.error('Error:', e);
    }
  }
  
  console.log('Sync complete! Reload the page.');
}

// Run it
syncPhotosToDatabase();
```

---

**Need more help?** Open browser console and share the output messages!

