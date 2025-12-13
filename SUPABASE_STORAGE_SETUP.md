# Supabase Storage Setup Guide

## Problem Identified
**Error**: `StorageException(message: Bucket not found, statusCode: 404, error: Bucket not found)`

Your Supabase project doesn't have a storage bucket named `public` configured.

---

## Solution: Create Storage Bucket in Supabase

### Step 1: Access Supabase Dashboard

1. Go to https://supabase.com/
2. Sign in with your account
3. Select your LMS project
4. Go to **Storage** (left sidebar)

### Step 2: Create "public" Bucket

1. Click **+ New Bucket**
2. Name it: `public` (lowercase, no spaces)
3. **Enable Public Bucket** → Toggle ON
   - This allows unauthenticated users to view uploaded images via public URLs
4. Click **Create Bucket**

### Step 3: Configure RLS (Row Level Security) Policies

For the `public` bucket, set the following policies:

#### Policy 1: Allow Authenticated Users to Upload

```
Definition:
- Name: "Allow authenticated users to upload"
- Permissions: SELECT, INSERT, UPDATE
- Target roles: authenticated
- USING: true
- WITH CHECK: true
```

#### Policy 2: Allow Public Access to View Files

```
Definition:
- Name: "Allow public access to read files"
- Permissions: SELECT
- Target roles: anon
- USING: true
- WITH CHECK: (empty)
```

### Step 4: Verify Configuration

Your bucket should have:
- ✅ Bucket Name: `public`
- ✅ Public Bucket: Enabled
- ✅ RLS Policies: Configured
- ✅ Access Level: Everyone can read, authenticated can write

---

## How the Enhanced Storage System Works

Your app now has a **robust, self-healing** storage system:

### 1. **Bucket Discovery** (Automatic)
```
Try bucket: "public"
  └─ Not found? Try "uploads"
     └─ Neither found? Show helpful error
```

### 2. **Image Validation** (Automatic)
- ✅ File size < 5MB
- ✅ Format: JPG, PNG, GIF
- ✅ File exists and readable

### 3. **Error Handling** (User-Friendly)
- 404 → "Bucket not found. Contact admin."
- 403 → "Permission denied. Check storage."
- 413 → "File too large (max 5MB)."
- Other → Specific error message

### 4. **Detailed Logging** (Debugging)
Every upload logs:
```
[ProfileUpload] Starting profile picture upload...
[ProfileUpload] Image validated - Size: 2.45MB
[ProfileUpload] Testing bucket: "public"
[ProfileUpload] ✓ Bucket "public" is available
[ProfileUpload] Uploading to bucket: "public", path: profile_pictures/user_id_timestamp.jpg
[ProfileUpload] ✓ File uploaded successfully
[ProfileUpload] ✓ Public URL generated: https://...
```

---

## Complete Upload Flow

```
1. User picks image from gallery
   ├─ Local preview shown immediately
   └─ File validated (size, format, exists)

2. User clicks "Save Changes"
   ├─ Find available bucket ("public" or "uploads")
   ├─ Upload to discovered bucket
   ├─ Get public CDN URL
   └─ Store URL in database

3. Profile reloads
   ├─ Fetch updated data from database
   ├─ Display image from CDN URL
   └─ Show success message

4. Profile picture displays from CDN
   ├─ Fast loading
   ├─ No local storage needed
   └─ Works across all devices
```

---

## File Structure in Storage

After uploading, your bucket structure will look like:

```
public/
├── profile_pictures/
│   ├── user123_1702170000000.jpg
│   ├── user123_1702180000000.jpg
│   ├── user456_1702170000000.png
│   └── ...
│
└── post_images/
    ├── user123_1702170000000.jpg
    ├── user456_1702175000000.jpg
    └── ...
```

Each file:
- **Unique path**: Includes user ID and timestamp
- **Public URL**: Served via Supabase CDN
- **No collisions**: Multiple uploads per user supported
- **Direct access**: URLs work without authentication

---

## Example Public URLs

After successful upload, you'll get URLs like:

```
https://YOUR_SUPABASE_URL.supabase.co/storage/v1/object/public/public/profile_pictures/user123_1702170000000.jpg

https://YOUR_SUPABASE_URL.supabase.co/storage/v1/object/public/public/post_images/user456_1702175000000.jpg
```

These URLs:
- ✅ Are publicly accessible
- ✅ Don't require authentication
- ✅ Are cached by CDN
- ✅ Can be shared with others
- ✅ Work in images, links, etc.

---

## Troubleshooting

### Still Getting "Bucket not found"?

1. **Verify bucket exists**:
   - Go to Supabase Dashboard → Storage
   - Confirm bucket "public" is listed

2. **Check bucket is PUBLIC**:
   - Click bucket settings
   - Verify "Public Bucket" toggle is ON

3. **Verify RLS policies**:
   - Storage → public bucket → Policies
   - At least one policy for `anon` or `authenticated` should exist

4. **Check authentication**:
   - User must be logged in to upload
   - This is automatic in your app

5. **Test manually**:
   - Go to Storage tab in Supabase
   - Try uploading a test image manually
   - If that fails, bucket configuration issue

### Image uploads timeout?

- Check file size (max 5MB)
- Check internet connection
- Check Supabase service status
- Try with smaller image

### Uploaded but not showing?

- Verify URL is HTTPS
- Check file was uploaded to correct bucket
- Verify RLS policies allow reading
- Clear app cache and reload

---

## Code Changes Made

### StorageService Enhancements

✅ **Image Validation**
```dart
- File size < 5MB
- Allowed formats: JPG, PNG, GIF
- File exists check
```

✅ **Bucket Auto-Discovery**
```dart
- Try "public" bucket first
- Fallback to "uploads" bucket
- Clear error if neither found
```

✅ **User-Friendly Errors**
```dart
- 404 → Bucket not found
- 403 → Permission denied
- 413 → File too large
- Other → Specific message
```

✅ **Detailed Logging**
```dart
- [ProfileUpload] prefix for tracking
- Step-by-step logging
- Error stack traces
```

✅ **New Return Type**
```dart
// Before: Future<String?> (ambiguous on failure)
// After: Future<({String? url, String? error})>

final result = await uploadProfilePicture(...);
print(result.url);   // Public URL or null
print(result.error); // Error message or null
```

### ProfileScreen Updates

✅ **Better Error Handling**
```dart
- Capture and display upload errors
- Allow bio update even if image fails
- Show specific error messages
```

✅ **User Feedback**
```dart
- Separate messages for success/partial-success
- 4-second error messages for visibility
- Clear SnackBar feedback
```

---

## Testing Checklist

After setting up the bucket, verify:

- [ ] Supabase bucket "public" exists
- [ ] Public Bucket toggle is ON
- [ ] RLS policies are configured
- [ ] Pick image in profile → preview shows
- [ ] Save changes → no bucket error
- [ ] Image uploads to Supabase
- [ ] Public URL generated correctly
- [ ] Profile reloads with new image
- [ ] CDN serves image fast
- [ ] Error messages display on failure

---

## Next Steps

1. **Create the "public" bucket** in Supabase (5 min)
2. **Configure RLS policies** (2 min)
3. **Test upload flow** (2 min)
4. **Done!** Your profile pictures will upload to cloud storage

After that, your system is:
- ✅ Scalable (unlimited images)
- ✅ Fast (CDN delivery)
- ✅ Reliable (auto-bucket discovery)
- ✅ User-friendly (helpful errors)
- ✅ Production-ready
