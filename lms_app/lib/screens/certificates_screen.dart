import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/social_service.dart';

class CertificatesScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const CertificatesScreen({super.key, required this.userId, this.token});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _certificates = [];
  File? _certificateImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock data - in a real app, this would come from an API
      setState(() {
        _certificates = [
          {
            'id': 1,
            'title': 'Python Programming Certificate',
            'issuer': 'Coursera',
            'issueDate': '2025-10-15',
            'expiryDate': '2028-10-15',
            'credentialId': 'PY2025ABC123',
          },
          {
            'id': 2,
            'title': 'Machine Learning Specialization',
            'issuer': 'edX',
            'issueDate': '2025-08-22',
            'expiryDate': '2028-08-22',
            'credentialId': 'ML2025XYZ789',
          },
          {
            'id': 3,
            'title': 'Cloud Computing Fundamentals',
            'issuer': 'Google Cloud',
            'issueDate': '2025-06-30',
            'expiryDate': '2028-06-30',
            'credentialId': 'CC2025GCP456',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading certificates: $e')),
        );
      }
    }
  }

  Future<void> _pickCertificateImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _certificateImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking certificate image: $e')),
        );
      }
    }
  }

  void _showAddCertificateDialog() {
    final titleController = TextEditingController();
    final issuerController = TextEditingController();
    final credentialIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Certificate'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Certificate Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: issuerController,
                      decoration: const InputDecoration(
                        labelText: 'Issuer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: credentialIdController,
                      decoration: const InputDecoration(
                        labelText: 'Credential ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                _certificateImage != null
                                    ? Image.file(
                                      _certificateImage!,
                                      fit: BoxFit.cover,
                                    )
                                    : const Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _pickCertificateImage,
                          child: const Text('Select Image'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Certificate would be added in a real implementation',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCertificateDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadCertificates,
                child:
                    _certificates.isEmpty
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No certificates yet',
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add your first certificate to showcase your skills',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _certificates.length,
                          itemBuilder: (context, index) {
                            final cert = _certificates[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.school,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cert['title'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                cert['issuer'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.calendar_today,
                                      'Issued',
                                      cert['issueDate'],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      Icons.event,
                                      'Expires',
                                      cert['expiryDate'],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      Icons.confirmation_number,
                                      'Credential ID',
                                      cert['credentialId'],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            // Share certificate
                                          },
                                          icon: const Icon(
                                            Icons.share,
                                            size: 16,
                                          ),
                                          label: const Text('Share'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            // View certificate details
                                          },
                                          icon: const Icon(
                                            Icons.visibility,
                                            size: 16,
                                          ),
                                          label: const Text('View'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCertificateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Certificate'),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }
}
