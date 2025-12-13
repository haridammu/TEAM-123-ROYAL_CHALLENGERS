import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;

  const ProfileScreen({super.key, required this.authService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final result = await widget.authService.getUserProfile();
      if (result['success']) {
        setState(() {
          _user = widget.authService.currentUser;
          _bioController.text = _user?.bio ?? '';
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile: ${result['error']}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Update profile with profile image if selected
        final result = await widget.authService.updateUserProfile(
          bio: _bioController.text,
          profilePicture: _profileImage,
        );

        if (result['success']) {
          setState(() {
            _user = widget.authService.currentUser;
            _isEditing = false;
            _isLoading = false;
            _profileImage =
                null; // Clear the temporary image after successful upload
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update profile: ${result['error']}'),
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
        }
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _bioController.text = _user?.bio ?? '';
        _profileImage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.username ?? 'Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _toggleEdit,
          ),
        ],
      ),
      body:
          _isLoading && _user == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUserProfile,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      _buildProfileHeader(),

                      // Bio section
                      _buildBioSection(),

                      // User posts/certificates/resumes
                      _buildUserContent(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Row(
        children: [
          // Profile picture
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child:
                    _profileImage != null
                        ? CircleAvatar(
                          radius: 38,
                          backgroundImage: FileImage(_profileImage!),
                        )
                        : (_user?.profilePicture != null &&
                            _user!.profilePicture!.isNotEmpty)
                        ? CircleAvatar(
                          radius: 38,
                          backgroundImage: NetworkImage(_user!.profilePicture!),
                        )
                        : CircleAvatar(
                          radius: 38,
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          child: Text(
                            _user?.firstName?.isNotEmpty == true
                                ? _user?.firstName
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    'U'
                                : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.username ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_user?.email ?? ''}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tell us about yourself...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.length > 200) {
                    return 'Bio must be less than 200 characters';
                  }
                  return null;
                },
              ),
            )
          else
            Text(
              _user?.bio?.isNotEmpty == true ? _user!.bio! : 'No bio yet',
              style: const TextStyle(fontSize: 16),
            ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Save Changes'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Content',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateContentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid of user content (certificates, resumes, etc.)
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildContentCard(
                Icons.school,
                'Certificates',
                'View your certificates',
                () {
                  // Navigate to certificates screen
                  Navigator.pushNamed(
                    context,
                    '/certificates',
                    arguments: {
                      'userId': _user?.id ?? 1,
                      'token': widget.authService.token,
                    },
                  );
                },
              ),
              _buildContentCard(
                Icons.description,
                'Resumes',
                'Manage your resumes',
                () {
                  // Navigate to resumes screen
                },
              ),
              _buildContentCard(
                Icons.assignment,
                'Projects',
                'Your projects',
                () {
                  // Navigate to projects screen
                },
              ),
              _buildContentCard(
                Icons.badge,
                'Achievements',
                'Your achievements',
                () {
                  // Navigate to achievements screen
                  Navigator.pushNamed(
                    context,
                    '/achievements',
                    arguments: {
                      'userId': _user?.id ?? 1,
                      'token': widget.authService.token,
                    },
                  );
                },
              ),

              _buildContentCard(
                Icons.badge,
                'Achievements',
                'Your achievements',
                () {
                  // Navigate to achievements screen
                  Navigator.pushNamed(
                    context,
                    '/code-editor',
                    arguments: {
                      'userId': _user?.id ?? 1,
                      'token': widget.authService.token,
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // User posts section
          const Text(
            'My Posts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // In a real app, these would be fetched from the API
          _buildPostItem(
            'Just completed my Python certification! Feeling proud of this achievement.',
            '2 hours ago',
          ),
          const SizedBox(height: 10),
          _buildPostItem(
            'Working on a new machine learning project. Excited to share the results soon!',
            '1 day ago',
          ),
          const SizedBox(height: 10),
          _buildPostItem(
            'Uploaded my resume. Open to new opportunities in software development.',
            '3 days ago',
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(String content, String time) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border, size: 18),
                      onPressed: () {
                        // Like post
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined, size: 18),
                      onPressed: () {
                        // Comment on post
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateContentDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Create New Content',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Certificate'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to certificate creation screen
                  Navigator.pushNamed(
                    context,
                    '/certificates',
                    arguments: {
                      'userId': _user?.id ?? 1,
                      'token': widget.authService.token,
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Resume'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to resume creation screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('Project'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to project creation screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Post'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to post creation screen
                  Navigator.pushNamed(
                    context,
                    '/create-post',
                    arguments: {
                      'userId': _user?.id ?? 1,
                      'token': widget.authService.token,
                    },
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
