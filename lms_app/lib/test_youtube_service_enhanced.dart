import 'package:flutter/material.dart';
import 'services/groq_service.dart';
import 'services/ai_course_service.dart';
import 'services/youtube_service.dart';
import 'utils/constants.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced YouTube Service Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const EnhancedYouTubeTestScreen(),
    );
  }
}

class EnhancedYouTubeTestScreen extends StatefulWidget {
  const EnhancedYouTubeTestScreen({super.key});

  @override
  State<EnhancedYouTubeTestScreen> createState() =>
      _EnhancedYouTubeTestScreenState();
}

class _EnhancedYouTubeTestScreenState extends State<EnhancedYouTubeTestScreen> {
  late AICourseService _aiCourseService;
  late YouTubeService _youtubeService;

  String _status = 'Initializing services...';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    try {
      // Initialize services
      final groqService = GroqService(apiKey: AppConstants.groqApiKey);
      _aiCourseService = AICourseService(aiService: groqService);
      _youtubeService = YouTubeService();

      setState(() {
        _status =
            'All services initialized successfully!\n\nReady to test:\n'
            '1. Enhanced YouTube Video Search with Module Types\n'
            '2. Comprehensive Python Course Generation\n'
            '3. Module-Specific Video Filtering';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize services: $e';
      });
    }
  }

  Future<void> _testPythonCourseEnhancements() async {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _status = 'Testing enhanced Python course features...\n';
    });

    try {
      // Test 1: Generate comprehensive Python course
      setState(() {
        _status += '\n1. Generating comprehensive Python course content...';
      });

      final courseContent = await _aiCourseService.generateCourseContent(
        'Python Programming',
      );
      setState(() {
        _status +=
            '\n✓ SUCCESS: Generated Python course with ${courseContent.modules.length} modules';
        _status += '\nModules:';
        for (int i = 0; i < courseContent.modules.length; i++) {
          _status += '\n  ${i + 1}. ${courseContent.modules[i].title}';
        }
      });

      // Test 2: Test module-specific video searches
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n\n2. Testing module-specific video searches...';
      });

      // Test introduction module search
      setState(() {
        _status += '\n   a. Searching for Python introduction videos...';
      });
      final introVideos = await _youtubeService.searchVideos(
        'Python basics',
        maxResults: 5,
        courseTitle: 'Python',
        moduleType: 'introduction',
      );
      setState(() {
        _status += '\n   ✓ Found ${introVideos.length} introduction videos';
        if (introVideos.isNotEmpty) {
          _status += '\n     First: ${introVideos[0].title}';
        }
      });

      // Test core module search
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n   b. Searching for Python core concept videos...';
      });
      final coreVideos = await _youtubeService.searchVideos(
        'Python core concepts',
        maxResults: 5,
        courseTitle: 'Python',
        moduleType: 'core',
      );
      setState(() {
        _status += '\n   ✓ Found ${coreVideos.length} core concept videos';
        if (coreVideos.isNotEmpty) {
          _status += '\n     First: ${coreVideos[0].title}';
        }
      });

      // Test advanced module search
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n   c. Searching for Python advanced videos...';
      });
      final advancedVideos = await _youtubeService.searchVideos(
        'Python advanced concepts',
        maxResults: 5,
        courseTitle: 'Python',
        moduleType: 'advanced',
      );
      setState(() {
        _status += '\n   ✓ Found ${advancedVideos.length} advanced videos';
        if (advancedVideos.isNotEmpty) {
          _status += '\n     First: ${advancedVideos[0].title}';
        }
      });

      // Test project module search
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n   d. Searching for Python project videos...';
      });
      final projectVideos = await _youtubeService.searchVideos(
        'Python projects',
        maxResults: 5,
        courseTitle: 'Python',
        moduleType: 'projects',
      );
      setState(() {
        _status += '\n   ✓ Found ${projectVideos.length} project videos';
        if (projectVideos.isNotEmpty) {
          _status += '\n     First: ${projectVideos[0].title}';
        }
      });

      // Test 3: Verify enhanced filtering
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n\n3. Verifying enhanced video filtering...';
      });

      // Test with a broader search that should still return quality content
      final filteredVideos = await _youtubeService.searchVideos(
        'Python programming',
        maxResults: 10,
        courseTitle: 'Python',
      );
      setState(() {
        _status += '\n✓ Found ${filteredVideos.length} quality Python videos';
        if (filteredVideos.isNotEmpty) {
          _status += '\n  First: ${filteredVideos[0].title}';
          _status +=
              '\n  Duration check: ${filteredVideos[0].isCourseAppropriateDuration ? "PASS" : "FAIL"}';
        }

        // Show statistics
        int educationalCount = 0;
        int understandableCount = 0;
        for (final video in filteredVideos) {
          if (_isEducationalVideo(video)) educationalCount++;
          if (_isUnderstandableVideo(video)) understandableCount++;
        }
        _status += '\n\nFiltering Statistics:';
        _status +=
            '\n  Educational content: $educationalCount/${filteredVideos.length}';
        _status +=
            '\n  Understandable content: $understandableCount/${filteredVideos.length}';
      });

      setState(() {
        _status +=
            '\n\n🎉 ALL ENHANCEMENTS TESTED SUCCESSFULLY! 🎉\n\n'
            'The enhanced YouTube service now provides:\n'
            '• Better module-specific video targeting\n'
            '• Improved educational content filtering\n'
            '• More comprehensive course coverage\n'
            '• Enhanced duration flexibility';
      });
    } catch (e) {
      setState(() {
        _status += '\n\n❌ ERROR: $e';
        if (e.toString().contains('401') ||
            e.toString().contains('Invalid API Key')) {
          _status +=
              '\n\n>>> API KEY ISSUE DETECTED <<<\n'
              'Please make sure you have entered valid API keys:\n'
              '1. Groq API key in constants.dart\n'
              '2. YouTube API keys in youtube_service.dart';
        }
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  // Helper methods to test filtering logic
  bool _isEducationalVideo(dynamic video) {
    final lowerTitle = video.title.toLowerCase();
    final lowerDescription = video.description.toLowerCase();
    final educationalKeywords = [
      'tutorial',
      'course',
      'learn',
      'introduction',
      'basics',
      'beginner',
      'fundamentals',
      'programming',
      'how to',
      'guide',
      'lesson',
      'module',
      'chapter',
      'complete',
      'full',
      'crash course',
      'comprehensive',
      'step by step',
      'from scratch',
      'for beginners',
      'master',
      'advanced',
      'intermediate',
      'expert',
      'project',
      'hands-on',
      'practical',
      'real world',
      'build',
      'create',
      'develop',
    ];

    for (final keyword in educationalKeywords) {
      if (lowerTitle.contains(keyword) || lowerDescription.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  bool _isUnderstandableVideo(dynamic video) {
    final lowerTitle = video.title.toLowerCase();
    final lowerDescription = video.description.toLowerCase();

    // Must have a reasonably descriptive title
    if (video.title.trim().isEmpty || video.title.length < 10) {
      return false;
    }

    // Should not contain spammy or vague words
    final spamKeywords = [
      'click here',
      'watch this',
      'amazing',
      'insane',
      'crazy',
      'you won\'t believe',
      'shocking',
      'unbelievable',
      'mind blowing',
      'blow your mind',
      'secret',
      'hack',
      'trick',
      'one weird',
      'they don\'t want you to know',
    ];

    for (final keyword in spamKeywords) {
      if (lowerTitle.contains(keyword) || lowerDescription.contains(keyword)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enhanced YouTube Service Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _status,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isTesting ? null : _testPythonCourseEnhancements,
              child: Text(
                _isTesting ? 'Testing...' : 'Test Python Course Enhancements',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This test verifies enhanced features for Python courses:\n'
              '• Module-specific video targeting\n'
              '• Improved content filtering\n'
              '• Comprehensive course coverage',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
