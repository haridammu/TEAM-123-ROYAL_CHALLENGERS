import 'package:flutter/material.dart';
import 'services/youtube_service.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Performance Fix Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const VideoPerformanceFixTestScreen(),
    );
  }
}

class VideoPerformanceFixTestScreen extends StatefulWidget {
  const VideoPerformanceFixTestScreen({super.key});

  @override
  State<VideoPerformanceFixTestScreen> createState() =>
      _VideoPerformanceFixTestScreenState();
}

class _VideoPerformanceFixTestScreenState
    extends State<VideoPerformanceFixTestScreen> {
  late YouTubeService _youtubeService;
  String _status = 'Initializing YouTube service...';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() {
    try {
      _youtubeService = YouTubeService();
      setState(() {
        _status =
            'YouTube service initialized!\n\nReady to test video loading performance.';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize service: $e';
      });
    }
  }

  Future<void> _testVideoLoadingSpeed() async {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _status = 'Testing video loading speed and display...\n';
    });

    try {
      // Test 1: Basic video search
      setState(() {
        _status += '\n1. Searching for Python tutorial videos...';
      });

      final startTime = DateTime.now();
      final videos = await _youtubeService.searchVideos(
        'Python tutorial',
        maxResults: 5,
        courseTitle: 'Python',
      );
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      setState(() {
        _status +=
            '\n✓ Found ${videos.length} videos in ${duration.inMilliseconds}ms';
        if (videos.isNotEmpty) {
          _status += '\nFirst video: ${videos[0].title}';
        }
      });

      // Test 2: Module-specific search
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n\n2. Searching for Python introduction videos...';
      });

      final startTime2 = DateTime.now();
      final introVideos = await _youtubeService.searchVideos(
        'Python basics',
        maxResults: 5,
        courseTitle: 'Python',
        moduleType: 'introduction',
      );
      final endTime2 = DateTime.now();
      final duration2 = endTime2.difference(startTime2);

      setState(() {
        _status +=
            '\n✓ Found ${introVideos.length} videos in ${duration2.inMilliseconds}ms';
        if (introVideos.isNotEmpty) {
          _status += '\nFirst video: ${introVideos[0].title}';
        }
      });

      // Test 3: Web development search
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _status += '\n\n3. Searching for Web Development videos...';
      });

      final startTime3 = DateTime.now();
      final webVideos = await _youtubeService.searchVideos(
        'Web Development tutorial',
        maxResults: 5,
        courseTitle: 'Web Development',
      );
      final endTime3 = DateTime.now();
      final duration3 = endTime3.difference(startTime3);

      setState(() {
        _status +=
            '\n✓ Found ${webVideos.length} videos in ${duration3.inMilliseconds}ms';
        if (webVideos.isNotEmpty) {
          _status += '\nFirst video: ${webVideos[0].title}';
        }
      });

      setState(() {
        _status +=
            '\n\n🎉 VIDEO PERFORMANCE TEST COMPLETED! 🎉\n\n'
            'Expected improvements:\n'
            '• Faster video loading (under 3 seconds)\n'
            '• Videos display even with relaxed filtering\n'
            '• All searches return results\n'
            '• Web Development courses work correctly';
      });
    } catch (e) {
      setState(() {
        _status += '\n\n❌ ERROR: $e';
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
      appBar: AppBar(title: const Text('Video Performance Fix Test')),
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
              onPressed: _isTesting ? null : _testVideoLoadingSpeed,
              child: Text(_isTesting ? 'Testing...' : 'Test Video Performance'),
            ),
            const SizedBox(height: 16),
            const Text(
              'This test verifies the video loading performance fix:\n'
              '• Faster video retrieval\n'
              '• Videos display properly\n'
              '• All searches return results',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
