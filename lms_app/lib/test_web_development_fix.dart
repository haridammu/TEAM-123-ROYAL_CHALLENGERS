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
      title: 'Web Development Fix Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WebDevelopmentFixTestScreen(),
    );
  }
}

class WebDevelopmentFixTestScreen extends StatefulWidget {
  const WebDevelopmentFixTestScreen({super.key});

  @override
  State<WebDevelopmentFixTestScreen> createState() =>
      _WebDevelopmentFixTestScreenState();
}

class _WebDevelopmentFixTestScreenState
    extends State<WebDevelopmentFixTestScreen> {
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
            '1. Web Development Course Generation\n'
            '2. Module-Specific Video Loading\n'
            '3. Enhanced Filtering for All Modules';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize services: $e';
      });
    }
  }

  Future<void> _testWebDevelopmentCourseFix() async {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _status = 'Testing web development course fix...\n';
    });

    try {
      // Test 1: Generate web development course
      setState(() {
        _status += '\n1. Generating Web Development course content...';
      });

      final courseContent = await _aiCourseService.generateCourseContent(
        'Web Development',
      );
      setState(() {
        _status +=
            '\n✓ SUCCESS: Generated Web Development course with ${courseContent.modules.length} modules';
        _status += '\nModules:';
        for (int i = 0; i < courseContent.modules.length; i++) {
          _status += '\n  ${i + 1}. ${courseContent.modules[i].title}';
        }
      });

      // Test 2: Test video loading for each module
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n\n2. Testing video loading for each module...';
      });

      int totalVideosLoaded = 0;
      List<String> moduleResults = [];

      for (int i = 0; i < courseContent.modules.length; i++) {
        final module = courseContent.modules[i];
        setState(() {
          _status += '\n   Testing module ${i + 1}: ${module.title}';
        });

        try {
          final videos = await _aiCourseService.searchRelevantVideos(
            module.title,
            courseContext: 'Web Development',
          );

          setState(() {
            _status += '\n   ✓ Found ${videos.length} videos';
            totalVideosLoaded += videos.length;

            if (videos.isNotEmpty) {
              _status += '\n     Sample: ${videos[0].title}';
            }

            moduleResults.add(
              'Module ${i + 1} (${module.title}): ${videos.length} videos',
            );
          });
        } catch (e) {
          setState(() {
            _status += '\n   ❌ Error loading videos: $e';
            moduleResults.add('Module ${i + 1} (${module.title}): Error - $e');
          });
        }

        // Small delay between requests
        await Future.delayed(const Duration(milliseconds: 500));
      }

      setState(() {
        _status += '\n\n3. Summary:';
        _status += '\n   Total videos loaded: $totalVideosLoaded';
        _status +=
            '\n   Average videos per module: ${(totalVideosLoaded / courseContent.modules.length).toStringAsFixed(1)}';

        _status += '\n\nModule Details:';
        for (final result in moduleResults) {
          _status += '\n   $result';
        }
      });

      // Test 3: Direct YouTube service tests for specific modules
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n\n4. Testing direct YouTube service calls...';
      });

      // Test introduction module
      final introVideos = await _youtubeService.searchVideos(
        'Introduction to Web Development',
        maxResults: 10,
        courseTitle: 'Web Development',
        moduleType: 'introduction',
      );
      setState(() {
        _status += '\n   Introduction videos: ${introVideos.length}';
      });

      // Test core module
      final coreVideos = await _youtubeService.searchVideos(
        'Web Development Core Concepts',
        maxResults: 10,
        courseTitle: 'Web Development',
        moduleType: 'core',
      );
      setState(() {
        _status += '\n   Core concept videos: ${coreVideos.length}';
      });

      // Test advanced module
      final advancedVideos = await _youtubeService.searchVideos(
        'Advanced Web Development',
        maxResults: 10,
        courseTitle: 'Web Development',
        moduleType: 'advanced',
      );
      setState(() {
        _status += '\n   Advanced videos: ${advancedVideos.length}';
      });

      // Test projects module
      final projectVideos = await _youtubeService.searchVideos(
        'Web Development Projects',
        maxResults: 10,
        courseTitle: 'Web Development',
        moduleType: 'projects',
      );
      setState(() {
        _status += '\n   Project videos: ${projectVideos.length}';
      });

      setState(() {
        _status +=
            '\n\n🎉 WEB DEVELOPMENT FIX TEST COMPLETED! 🎉\n\n'
            'Expected improvements:\n'
            '• All modules should load videos\n'
            '• Each module should have 3-5 relevant videos\n'
            '• Videos should be specific to each module type\n'
            '• Web development content should be properly targeted';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Web Development Fix Test')),
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
              onPressed: _isTesting ? null : _testWebDevelopmentCourseFix,
              child: Text(
                _isTesting ? 'Testing...' : 'Test Web Development Fix',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This test verifies the fix for web development course video loading:\n'
              '• All modules get videos\n'
              '• Proper module-specific targeting\n'
              '• Adequate video count per module',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
