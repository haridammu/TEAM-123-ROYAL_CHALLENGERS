import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';
import '../services/ai_course_service.dart';
import '../services/groq_service.dart';
import '../screens/course_reels_screen.dart'; 
import '../screens/code_editor_screen.dart'; // Added Import
import '../screens/quiz_screen.dart';
import '../utils/constants.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseTopic;

  const CourseDetailScreen({super.key, required this.courseTopic});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _currentModuleIndex = 0; // Track current module
  late AICourseService _aiCourseService;
  CourseContent? _courseContent;
  bool _isLoading = true;
  String _errorMessage = '';
  String _debugLog = '=== Course Detail Screen Debug Log ===\n';
  Map<String, YoutubePlayerController> _videoControllers = {};
  Map<String, bool> _videoLoadErrors = {}; // Track video loading errors
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    _logDebug('initState called');
    _initializeServices();
  }

  void _logDebug(String message) {
    final timestamp = DateTime.now().toIso8601String();
    setState(() {
      _debugLog += '[$timestamp] $message\n';
    });
    print('COURSE_DEBUG: [$timestamp] $message');
  }

  /// Retry video initialization for a specific video
  Future<void> _retryVideoInitialization(YouTubeVideoModel video) async {
    _logDebug('Retrying video initialization for: ${video.title}');

    // Clear the error state
    setState(() {
      _videoLoadErrors.remove(video.url);
    });

    try {
      // Create a new controller
      final controller = YoutubePlayerController(
        initialVideoId: video.id,
        flags: const YoutubePlayerFlags(
          mute: false,
          hideControls: false,
          // showFullscreenButton: true,
          // enableKeyboard: false, // Disable keyboard to reduce errors
          isLive: false,
        ),
      );

      // Store the controller immediately
      _videoControllers[video.url] = controller;

      // Force UI update
      setState(() {});

      _logDebug(
        'Video controller re-initialized successfully for: ${video.title}',
      );
    } on SocketException catch (e) {
      _logDebug(
        'Timeout re-initializing video controller for ${video.title}: $e',
      );
      setState(() {
        _videoLoadErrors[video.url] = true;
      });
    } catch (e, stackTrace) {
      _logDebug(
        'Error re-initializing video controller for ${video.title}: $e\nStack trace: $stackTrace',
      );

      // Check if this is a specific JavaScript error we've seen
      if (e.toString().contains('setSize') ||
          e.toString().contains('TypeError')) {
        _logDebug(
          'Detected known YouTube player JavaScript error for: ${video.title}',
        );
      }

      setState(() {
        _videoLoadErrors[video.url] = true;
      });
    }
  }

  /// Retry initialization for all videos with errors
  Future<void> _retryAllVideoInitializations() async {
    _logDebug('Retrying initialization for all videos with errors');

    // Get all videos with errors
    final videosWithErrors =
        _videoLoadErrors.keys
            .where((url) => _videoLoadErrors[url] == true)
            .map((url) {
              // Find the video model by URL
              for (final module in _courseContent?.modules ?? []) {
                for (final video in module.videos) {
                  if (video.url == url) {
                    return video;
                  }
                }
              }
              return null;
            })
            .whereType<YouTubeVideoModel>()
            .toList();

    // Retry each video
    for (final video in videosWithErrors) {
      await _retryVideoInitialization(video);
    }
  }

  void _initializeServices() {
    _logDebug('Starting service initialization');

    try {
      _logDebug(
        'Creating GroqService with API key: ${AppConstants.groqApiKey.substring(0, 5)}...',
      );
      final groqService = GroqService(apiKey: AppConstants.groqApiKey);
      _logDebug('GroqService created successfully');

      _logDebug('Creating AICourseService...');
      _aiCourseService = AICourseService(aiService: groqService);
      _logDebug('AICourseService created successfully');

      _servicesInitialized = true;
      _logDebug('All services initialized successfully');

      // Load content after a small delay to ensure UI updates
      Future.delayed(const Duration(milliseconds: 100), () {
        _loadCourseContent();
      });
    } catch (e, stackTrace) {
      final errorMsg =
          'Service initialization failed: $e\nStack trace: $stackTrace';
      _logDebug(errorMsg);
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourseContent() async {
    if (!_servicesInitialized) {
      _logDebug('Services not initialized, cannot load content');
      return;
    }

    _logDebug(
      'Starting course content loading for topic: ${widget.courseTopic}',
    );

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Add overall timeout to prevent indefinite hanging
      final content = await _aiCourseService
          .generateCourseContent(widget.courseTopic)
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              throw SocketException(
                'Course content generation timed out after 45 seconds',
              );
            },
          );
      _logDebug(
        'generateCourseContent completed, got ${content.modules.length} modules',
      );

      // Update UI immediately with course content, don't wait for videos
      _logDebug(
        'Updating UI with course content (videos will load in background)',
      );
      setState(() {
        _courseContent = content;
        // Keep loading state until videos are processed
      });

      // Process modules and load videos in background with timeout
      _logDebug('Processing ${content.modules.length} modules...');
      for (int i = 0; i < content.modules.length; i++) {
        final module = content.modules[i];
        _logDebug('Processing module ${i + 1}: ${module.title}');

        try {
          // SKIP API Call if videos already exist (e.g. from AI generation)
          if (module.videos.isNotEmpty) {
             _logDebug('Module "${module.title}" already has ${module.videos.length} videos (AI Generated). Skipping API search.');
             
             // Initialize controllers for existing videos
             for (final video in module.videos) {
                if (!_videoControllers.containsKey(video.url)) {
                   _retryVideoInitialization(video);
                }
             }
             continue;
          }

          _logDebug('Searching for videos for module: ${module.title}');
          // ENHANCED: Pass the main course topic as context for better filtering
          final videos = await _aiCourseService
              .searchRelevantVideos(
                module.title,
                courseContext: widget.courseTopic,
              )
              .timeout(
                const Duration(seconds: 15), // Reduced timeout
                onTimeout: () {
                  _logDebug(
                    'Video search timed out for module: ${module.title}',
                  );
                  return <YouTubeVideoModel>[];
                },
              );
          _logDebug(
            'Found ${videos.length} videos for module: ${module.title}',
          );

          // Update module videos
          module.videos.addAll(videos);

          // Initialize video controllers for each video (with error handling and timeout)
          for (final video in videos) {
            if (!_videoControllers.containsKey(video.url)) {
              try {
                _logDebug(
                  'Initializing video controller for: ${video.title} (${video.id})',
                );
                final controller = YoutubePlayerController(
                  initialVideoId: video.id,
                  flags: const YoutubePlayerFlags(
                    mute: false,
                    hideControls: false,
                    // showFullscreenButton: true,
                    // enableKeyboard: false, // Disable keyboard to reduce errors
                    isLive: false,
                  ),
                );
                _videoControllers[video.url] = controller;
                _logDebug(
                  'Video controller initialized successfully for: ${video.title}',
                );
              } on SocketException catch (e) {
                final errorMsg =
                    'Timeout initializing video controller for ${video.title}: $e';
                _logDebug('$errorMsg');
                setState(() {
                  _videoLoadErrors[video.url] = true;
                });
              } catch (e, stackTrace) {
                final errorMsg =
                    'Failed to initialize video controller for ${video.title}: $e';
                _logDebug('$errorMsg\nStack trace: $stackTrace');
                setState(() {
                  _videoLoadErrors[video.url] = true;
                });
              }
            }
          }

          // Update UI after each module is processed
          setState(() {
            // Trigger rebuild to show updated videos
          });
        } catch (e, stackTrace) {
          final errorMsg =
              'Error processing videos for module "${module.title}": $e';
          _logDebug('$errorMsg\nStack trace: $stackTrace');
        }
      }

      _logDebug('All modules processed, updating UI state');
      setState(() {
        _isLoading = false;
      });
      _logDebug('Course content loading completed successfully');
    } on SocketException catch (e) {
      final errorMsg = 'Course loading timed out: $e';
      _logDebug(errorMsg);
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false; // Ensure loading stops even on timeout
      });
    } catch (e, stackTrace) {
      final errorMsg =
          'Course content loading failed: $e\nStack trace: $stackTrace';
      _logDebug(errorMsg);
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false; // Ensure loading stops even on error
      });
    }
  }

  Future<void> _launchFinalQuiz() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Generating Final Exam...', 
              style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.none)
            ),
          ],
        ),
      ),
    );

    try {
      final quizQuestions = await _aiCourseService.generateFinalQuiz(widget.courseTopic);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              courseTitle: widget.courseTopic,
              questions: quizQuestions,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate quiz: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _logDebug('Disposing course detail screen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseTopic),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Add reels button to app bar
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CourseReelsScreen(
                        courseId:
                            widget
                                .courseTopic, // Use courseTopic as courseId for now
                        courseTitle: widget.courseTopic,
                      ),
                ),
              );
            },
            tooltip: 'View Course Reels',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show content immediately if we have it, even if videos are still loading
    if (_courseContent != null) {
      return _buildCourseContent();
    }

    if (_isLoading) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading course content...'),
              const SizedBox(height: 8),
              const Text('This may take a few moments'),
              const SizedBox(height: 16),
              // Show debug log during loading
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.8),
                ),
                child: Text(
                  _debugLog,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error Loading Course:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Show detailed error message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCourseContent,
                child: const Text('Retry Loading Content'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = '';
                    _debugLog = '=== Course Detail Screen Debug Log ===\n';
                  });
                  _initializeServices();
                },
                child: const Text('Reinitialize Services'),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(child: Text('No course content available'));
  }

  Widget _buildCourseContent() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCourseContent,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Overview (Only show on first module or separate tab? 
                    // Requirement: "each modeule needs to display in each sccren"
                    // Let's keep Overview at the top or maybe only on first screen?
                    // User request implies a flow. Let's show Overview only on first step, then modules.
                    // Or simply show course info header and then the current module.
                    
                    if (_currentModuleIndex == 0) ...[
                      _buildSectionHeader('Course Overview'),
                      _buildCourseOverview(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Learning Objectives'),
                      _buildLearningObjectives(),
                      const SizedBox(height: 24),
                    ],

                    // Current Module Display
                    _buildSectionHeader('Module ${_currentModuleIndex + 1} of ${_courseContent?.modules.length ?? 0}'),
                    _buildCurrentModule(),

                    const SizedBox(height: 24),
                    
                    // Show resources only on last slide? Or always?
                    if (_currentModuleIndex == (_courseContent?.modules.length ?? 0) - 1) ...[
                       _buildSectionHeader('Assessment Methods'),
                       Text(_courseContent?.assessmentMethods ?? 'Not specified'),
                       const SizedBox(height: 24),
                       _buildSectionHeader('Additional Resources'),
                       _buildAdditionalResources(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        // Navigation Bar
        _buildBottomNavigation(),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    final totalModules = _courseContent?.modules.length ?? 0;
    final isFirst = _currentModuleIndex == 0;
    final isLast = _currentModuleIndex == totalModules - 1;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: isFirst ? null : () {
              setState(() {
                if (_currentModuleIndex > 0) _currentModuleIndex--;
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFirst ? Colors.grey : null,
            ),
          ),
          Text(
            '${_currentModuleIndex + 1} / $totalModules',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
             onPressed: () async {
              final module = _courseContent?.modules[_currentModuleIndex];
              // DEBUG: Check for gamification
              print('GAMIFICATION DEBUG: Checking module ${_currentModuleIndex + 1}');
              print('GAMIFICATION DEBUG: Has Module? ${module != null}');
              print('GAMIFICATION DEBUG: Has Challenge? ${module?.challenge != null}');
              if (module?.challenge != null) {
                  print('GAMIFICATION DEBUG: Challenge Desc: ${module!.challenge!.description}');
              } else {
                  print('GAMIFICATION DEBUG: No challenge found for this module.');
              }

              // GAMIFICATION CHECK
              if (module != null && module.challenge != null) {
                 final result = await Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => CodeEditorScreen(
                       userId: 'user-id', // Should be real user ID
                       challenge: module.challenge,
                     ),
                   ),
                 );
                 
                 // If user didn't complete (back button), don't advance?
                 // User request: "after success completion of each module then the gamification nneds to happen"
                 // And "when theey run the code in output it should say succesful ... and navigate to next question"
                 // So we should strictly require success? 
                 // Let's assume result == true means success.
                 if (result != true) {
                    print('GAMIFICATION DEBUG: Challenge not completed (result=$result)');
                    return; 
                 }
                 print('GAMIFICATION DEBUG: Challenge completed successfully');
              }

              if (isLast) {
                _launchFinalQuiz();
              } else {
                setState(() {
                  if (_currentModuleIndex < totalModules - 1) _currentModuleIndex++;
                });
              }
            },
            icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
            label: Text(isLast ? 'Finish' : 'Next'),
             style: ElevatedButton.styleFrom(
              backgroundColor: isLast ? Colors.green : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCourseOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${_courseContent?.description ?? "N/A"}'),
            const SizedBox(height: 8),
            Text('Duration: ${_courseContent?.duration ?? "N/A"}'),
            const SizedBox(height: 8),
            Text('Skill Level: ${_courseContent?.skillLevel ?? "N/A"}'),
            const SizedBox(height: 8),
            Text('Prerequisites: ${_courseContent?.prerequisites ?? "N/A"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningObjectives() {
    final objectives = _courseContent?.learningObjectives ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              objectives.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('${entry.key + 1}. ${entry.value}'),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildCurrentModule() {
    final modules = _courseContent?.modules ?? [];
    if (modules.isEmpty || _currentModuleIndex >= modules.length) {
      return const Text('No module content available');
    }
    
    final module = modules[_currentModuleIndex];
    
    // Animate the switch
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Card(
        key: ValueKey<int>(_currentModuleIndex),
        margin: const EdgeInsets.all(8),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${module.title}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                module.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Estimated Time: ${module.estimatedTime}'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Topics covered:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...module.topics.map(
                (topic) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(topic)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (module.videos.isNotEmpty) ...[
                const Text(
                  'Recommended Videos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                ...module.videos.map((video) => _buildVideoItem(video)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoItem(YouTubeVideoModel video) {
    final controller = _videoControllers[video.url];
    final hasError = _videoLoadErrors[video.url] ?? false;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(video.description),
            const SizedBox(height: 8),
            if (hasError)
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      const Text('Video unavailable'),
                      const SizedBox(height: 4),
                      const Text(
                        'This video could not be loaded.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You can open it directly in YouTube or try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Retry video initialization
                          _retryVideoInitialization(video);
                        },
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _retryAllVideoInitializations,
                        child: const Text('Retry All Videos'),
                      ),
                    ],
                  ),
                ),
              )
            else if (controller != null)
              _buildSafeVideoPlayer(controller, video.url)
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Loading video player...'),
                      SizedBox(height: 4),
                      Text(
                        'This may take a few moments',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Safe wrapper for video player to handle potential errors
  Widget _buildSafeVideoPlayer(
    YoutubePlayerController controller,
    String videoUrl,
  ) {
    try {
      return Container(
        height: 200,
        child: YoutubePlayer(controller: controller),
      );
    } catch (e, stackTrace) {
      _logDebug('Video player error: $e\nStack trace: $stackTrace');
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              const Text('Video player error'),
              const SizedBox(height: 8),
              const Text(
                'Unable to load video player.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'This may be due to network issues or browser compatibility.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              // Fallback: Show a link to the YouTube video
              ElevatedButton(
                onPressed: () async {
                  // Open the YouTube video in external browser
                  final uri = Uri.parse(videoUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    _logDebug('Could not launch YouTube video: $videoUrl');
                    // Show a snackbar or dialog to inform the user
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open YouTube video'),
                      ),
                    );
                  }
                },
                child: const Text('Open in YouTube'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildAdditionalResources() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Textbooks:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...?_courseContent?.additionalResources.textbooks.map(
              (book) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('${book.title} by ${book.author}'),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Online Resources:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...?_courseContent?.additionalResources.onlineResources.map(
              (resource) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.name),
                    Text(
                      resource.url,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
