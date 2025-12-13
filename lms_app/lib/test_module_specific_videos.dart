import 'package:flutter/material.dart';
import 'services/youtube_service.dart';

class TestModuleSpecificVideos extends StatefulWidget {
  @override
  _TestModuleSpecificVideosState createState() =>
      _TestModuleSpecificVideosState();
}

class _TestModuleSpecificVideosState extends State<TestModuleSpecificVideos> {
  final YouTubeService _youtubeService = YouTubeService();
  String _status = 'Ready to test module-specific video loading...';
  bool _isRunning = false;

  Future<void> _runTest() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _status = 'Starting module-specific video loading test...\n';
    });

    try {
      // Test with Web Development as an example course
      final courseTitle = 'Web Development';

      setState(() {
        _status += '\n1. Testing Introduction Module...';
      });

      // Test introduction module
      final introVideos = await _youtubeService.searchVideos(
        '$courseTitle basics',
        maxResults: 5,
        courseTitle: courseTitle,
        moduleType: 'introduction',
      );

      setState(() {
        _status += '\n   Found ${introVideos.length} videos';
        if (introVideos.isNotEmpty) {
          _status += '\n   First video: ${introVideos[0].title}';
        }
      });

      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _status += '\n\n2. Testing Core Module...';
      });

      // Test core module
      final coreVideos = await _youtubeService.searchVideos(
        '$courseTitle core concepts',
        maxResults: 5,
        courseTitle: courseTitle,
        moduleType: 'core',
      );

      setState(() {
        _status += '\n   Found ${coreVideos.length} videos';
        if (coreVideos.isNotEmpty) {
          _status += '\n   First video: ${coreVideos[0].title}';
        }
      });

      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _status += '\n\n3. Testing Advanced Module...';
      });

      // Test advanced module
      final advancedVideos = await _youtubeService.searchVideos(
        '$courseTitle advanced concepts',
        maxResults: 5,
        courseTitle: courseTitle,
        moduleType: 'advanced',
      );

      setState(() {
        _status += '\n   Found ${advancedVideos.length} videos';
        if (advancedVideos.isNotEmpty) {
          _status += '\n   First video: ${advancedVideos[0].title}';
        }
      });

      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _status += '\n\n4. Testing Projects Module...';
      });

      // Test projects module
      final projectVideos = await _youtubeService.searchVideos(
        '$courseTitle projects',
        maxResults: 5,
        courseTitle: courseTitle,
        moduleType: 'projects',
      );

      setState(() {
        _status += '\n   Found ${projectVideos.length} videos';
        if (projectVideos.isNotEmpty) {
          _status += '\n   First video: ${projectVideos[0].title}';
        }
      });

      setState(() {
        _status += '\n\n✅ TEST COMPLETED!';
        _status += '\n\nExpected results:';
        _status += '\n- Each module should load different, relevant videos';
        _status += '\n- Introduction: HTML/CSS/JS basics';
        _status += '\n- Core: Frameworks and libraries';
        _status += '\n- Advanced: Performance, security, architecture';
        _status += '\n- Projects: Hands-on applications';
      });
    } catch (e) {
      setState(() {
        _status += '\n\n❌ ERROR: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Module-Specific Video Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runTest,
              child: Text(_isRunning ? 'Testing...' : 'Run Test'),
            ),
            SizedBox(height: 20),
            Text(
              'Test Results:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(child: SingleChildScrollView(child: Text(_status))),
          ],
        ),
      ),
    );
  }
}
