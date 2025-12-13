import 'services/youtube_service.dart';

void main() async {
  final youtubeService = YouTubeService();
  final courseTitle = 'Web Development';
  
  final modules = [
    {'title': 'Introduction to Web Development', 'type': 'introduction'},
    {'title': 'Web Development Fundamentals', 'type': 'introduction'}, // Maps to same type
    {'title': 'Intermediate Web Development', 'type': 'core'},
    {'title': 'Advanced Web Development', 'type': 'advanced'},
    {'title': 'Web Development Projects', 'type': 'projects'},
  ];

  print('=== Reproducing Video Search Issue ===');

  for (final module in modules) {
    print('\n--- Module: ${module['title']} (Type: ${module['type']}) ---');
    
    // Simulate what AICourseService does
    try {
      final videos = await youtubeService.searchVideos(
        module['title']!,
        courseTitle: courseTitle,
        moduleType: module['type'],
        maxResults: 5
      );
      
      print('Found ${videos.length} videos:');
      for (final video in videos) {
        print('- ${video.title} (ID: ${video.id})');
      }
      
      if (videos.isEmpty) {
        print('WARNING: No videos found!');
      }
    } catch (e) {
      print('ERROR: $e');
    }
  }
}
