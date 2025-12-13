# Supabase Migration Guide for LMS Application

This guide outlines the steps to migrate the LMS application from Django backend to Supabase.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Supabase Project Setup](#supabase-project-setup)
3. [Database Schema](#database-schema)
4. [Authentication Providers](#authentication-providers)
5. [Row Level Security (RLS)](#row-level-security-rls)
6. [Flutter Integration](#flutter-integration)
7. [Testing](#testing)
8. [Django Removal](#django-removal)

## Prerequisites

1. Create a Supabase account at [https://supabase.com](https://supabase.com)
2. Install Supabase CLI: `npm install -g supabase`
3. Install Flutter dependencies: `flutter pub add supabase_flutter`

## Supabase Project Setup

1. Create a new Supabase project in the Supabase dashboard
2. Note your Project URL and anon/public keys
3. Update `lib/main.dart` with your Supabase credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_PROJECT_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

## Database Schema

The complete database schema is defined in `supabase_setup.sql`. To apply it:

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `supabase_setup.sql`
4. Run the script

The schema includes tables for:
- Users and profiles
- Social features (posts, followers, comments, likes)
- Courses, modules, and lessons
- Quizzes and assessments
- Chat functionality
- Payments and subscriptions
- Certificates and achievements

## Authentication Providers

Enable authentication providers in your Supabase dashboard:

1. Go to Authentication > Settings
2. Enable Email authentication
3. For Google Sign-In:
   - Create OAuth credentials in Google Cloud Console
   - Add your credentials to Supabase Authentication settings
   - Update redirect URLs to match your app's callback URLs

## Row Level Security (RLS)

RLS policies are included in the SQL setup script. They ensure:
- Users can only access their own data
- Public read access where appropriate
- Proper authorization for data modifications

## Flutter Integration

The Flutter app has been updated to use Supabase services:

1. All services now use `SupabaseService` instead of direct HTTP calls
2. Authentication is handled through Supabase Auth
3. Data operations use Supabase Database client

Key service files:
- `lib/services/supabase_service.dart` - Core Supabase integration
- `lib/services/auth_service.dart` - Authentication
- `lib/services/social_service.dart` - Social features
- `lib/services/course_service.dart` - Course management
- `lib/services/quiz_service.dart` - Quiz functionality
- `lib/services/chat_service.dart` - Chat features
- `lib/services/payment_service.dart` - Payments and subscriptions

## Testing

1. Run the Flutter app: `flutter run`
2. Test authentication flows
3. Verify data creation and retrieval
4. Check real-time features (if implemented)

## Django Removal

Once all functionality is verified with Supabase:

1. Remove Django apps from the project:
   ```bash
   rm -rf authentication courses quizzes chat social payments analytics code_execution
   ```
2. Remove Django dependencies from `requirements.txt`
3. Remove Django settings from `Lms/settings.py`
4. Remove Django URLs from `Lms/urls.py`
5. Clean up any remaining Django references

## Troubleshooting

Common issues and solutions:

1. **Authentication errors**: Verify your Supabase credentials and auth provider settings
2. **Permission denied**: Check RLS policies and user roles
3. **Data not loading**: Verify table schemas match your model expectations
4. **Real-time not working**: Ensure you've enabled Realtime in Supabase dashboard

## Next Steps

1. Implement real-time features using Supabase Realtime
2. Add file storage for user uploads using Supabase Storage
3. Set up custom SMTP for email notifications
4. Configure custom domain for your Supabase project
5. Set up monitoring and logging