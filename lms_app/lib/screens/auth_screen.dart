import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _googleSignInAvailable = true;
  bool _isWebPlatform = false;

  // Google Sign-In instance
  late final GoogleSignIn _googleSignInInstance;

  // Controllers for form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Check if we're on web platform
    _isWebPlatform = identical(0, 0.0); // Simple check for web platform

    // Initialize Google Sign-In with error handling
    try {
      // For Android, use standard initialization
      // For web, we'll handle it differently or disable it based on preference
      if (_isWebPlatform) {
        // Based on memory preference, we should use Android client ID
        // For web, this might cause issues, so we'll disable it
        _googleSignInAvailable = false;
        print(
          'Google Sign-In disabled on web platform per Android client ID preference',
        );
      } else {
        // Android initialization
        _googleSignInInstance = GoogleSignIn(scopes: ['email', 'profile']);
      }
    } catch (e) {
      // Google Sign-In is not available on this platform
      _googleSignInAvailable = false;
      print('Google Sign-In not available: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isLogin) {
          // Login logic
          final result = await _authService.login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          if (result['success']) {
            // Navigate to dashboard with the AuthService instance
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/dashboard',
                arguments: {'authService': _authService},
              );
            }
          } else {
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['error'].toString())),
              );
            }
          }
        } else {
          // Registration logic
          final result = await _authService.register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );

          if (result['success']) {
            // Navigate to dashboard with the AuthService instance
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/dashboard',
                arguments: {'authService': _authService},
              );
            }
          } else {
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['error'].toString())),
              );
            }
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Actual Google Sign-In implementation with error handling
  void _performGoogleSignIn() async {
    if (!_googleSignInAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In is not available on this platform'),
          ),
        );
      }
      return;
    }

    // Don't allow Google Sign-In on web if using Android client ID preference
    if (_isWebPlatform) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google Sign-In not supported on web with Android client ID preference',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Sign out any previously signed in user
      await _googleSignInInstance.signOut();

      // Sign in with Google
      final GoogleSignInAccount? googleUser =
          await _googleSignInInstance.signIn();

      if (googleUser != null) {
        // Get authentication details
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Extract user details with better fallbacks
        final String email = googleUser.email;
        final String displayName = googleUser.displayName ?? '';
        final String photoUrl = googleUser.photoUrl ?? '';
        final String idToken = googleAuth.idToken ?? '';

        // Better name parsing with extensive fallbacks
        String firstName = '';
        String lastName = '';

        // Method 1: Parse from display name
        if (displayName.isNotEmpty) {
          final nameParts = displayName.split(' ');
          if (nameParts.length >= 2) {
            firstName = nameParts[0];
            lastName = nameParts.sublist(1).join(' ');
          } else {
            firstName = displayName;
            lastName =
                displayName; // Use display name for both if only one part
          }
        }

        // Method 2: Fallback to given name and family name from Google auth if available
        if (firstName.isEmpty || lastName.isEmpty) {
          // These might be available in the GoogleSignInAuthentication object
          // But since they're not directly exposed, we'll use email as fallback
          if (email.isNotEmpty) {
            final emailParts = email.split('@');
            final emailPrefix = emailParts[0];

            // If we still don't have names, use email prefix
            if (firstName.isEmpty) firstName = emailPrefix;
            if (lastName.isEmpty) lastName = emailPrefix;
          }
        }

        // Method 3: Ultimate fallback - use generic names
        if (firstName.isEmpty) firstName = 'User';
        if (lastName.isEmpty) lastName = 'Google';

        // Validate required fields
        if (email.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email is required but not provided by Google'),
              ),
            );
          }
          return;
        }

        if (idToken.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'ID Token is required but not provided by Google',
                ),
              ),
            );
          }
          return;
        }

        // Debug logging to see what we're sending
        print('Sending to backend:');
        print('  Email: $email');
        print('  First Name: $firstName');
        print('  Last Name: $lastName');
        print('  ID Token: $idToken');
        print('  Photo URL: $photoUrl');

        // Send the Google details to our backend
        final result = await _authService.googleSignIn(
          idToken: idToken,
          email: email,
          firstName: firstName,
          lastName: lastName,
          photoUrl: photoUrl.isEmpty ? null : photoUrl,
        );

        if (result['success']) {
          // Navigate to dashboard with the AuthService instance
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
              arguments: {'authService': _authService},
            );
          }
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sign-In failed: ${result['error'].toString()}'),
              ),
            );
          }
        }
      } else {
        // User canceled the sign in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-In canceled')),
          );
        }
      }
    } on PlatformException catch (e) {
      // Handle the specific error you're seeing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google Sign-In requires Android setup. Check console for details.',
            ),
          ),
        );

        // Show detailed error in console
        print('Google Sign-In Android setup required: $e');
        print('To fix this issue:');
        print('1. Add google-services.json to android/app/ directory');
        print(
          '2. Configure SHA-1 fingerprint in Firebase/Google Cloud Console',
        );
        print(
          '3. Make sure you have the correct package name in your configuration',
        );
      }
    } catch (e) {
      // Handle other errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or title
                Text(
                  'Learning Management System',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 30),

                // First Name field (only for signup)
                if (!_isLogin)
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),

                if (!_isLogin) const SizedBox(height: 16),

                // Last Name field (only for signup)
                if (!_isLogin)
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),

                if (!_isLogin) const SizedBox(height: 16),

                // Username field (only for signup)
                if (!_isLogin)
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),

                if (!_isLogin) const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                              _isLogin ? 'Login' : 'Sign Up',
                              style: const TextStyle(fontSize: 16),
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                // Google Sign In button (only show if available and not on web with Android preference)
                if (_googleSignInAvailable && !_isWebPlatform)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _performGoogleSignIn,
                      icon: const Icon(Icons.account_circle),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                if (_googleSignInAvailable && !_isWebPlatform)
                  const SizedBox(height: 24),

                // Toggle between login and signup
                TextButton(
                  onPressed: _isLoading ? null : _toggleAuthMode,
                  child: Text(
                    _isLogin
                        ? 'Don\'t have an account? Sign Up'
                        : 'Already have an account? Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
