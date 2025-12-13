import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import
import '../models/course_reel_model.dart';
import '../services/supabase_service.dart';
import '../services/course_reels_service.dart'; // Add this import
import '../utils/constants.dart';

class CourseReelsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const CourseReelsScreen({
    Key? key,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  State<CourseReelsScreen> createState() => _CourseReelsScreenState();
}

class _CourseReelsScreenState extends State<CourseReelsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final PageController _pageController = PageController();
  final CourseReelsService _reelsService = CourseReelsService(); // Add this

  List<CourseReel> _reels = [];
  List<String> _availableLanguages = [
    'English',
    'Telugu',
    'Hindi',
    'Tamil',
    'Kannada',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
  ];
  String _selectedLanguage = 'English';
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _initialPopulationDone = false; // Add this flag
  String _errorMessage = '';
  Map<String, bool> _likedReels = {};
  Map<String, YoutubePlayerController?> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  /// ULTRA-STRICT Load reels for this course with enhanced error handling
  Future<void> _loadReels() async {
    try {
      print(
        '🔍 Loading reels for course: ${widget.courseTitle} in ${_selectedLanguage}',
      );
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get reels from database with enhanced filtering
      var reelsData = await _supabaseService.getCourseReels(
        courseId: widget.courseId,
        language: _selectedLanguage,
      );

      print('📊 Retrieved ${reelsData.length} raw reels from database');

      // If no reels found and we haven't tried to populate yet, do it now
      if (reelsData.isEmpty && !_initialPopulationDone) {
        print(
          '🔴 No reels found for ${widget.courseTitle} in ${_selectedLanguage}, attempting to populate...',
        );
        await _populateReelsIfNeeded();
        _initialPopulationDone = true;

        // Try loading again after population
        print('🔍 Reloading reels after population attempt');
        final retryReelsData = await _supabaseService.getCourseReels(
          courseId: widget.courseId,
          language: _selectedLanguage,
        );

        print('📊 Retrieved ${retryReelsData.length} reels after population');
        // Add the retry data to the original list
        reelsData.addAll(retryReelsData);
      }

      // Convert dynamic list to CourseReel list with ULTRA-STRICT validation
      final reels = <CourseReel>[];
      for (var data in reelsData) {
        try {
          final reelData = data as Map<String, dynamic>;

          // ULTRA-STRICT: Validate that the reel is actually for this course and language
          final reelCourseTitle = reelData['course_title'] as String? ?? '';
          final reelLanguage = reelData['language'] as String? ?? 'English';

          // Only include reels that match our current course and language EXACTLY
          if (reelCourseTitle.toLowerCase() ==
                  widget.courseTitle.toLowerCase() &&
              reelLanguage.toLowerCase() == _selectedLanguage.toLowerCase()) {
            reels.add(CourseReel.fromJson(reelData));
          } else {
            print(
              '🟡 Skipping reel for different course/language: ${reelCourseTitle} (${reelLanguage})',
            );
          }
        } catch (e) {
          print('❌ Error parsing reel data: $e');
        }
      }

      print('✅ Validated and filtered to ${reels.length} relevant reels');

      // Load user's liked reels
      final likedReelsIds = await _supabaseService.getUserLikedReels();
      final likedMap = <String, bool>{};
      for (var reelId in likedReelsIds) {
        likedMap[reelId] = true;
      }

      // Initialize controllers for each reel
      _controllers.clear();
      for (var reel in reels) {
        try {
          _controllers[reel.id] = YoutubePlayerController(
            initialVideoId: reel.videoId,
            flags: const YoutubePlayerFlags(
              mute: false,
              autoPlay: true,
              hideControls: true,
              disableDragSeek: true,
              loop: false,
              isLive: false,
              forceHD: false,
              enableCaption: false,
            ),
          );
        } catch (e) {
          print('Error initializing controller for reel ${reel.id}: $e');
          _controllers[reel.id] = null;
        }
      }

      setState(() {
        _reels = reels;
        _likedReels = likedMap;
        _isLoading = false;
      });

      print(
        '🎉 Successfully loaded ${reels.length} reels for ${widget.courseTitle}',
      );
    } catch (e, stackTrace) {
      print('❌ Error loading reels: $e');
      print('📝 Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load reels: $e';
        _isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reels: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(CourseReel reel) async {
    try {
      final isCurrentlyLiked = _likedReels[reel.id] ?? false;

      if (isCurrentlyLiked) {
        await _supabaseService.unlikeReel(reelId: reel.id);
        setState(() {
          _likedReels[reel.id] = false;
          // Update the reel's like count
          final index = _reels.indexWhere((r) => r.id == reel.id);
          if (index != -1) {
            _reels[index] = CourseReel(
              id: _reels[index].id,
              courseId: _reels[index].courseId,
              courseTitle: _reels[index].courseTitle,
              videoId: _reels[index].videoId,
              title: _reels[index].title,
              description: _reels[index].description,
              language: _reels[index].language,
              likes: _reels[index].likes > 0 ? _reels[index].likes - 1 : 0,
              createdAt: _reels[index].createdAt,
            );
          }
        });
      } else {
        await _supabaseService.likeReel(
          reelId: reel.id,
          courseId: reel.courseId,
          language: reel.language,
        );
        setState(() {
          _likedReels[reel.id] = true;
          // Update the reel's like count
          final index = _reels.indexWhere((r) => r.id == reel.id);
          if (index != -1) {
            _reels[index] = CourseReel(
              id: _reels[index].id,
              courseId: _reels[index].courseId,
              courseTitle: _reels[index].courseTitle,
              videoId: _reels[index].videoId,
              title: _reels[index].title,
              description: _reels[index].description,
              language: _reels[index].language,
              likes: _reels[index].likes + 1,
              createdAt: _reels[index].createdAt,
            );
          }
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update like: $e')));
    }
  }

  void _onLanguageChanged(String? newLanguage) {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
      });
      _loadReels();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _controllers.values.forEach((controller) {
      controller?.dispose();
    });
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.courseTitle} Reels'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Manual reel addition button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddReelDialog,
            tooltip: 'Add Manual Reel',
          ),
          // Language selector dropdown
          DropdownButton<String>(
            value: _selectedLanguage,
            items:
                _availableLanguages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
            onChanged: _onLanguageChanged,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadReels, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_reels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No reels available for this course and language',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _populateReelsIfNeeded,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _reels.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;

          // Pause all videos except the current one
          for (int i = 0; i < _reels.length; i++) {
            final controller = _controllers[_reels[i].id];
            if (controller != null) {
              if (i == index) {
                controller.play();
              } else {
                controller.pause();
              }
            }
          }
        });
      },
      itemBuilder: (context, index) {
        final reel = _reels[index];
        return _buildReelItem(reel);
      },
    );
  }

  Widget _buildReelItem(CourseReel reel) {
    final isLiked = _likedReels[reel.id] ?? false;
    final controller = _controllers[reel.id];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player or fallback
        _buildVideoPlayer(reel, controller),

        // Overlay UI
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title and description
                Text(
                  reel.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reel.description,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    // Like button
                    GestureDetector(
                      onTap: () => _toggleLike(reel),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${reel.likes}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Language tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reel.language,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // External link button
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_browser,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        final url =
                            'https://www.youtube.com/watch?v=${reel.videoId}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Progress indicator
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_reels.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      index == _currentIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(
    CourseReel reel,
    YoutubePlayerController? controller,
  ) {
    if (controller == null) {
      // Fallback UI when controller fails to initialize
      return Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final url = 'https://www.youtube.com/watch?v=${reel.videoId}';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
              child: const Text(
                'Open in YouTube',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }

    try {
      return YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: false,
        onEnded: (metaData) {
          // Auto-play next video when current one ends
          if (_currentIndex < _reels.length - 1) {
            _pageController.animateToPage(
              _currentIndex + 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
      );
    } catch (e) {
      print('Error building video player: $e');
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.white, size: 48),
        ),
      );
    }
  }

  /// ULTRA-STRICT Populate reels for this course if none exist
  /// This method ensures ONLY the EXACT course reels are populated
  Future<void> _populateReelsIfNeeded() async {
    try {
      print(
        '🔴 ULTRA-STRICT Attempting to populate reels for course: ${widget.courseTitle} in ${_selectedLanguage}',
      );

      // Call the populate method with enhanced retry logic
      int attempts = 0;
      bool success = false;

      while (attempts < 5 && !success) {
        // Increased to 5 attempts
        try {
          await _reelsService.populateCourseReels(
            courseId: widget.courseId,
            courseTitle: widget.courseTitle,
            language: _selectedLanguage,
          );
          success = true;
        } catch (e) {
          attempts++;
          print('🔴 Attempt $attempts failed: $e');
          if (attempts < 5) {
            // Exponential backoff
            await Future.delayed(Duration(seconds: 2 * attempts));
          }
        }
      }

      if (success) {
        print('✅ Reels populated successfully after $attempts attempt(s)');
      } else {
        print('❌ Failed to populate reels after 5 attempts');
        // Even if population failed, try to load whatever reels might exist
        await _loadReels();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to populate reels for this course. Showing existing content.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Reload reels after population
      await _loadReels();

      // Show success message
      if (mounted && _reels.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully loaded ${_reels.length} relevant reels for ${widget.courseTitle}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error populating reels: $e');
      // Show user-friendly error message but still try to load existing reels
      await _loadReels();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error occurred while loading reels. Showing available content.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Show dialog to add a manual reel
  void _showAddReelDialog() {
    final videoIdController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Manual Reel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: videoIdController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube Video ID',
                    hintText: 'Enter YouTube video ID',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter reel title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter reel description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (videoIdController.text.isNotEmpty &&
                    titleController.text.isNotEmpty) {
                  Navigator.of(context).pop();

                  try {
                    await _reelsService.addManualReel(
                      courseId: widget.courseId,
                      courseTitle: widget.courseTitle,
                      videoId: videoIdController.text.trim(),
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      language: _selectedLanguage,
                    );

                    // Refresh the reels list
                    await _loadReels();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reel added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add reel: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add Reel'),
            ),
          ],
        );
      },
    );
  }
}
