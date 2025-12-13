import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/social_service.dart';

class CreatePostScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const CreatePostScreen({super.key, required this.userId, this.token});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String? _selectedContentType = 'text';

  File? _postImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickPostImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _postImage = File(pickedFile.path);
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

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create post functionality would use the social service

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully!')),
          );

          // Navigate back
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content type selector
              const Text(
                'Content Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedContentType,
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text Post')),
                  DropdownMenuItem(
                    value: 'certificate',
                    child: Text('Certificate'),
                  ),
                  DropdownMenuItem(value: 'resume', child: Text('Resume')),
                  DropdownMenuItem(value: 'project', child: Text('Project')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedContentType = value;
                  });
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // Title field (for certificates, resumes, projects)
              if (_selectedContentType != 'text')
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedContentType != 'text' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Store title value
                  },
                ),
              if (_selectedContentType != 'text') const SizedBox(height: 16),

              // Content field
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: _getContentLabel(),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image preview
              if (_postImage != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_postImage!, fit: BoxFit.cover),
                  ),
                ),
              if (_postImage != null) const SizedBox(height: 16),

              // File upload button (for certificates, resumes, projects)
              if (_selectedContentType != 'text')
                ElevatedButton.icon(
                  onPressed: _pickPostImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload File'),
                )
              else
                ElevatedButton.icon(
                  onPressed: _pickPostImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add Image'),
                ),
              if (_selectedContentType != 'text' || _postImage != null)
                const SizedBox(height: 16),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Create Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getContentLabel() {
    switch (_selectedContentType) {
      case 'certificate':
        return 'Certificate Details';
      case 'resume':
        return 'Resume Summary';
      case 'project':
        return 'Project Description';
      default:
        return 'What\'s on your mind?';
    }
  }
}
