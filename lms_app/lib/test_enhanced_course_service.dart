import 'package:flutter/material.dart';
import 'services/groq_service.dart';
import 'services/ai_course_service.dart';
import 'services/youtube_service.dart';
import 'services/web_scraper_service.dart';
import 'utils/constants.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Course Service Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const EnhancedCourseTestScreen(),
    );
  }
}

class EnhancedCourseTestScreen extends StatefulWidget {
  const EnhancedCourseTestScreen({super.key});

  @override
  State<EnhancedCourseTestScreen> createState() =>
      _EnhancedCourseTestScreenState();
}

class _EnhancedCourseTestScreenState extends State<EnhancedCourseTestScreen> {
  late AICourseService _aiCourseService;
  late YouTubeService _youtubeService;
  late WebScraperService _webScraperService;

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
      _webScraperService = WebScraperService();

      setState(() {
        _status =
            'All services initialized successfully!\n\nReady to test:\n'
            '1. AI Course Generation\n'
            '2. YouTube Video Search\n'
            '3. Web Resource Scraping';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize services: $e';
      });
    }
  }

  Future<void> _testAllServices() async {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _status = 'Testing all services...\n';
    });

    try {
      // Test 1: AI Course Generation
      setState(() {
        _status +=
            '\n1. Generating AI course content for "Python Programming"...';
      });

      final courseContent = await _aiCourseService.generateCourseContent(
        'Python Programming',
      );
      setState(() {
        _status +=
            '\n✓ SUCCESS: Generated course with ${courseContent.modules.length} modules';
      });

      // Test 2: YouTube Video Search
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n\n2. Searching for YouTube videos on "Python basics"...';
      });

      final videos = await _aiCourseService.searchRelevantVideos(
        'Python basics',
      );
      setState(() {
        _status += '\n✓ SUCCESS: Found ${videos.length} videos';
        if (videos.isNotEmpty) {
          _status += '\n  First video: ${videos[0].title}';
        }
      });

      // Test 3: Web Resource Scraping
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n\n3. Scraping educational resources for "Python"...';
      });

      final resources = await _aiCourseService.generateSupplementaryMaterials(
        'Python',
      );
      setState(() {
        _status +=
            '\n✓ SUCCESS: Found ${resources.textbooks.length} textbooks and '
            '${resources.onlineResources.length} online resources';
      });

      setState(() {
        _status +=
            '\n\n🎉 ALL TESTS PASSED! 🎉\n\n'
            'The enhanced AI course system is working correctly.';
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
      appBar: AppBar(title: const Text('Enhanced Course Service Test')),
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
              onPressed: _isTesting ? null : _testAllServices,
              child: Text(_isTesting ? 'Testing...' : 'Test All Services'),
            ),
            const SizedBox(height: 16),
            const Text(
              'This test verifies:\n'
              '• AI course generation\n'
              '• YouTube video search\n'
              '• Web resource scraping',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
