# Quick Fix: Supabase Storage Bucket Not Found

## ⚡ Quick Steps (5 Minutes)

### 1. Open Supabase Dashboard
```
https://supabase.com/ → Your Project → Storage
```

### 2. Create Bucket
- Click **+ New Bucket**
- Name: `public` (exactly as shown)
- Enable Public Bucket: **Toggle ON ✓**
- Click **Create Bucket**

### 3. Add RLS Policy
- Go to **Policies** tab in the bucket
- Click **+ New Policy** → **For SELECT**
  - Target Roles: `anon`
  - USING: `true`
  - Save
- Click **+ New Policy** → **For INSERT, UPDATE**
  - Target Roles: `authenticated`
  - USING: `true`
  - WITH CHECK: `true`
  - Save

### 4. Done! 
Your bucket is ready. Upload works now.

---

## What Changed in Your App

### StorageService (`lib/services/storage_service.dart`)

**New Features:**
1. **Auto-discovers buckets** - Tries "public", then "uploads"
2. **Validates images** - Checks size (5MB), format (JPG/PNG/GIF)
3. **Better errors** - Shows specific messages (404, 403, 413, etc.)
4. **Detailed logging** - Tracks every upload step with `[ProfileUpload]` prefix

**New Return Type:**
```dart
// Instead of: Future<String?> uploadProfilePicture(...)
// Now returns:
Future<({String? url, String? error})> uploadProfilePicture(...)

// Usage:
final result = await StorageService().uploadProfilePicture(...);
if (result.url != null) {
  print('✓ Uploaded: ${result.url}');
} else {
  print('✗ Error: ${result.error}');
}
```

### ProfileScreen (`lib/screens/profile_screen.dart`)

**New Features:**
1. **Better error messages** - Shows what went wrong during upload
2. **Graceful degradation** - Bio saves even if image upload fails
3. **Clear feedback** - Different messages for success vs. partial success
4. **Longer error display** - 4-second duration for error SnackBars

**Example Flow:**
```
User picks image
    ↓
Validates: Size OK? Format OK? File exists?
    ↓
Auto-discovers bucket ("public" or "uploads")
    ↓
Uploads to discovered bucket
    ↓
Gets public CDN URL
    ↓
Updates database with URL
    ↓
Reloads profile
    ↓
Displays image from CDN
```

---

## How to Debug (If Still Not Working)

### Check 1: Does bucket exist?
```
Supabase Dashboard → Storage tab
Should see: [public] bucket listed
```

### Check 2: Is it public?
```
Storage → public bucket → Settings
Should see: "Public Bucket" toggle = ON
```

### Check 3: Check RLS policies
```
Storage → public bucket → Policies
Should see: At least one policy for anon or authenticated
```

### Check 4: Watch console logs
When uploading, you'll see:
```
[ProfileUpload] Starting profile picture upload...
[ProfileUpload] Image validated - Size: 2.45MB
[ProfileUpload] Testing bucket: "public"
[ProfileUpload] ✓ Bucket "public" is available
[ProfileUpload] Uploading to bucket: "public", path: profile_pictures/...
[ProfileUpload] ✓ File uploaded successfully
[ProfileUpload] ✓ Public URL generated: https://...
```

If you see ✗ instead of ✓, check the error message for next steps.

### Check 5: Test manually in Supabase
```
1. Go to Storage tab
2. Click [public] bucket
3. Click "Upload file"
4. Try uploading a small test image
5. If this works, app should work too
6. If this fails, bucket isn't configured correctly
```

---

## Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Bucket not found (404)` | No "public" bucket exists | Create bucket named "public" |
| `Permission denied (403)` | Bucket exists but not public | Toggle "Public Bucket" ON |
| `File too large (413)` | Image > 5MB | Compress image, max 5MB |
| `Invalid format` | JPG/PNG/GIF expected | Use JPG, PNG, or GIF file |
| `URL not generated` | Upload OK but URL failed | Check RLS policies |

---

## File Structure After Upload

```
Supabase Storage Bucket "public"
│
├── profile_pictures/
│   ├── b50bcdef-d22c-4d4a-b561-c53db7809232_1702170000000.jpg
│   └── (more user profile pictures...)
│
└── post_images/
    ├── b50bcdef-d22c-4d4a-b561-c53db7809232_1702175000000.jpg
    └── (more post images...)
```

**URL Format:**
```
https://YOUR-PROJECT.supabase.co/storage/v1/object/public/public/profile_pictures/USER_ID_TIMESTAMP.jpg
```

---

## Success Indicators

✅ **Setup Complete When:**
1. Bucket "public" visible in Storage tab
2. Public Bucket toggle is ON
3. RLS policies configured
4. No 404 errors in console
5. Upload logs show ✓ checkmarks
6. Image appears in profile after save

✅ **Everything Works When:**
1. Select image → preview shows locally
2. Click "Save Changes"
3. Console shows upload success
4. Page reloads with new image
5. Image loads fast from CDN
6. Logout/login → image still there

---

## Support

If still having issues:

1. **Check console logs** - Look for [ProfileUpload] messages
2. **Read error message** - Each error has specific cause
3. **Verify bucket config** - Supabase Storage tab
4. **Check RLS policies** - Must exist for public access
5. **Test with browser** - Go directly to public URL and check if image loads

The error message in your app is now **very specific** and will guide you to the exact problem!
