import 'package:flutter/material.dart';
import 'services/youtube_service.dart';

void main() {
  runApp(MaterialApp(home: TestModuleFixSimple()));
}

class TestModuleFixSimple extends StatefulWidget {
  @override
  _TestModuleFixSimpleState createState() => _TestModuleFixSimpleState();
}

class _TestModuleFixSimpleState extends State<TestModuleFixSimple> {
  final YouTubeService _youtubeService = YouTubeService();
  String _result = '';
  bool _isLoading = false;

  Future<void> _testModuleVideos() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing module-specific video loading...\n';
    });

    try {
      // Test with a web development course
      final courseTitle = 'Web Development';

      // Test introduction module
      final introVideos = await _youtubeService.searchVideos(
        '$courseTitle basics',
        maxResults: 3,
        courseTitle: courseTitle,
        moduleType: 'introduction',
      );

      // Test core module
      final coreVideos = await _youtubeService.searchVideos(
        '$courseTitle core concepts',
        maxResults: 3,
        courseTitle: courseTitle,
        moduleType: 'core',
      );

      // Compare if we got different videos
      bool hasDifferentVideos = false;
      if (introVideos.isNotEmpty && coreVideos.isNotEmpty) {
        // Check if first videos are different
        if (introVideos[0].id != coreVideos[0].id) {
          hasDifferentVideos = true;
        }
      }

      setState(() {
        _result += 'Introduction videos: ${introVideos.length}\n';
        if (introVideos.isNotEmpty) {
          _result += '  First: ${introVideos[0].title}\n';
        }

        _result += 'Core videos: ${coreVideos.length}\n';
        if (coreVideos.isNotEmpty) {
          _result += '  First: ${coreVideos[0].title}\n';
        }

        _result += '\nDifferent videos loaded: $hasDifferentVideos\n';
        _result +=
            hasDifferentVideos
                ? '✅ SUCCESS: Modules load different videos!\n'
                : '⚠️  WARNING: May be loading same videos\n';
      });
    } catch (e) {
      setState(() {
        _result += 'Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Module Fix Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testModuleVideos,
              child: Text(_isLoading ? 'Testing...' : 'Test Module Videos'),
            ),
            SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: Text(_result))),
          ],
        ),
      ),
    );
  }
}
