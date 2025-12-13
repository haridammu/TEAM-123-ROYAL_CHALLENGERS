# Supabase Setup Instructions

## Prerequisites

1. Create a Supabase account at https://supabase.com/
2. Create a new Supabase project

## Step 1: Get Your Supabase Credentials

1. Go to your Supabase project dashboard
2. Click on "Project Settings" (gear icon)
3. Go to "API" tab
4. Copy your:
   - Project URL (starts with https://)
   - anon key (public key)

## Step 2: Update Configuration

Open `lms_app/lib/services/supabase_auth_service.dart` and replace the placeholder values:

```dart
static Future<void> initialize() async {
  await Supabase.initialize(
    url: 'https://your-project.supabase.co', // Replace with your actual Supabase URL
    anonKey: 'your-anon-key-here', // Replace with your actual Supabase anon key
  );
}
```

## Step 3: Run Database Setup

1. Go to your Supabase project dashboard
2. Click on "SQL Editor" in the left sidebar
3. Copy the contents of `supabase_setup.sql` from this project
4. Paste it into the SQL editor and click "Run"

## Step 4: Configure Authentication

### Email/Password Authentication
1. Go to "Authentication" > "Providers" in your Supabase dashboard
2. Enable "Email" provider

### Google Sign-In (Optional)
1. Go to "Authentication" > "Providers" in your Supabase dashboard
2. Enable "Google" provider
3. Add your Google OAuth client IDs:
   - For Android: Add your SHA-1 fingerprint and package name
   - For iOS: Add your bundle identifier
   - For Web: Add your authorized domains

## Step 5: Test the Application

1. Run the Flutter app:
   ```
   cd lms_app
   flutter pub get
   flutter run
   ```

2. Try registering or signing in with email/password
3. Try Google Sign-In (if configured)

## Troubleshooting

### "Network error: FormatException: Unexpected end of input"
This usually means:
1. Incorrect Supabase URL or anon key
2. Network connectivity issues
3. Supabase project not properly set up

### "provider_disabled" Error
This means the authentication provider is not enabled in Supabase:
1. Go to "Authentication" > "Providers"
2. Enable the required provider (Email, Google, etc.)

### "Unexpected failure" During Registration
This usually indicates:
1. Database tables not created properly
2. Run the SQL setup script again
3. Check that all RLS policies are applied

## Additional Notes

- The application uses Row Level Security (RLS) policies to protect data
- User profiles are automatically created when users sign up
- All timestamps are stored in UTC