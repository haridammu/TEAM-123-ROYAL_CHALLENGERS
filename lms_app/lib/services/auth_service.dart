import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as local_user;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  String? _token;
  local_user.User? _currentUser;

  String? get token => _token;
  local_user.User? get currentUser => _currentUser;

  // Initialize Supabase - Should be called in main.dart
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://rygssvwlqwnzkarmihvd.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5Z3NzdndscXduemthcm1paHZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjAxNzIsImV4cCI6MjA4MDkzNjE3Mn0.XiXbLY8pldr_fMe0YLZ6Fq7syLyQP1LO-NWv2wfAeUA',
    );
  }

  // Helper method to extract error message from response
  String _extractErrorMessage(dynamic errorResponse) {
    if (errorResponse == null) return 'Unknown error occurred';

    if (errorResponse is String) {
      return errorResponse;
    }

    if (errorResponse is Map<String, dynamic>) {
      if (errorResponse.containsKey('message')) {
        return errorResponse['message'].toString();
      }
      if (errorResponse.containsKey('error')) {
        return errorResponse['error'].toString();
      }
      return errorResponse.toString();
    }

    return 'An error occurred';
  }

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
        },
      );

      if (response.user != null) {
        // Create user profile in users table
        await _client.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'username': username,
          'first_name': firstName,
          'last_name': lastName,
          'created_at': DateTime.now().toIso8601String(),
        });

        _token = response.session?.accessToken;
        _currentUser = local_user.User(
          id: response.user!.id,
          username: username,
          email: email,
          firstName: firstName,
          lastName: lastName,
          isVerified: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return {
          'success': true,
          'data': {'user': response.user, 'session': response.session},
        };
      } else {
        return {'success': false, 'error': 'Failed to create user'};
      }
    } catch (e) {
      return {'success': false, 'error': _extractErrorMessage(e.toString())};
    }
  }

  // Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Fetch user profile
        final profileResponse =
            await _client
                .from('users')
                .select()
                .eq('id', response.user!.id)
                .single();

        _token = response.session?.accessToken;
        _currentUser = local_user.User(
          id: response.user!.id,
          username: profileResponse['username'] ?? email.split('@')[0],
          email: response.user!.email ?? '',
          firstName: profileResponse['first_name'] ?? '',
          lastName: profileResponse['last_name'] ?? '',
          isVerified: profileResponse['is_verified'] ?? false,
          createdAt: DateTime.parse(
            profileResponse['created_at'] ?? DateTime.now().toIso8601String(),
          ),
          updatedAt: DateTime.parse(
            profileResponse['updated_at'] ?? DateTime.now().toIso8601String(),
          ),
        );

        return {
          'success': true,
          'data': {'user': response.user, 'session': response.session},
        };
      } else {
        return {'success': false, 'error': 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'error': _extractErrorMessage(e.toString())};
    }
  }

  // Google Sign-In using ID token
  Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
    required String email,
    required String firstName,
    required String lastName,
    String? photoUrl,
  }) async {
    try {
      // Validate required parameters
      if (idToken.isEmpty) {
        return {'success': false, 'error': 'ID Token is required'};
      }
      if (email.isEmpty) {
        return {'success': false, 'error': 'Email is required'};
      }

      // Sign in with ID token
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.user != null) {
        // Check if user already exists in users table
        try {
          final existingUser =
              await _client
                  .from('users')
                  .select()
                  .eq('id', response.user!.id)
                  .single();

          // User exists, update if needed
          if (photoUrl != null) {
            await _client
                .from('users')
                .update({'profile_picture_url': photoUrl})
                .eq('id', response.user!.id);
          }
        } catch (e) {
          // User doesn't exist, create new profile
          await _client.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'username': email.split('@')[0],
            'first_name': firstName,
            'last_name': lastName,
            'profile_picture_url': photoUrl,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        _token = response.session?.accessToken;
        _currentUser = local_user.User(
          id: response.user!.id,
          username: email.split('@')[0],
          email: email,
          firstName: firstName,
          lastName: lastName,
          isVerified: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return {
          'success': true,
          'data': {'user': response.user, 'session': response.session},
        };
      } else {
        return {'success': false, 'error': 'Failed to sign in with Google'};
      }
    } catch (e) {
      return {'success': false, 'error': _extractErrorMessage(e.toString())};
    }
  }

  // Alternative Google Sign-In with OAuth
  Future<Map<String, dynamic>> googleSignInWithOAuth() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterdemo://login-callback/',
      );

      // Listen for auth state changes
      _client.auth.onAuthStateChange.listen((data) {
        if (data.session?.user != null) {
          final user = data.session!.user;
          _token = data.session?.accessToken;
          _currentUser = local_user.User(
            id: user.id,
            username: user.email?.split('@')[0] ?? 'user',
            email: user.email ?? '',
            firstName: user.userMetadata?['first_name'] ?? '',
            lastName: user.userMetadata?['last_name'] ?? '',
            isVerified: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      });

      return {'success': true, 'provider': response};
    } catch (e) {
      return {'success': false, 'error': _extractErrorMessage(e.toString())};
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Logout error: $e');
    }

    _token = null;
    _currentUser = null;
  }

  // Get current user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final response =
          await _client.from('users').select().eq('id', user.id).single();

      _currentUser = local_user.User(
        id: user.id,
        username: response['username'] ?? user.email?.split('@')[0] ?? 'user',
        email: user.email ?? '',
        firstName: response['first_name'] ?? '',
        lastName: response['last_name'] ?? '',
        isVerified: response['is_verified'] ?? false,
        createdAt: DateTime.parse(
          response['created_at'] ?? DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          response['updated_at'] ?? DateTime.now().toIso8601String(),
        ),
      );

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': _extractErrorMessage(e.toString())};
    }
  }

  // Update user profile with file upload support
  Future<Map<String, dynamic>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    File? profilePicture,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final Map<String, dynamic> updateData = {};
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (phone != null) updateData['phone'] = phone;
      if (bio != null) updateData['bio'] = bio;

      // If profile picture provided, upload to storage first
      if (profilePicture != null) {
        final fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = 'profile_pictures/$fileName';

        await _client.storage
            .from('public')
            .upload(
              filePath,
              profilePicture,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        final publicUrl = _client.storage.from('public').getPublicUrl(filePath);

        updateData['profile_picture_url'] = publicUrl;
      }

      // Update user profile
      await _client.from('users').update(updateData).eq('id', user.id);

      // Fetch updated profile
      final response =
          await _client.from('users').select().eq('id', user.id).single();

      _currentUser = local_user.User(
        id: user.id,
        username: response['username'] ?? user.email?.split('@')[0] ?? 'user',
        email: user.email ?? '',
        firstName: response['first_name'] ?? '',
        lastName: response['last_name'] ?? '',
        isVerified: response['is_verified'] ?? false,
        createdAt: DateTime.parse(
          response['created_at'] ?? DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          response['updated_at'] ?? DateTime.now().toIso8601String(),
        ),
      );

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': _extractErrorMessage(e.toString())};
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  // Get current session
  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }
}
