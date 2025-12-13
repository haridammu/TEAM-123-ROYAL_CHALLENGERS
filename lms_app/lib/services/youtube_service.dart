import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class YouTubeService {
  // List of API keys for rotation
  final List<String> _apiKeys = [
    'AIzaSyDJSU4CNx56jPHYyVrpU32PwAeL8B60H20', // Primary Key
    // Add backup keys here
    'AIzaSyBufkdIYyqM9wLF2RewyU9xbfKFt1hM1CU', 
    'AIzaSyCm4_YHY-bc8eM_J4KHygSr9EMqu1lcDXE',
    'AIzaSyCm4_YHY-bc8eM_J4KHygSr9EMqu1lcDXE',
  ];
  
  int _currentKeyIndex = 0; // Track active key

  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  static const int _timeoutSeconds = 15;

  YouTubeService() {
    if (_apiKeys.isEmpty) {
      print('🔴 WARNING: No YouTube API keys configured!');
    }
  }

  /// Execute an API call with automatic key rotation on quota errors
  Future<T> _executeWithRetry<T>(Future<T> Function(String apiKey) operation) async {
    int attempts = 0;
    while (attempts < _apiKeys.length) {
      try {
        final apiKey = _apiKeys[_currentKeyIndex];
        return await operation(apiKey);
      } catch (e) {
        final strError = e.toString().toLowerCase();
        // Check for Quota Exceeded (403) or manual "Quota" exception
        if (strError.contains('quota') || strError.contains('403')) {
          print('YOUTUBE_SERVICE: ⚠️ Key index $_currentKeyIndex quota exceeded. Switching keys...');
          // Rotate to next key
          _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
          attempts++;
          
          if (attempts >= _apiKeys.length) {
             print('YOUTUBE_SERVICE: 🔴 All API keys exhausted!');
             rethrow;
          }
        } else {
          // Other errors (network, parsing) -> fail normally
          rethrow;
        }
      }
    }
    throw Exception('All YouTube API keys exhausted');
  }

  /// Enhanced search for videos with better filtering
  /// Now supports comprehensive course module coverage from basic to advanced levels
  Future<List<YouTubeVideo>> searchVideos(
    String query, {
    int maxResults = 10,
    String? language,
    String? courseTitle,
    String? moduleType, // Added to support module-specific searches
  }) async {
    print('YOUTUBE_SERVICE: Searching for videos: $query');
    print('YOUTUBE_SERVICE: Module type: $moduleType');

    try {
      // Enhanced query - search for high-quality educational content with module-specific targeting
      String searchQuery = query;
      if (courseTitle != null) {
        // Create more targeted queries based on module type
        // WE MUST INCLUDE THE QUERY (MODULE TITLE) to get specific results
        // pattern: "$courseTitle $query tutorial"
        
        // Clean up query to avoid redundancy if it already contains course title
        String cleanQuery = query;
        if (query.toLowerCase().contains(courseTitle.toLowerCase())) {
           cleanQuery = query;
        }

        if (moduleType != null) {
          switch (moduleType.toLowerCase()) {
            case 'introduction':
            case 'basics':
            case 'fundamentals':
              searchQuery = '$courseTitle $cleanQuery tutorial for beginners';
              break;
            case 'core':
            case 'intermediate':
            case 'principles':
              searchQuery = '$courseTitle $cleanQuery intermediate tutorial';
              break;
            case 'advanced':
            case 'expert':
            case 'professional':
              searchQuery = '$courseTitle $cleanQuery advanced tutorial';
              break;
           case 'projects':
            case 'applications':
            case 'practical':
              searchQuery = '$courseTitle $cleanQuery project tutorial';
              break;
            default:
              searchQuery = '$courseTitle $cleanQuery tutorial';
          }
        } else {
          searchQuery = '$courseTitle $cleanQuery tutorial';
        }
      }
      print('YOUTUBE_SERVICE: Request URL parameters: q=$searchQuery');

      // Execute with retry logic for key rotation
      final response = await _executeWithRetry((apiKey) async {
          // Build URL with current key
          final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
            'part': 'snippet,id',
            'q': searchQuery,
            'type': 'video',
            'maxResults': '${maxResults * 2}', 
            'key': apiKey,
            'order': 'relevance',
            'videoCaption': 'any',
          });

          final resp = await http.get(uri).timeout(Duration(seconds: _timeoutSeconds));
          
          // Check specifically for Quota error (403) to trigger rotation
          if (resp.statusCode == 403) {
            throw Exception('Quota Exceeded (403)');
          }
          
          return resp;
      });

      print('YOUTUBE_SERVICE: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = await _parseVideoData(data);

        // Apply additional filtering for course-appropriate content
        final filteredVideos = _filterCourseVideos(
          videos,
          courseTitle ?? query,
          moduleType: moduleType,
          query: query,
        );

        // Sort by view count (most popular first) - videos are already sorted by viewCount from API
        // but we can add additional sorting if needed in the future

        // Return only the requested number of results
        return filteredVideos.take(maxResults).toList();
      } else {
        print(
          'YOUTUBE_SERVICE: Error ${response.statusCode}: ${response.body}',
        );
        return _getFallbackVideos(query);
      }
    } catch (e, stackTrace) {
      print('YOUTUBE_SERVICE ERROR: $e');
      print('YOUTUBE_SERVICE STACK TRACE: $stackTrace');
      return _getFallbackVideos(query);
    }
  }

  /// Fast video parsing without duration information to improve performance
  Future<List<YouTubeVideo>> _parseVideoData(Map<String, dynamic> data) async {
    final videos = <YouTubeVideo>[];

    if (data['items'] != null) {
      for (final item in data['items']) {
        try {
          final snippet = item['snippet'];
          final videoId = item['id']?['videoId'];

          if (snippet != null && videoId != null) {
            // Skip duration lookup for performance - use null duration
            // Duration will be checked later in filtering if needed
            final video = YouTubeVideo(
              id: videoId,
              title: snippet['title'] ?? 'Untitled',
              description: snippet['description'] ?? '',
              thumbnailUrl: snippet['thumbnails']?['medium']?['url'] ?? '',
              channelTitle: snippet['channelTitle'] ?? 'Unknown',
              publishedAt: snippet['publishedAt'] ?? '',
              duration: null, // Skip duration lookup for speed
            );
            videos.add(video);
          }
        } catch (e) {
          // Skip malformed videos
        }
      }
    }

    print('YOUTUBE_SERVICE: Parsed ${videos.length} videos');
    return videos;
  }

  /// Get video duration
  Future<String?> _getVideoDuration(String videoId) async {
    try {
      final response = await _executeWithRetry((apiKey) async {
         final uri = Uri.https('www.googleapis.com', '/youtube/v3/videos', {
           'part': 'contentDetails',
           'id': videoId,
           'key': apiKey,
         });

         final resp = await http
             .get(uri)
             .timeout(Duration(seconds: _timeoutSeconds));
         
         if (resp.statusCode == 403) {
             throw Exception('Quota Exceeded (403)');
         }
         return resp;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data['items'][0]['contentDetails']?['duration'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Filter videos for course appropriateness
  /// Enhanced to support comprehensive module coverage from basic to advanced
  List<YouTubeVideo> _filterCourseVideos(
    List<YouTubeVideo> videos,
    String courseTitle, {
    String? moduleType,
    String query = '',
  }) {
    final filtered = <YouTubeVideo>[];
    final lowerCourseTitle = courseTitle.toLowerCase();

    // Module-specific keywords for better targeting
    // Enhanced with more web development specific terms
    final moduleKeywords = <String, List<String>>{
      'introduction': [
        'introduction',
        'basics',
        'fundamentals',
        'getting started',
        'beginner',
        'learn',
        'start',
        'first',
        'html',
        'css',
        'javascript basics',
        'setup',
        'install',
        'environment',
      ],
      'core': [
        'core',
        'intermediate',
        'principles',
        'concepts',
        'essential',
        'main',
        'basic',
        'foundation',
        'frontend',
        'backend',
        'framework',
        'library',
        'responsive',
        'api',
        'database',
        'routing',
      ],
      'advanced': [
        'advanced',
        'expert',
        'professional',
        'deep dive',
        'master',
        'complex',
        'difficult',
        'senior',
        'performance',
        'optimization',
        'security',
        'architecture',
        'design patterns',
        'scalability',
        'testing',
        'debugging',
      ],
      'projects': [
        'project',
        'application',
        'practical',
        'hands-on',
        'build',
        'real world',
        'practice',
        'exercise',
        'portfolio',
        'full stack',
        'deployment',
        'production',
        'case study',
        'workshop',
      ],
    };

    for (final video in videos) {
      // Check if video is relevant to the course
      final lowerTitle = video.title.toLowerCase();
      final lowerDescription = video.description.toLowerCase();

      // Must contain course-related keywords
      if (!lowerTitle.contains(lowerCourseTitle) &&
          !lowerDescription.contains(lowerCourseTitle)) {
        continue;
      }

        // If module type is specified, check for module-specific keywords
        // DEEPER ALGORITHM: STRICT MODE
        // We now require the video to match the module intent more strictly.
        if (moduleType != null) {
          final keywords = moduleKeywords[moduleType.toLowerCase()] ?? [];
          bool strictMatchFound = false;

          // Check if video title or description contains module-specific keywords
          for (final keyword in keywords) {
             if (lowerTitle.contains(keyword) || lowerDescription.contains(keyword)) {
               strictMatchFound = true;
               break;
             }
          }
          
          // Also check against the query (Module Title) itself for specific words
          // e.g. if query is "React Hooks", we want to find "Hooks"
          final queryWords = query.toLowerCase().split(' ')
              .where((w) => w.length > 3 && !['introduction', 'basics', 'advanced', 'course', 'tutorial'].contains(w))
              .toList();
          
          for (final word in queryWords) {
            if (lowerTitle.contains(word)) {
              strictMatchFound = true;
              break;
            }
          }

          // STRICT FILTERING: If no strict match found, we skip this video
          // This ensures "Introduction" videos don't show up for "Advanced" modules
          if (!strictMatchFound && keywords.isNotEmpty) {
             continue; // Skip video if it doesn't match the specific module context
          }
        }

      // Must be educational content
      if (!_isEducationalContent(video)) {
        continue;
      }

      // Skip duration check to improve performance and ensure videos display
      // Duration filtering can be done in UI if needed

      // Must be understandable (have descriptive title/description)
      if (!_isUnderstandableVideo(video)) {
        continue;
      }

      // Video seems appropriate, add it
      filtered.add(video);

      // Limit to 5 videos per module to ensure variety without overwhelming
      // But make sure we have at least 3 videos for web development courses
      bool isWebDevelopment = lowerCourseTitle.contains('web');
      if (filtered.length >= 5 || (isWebDevelopment && filtered.length >= 3)) {
        break;
      }
    }

    // If no videos passed filtering, return first few videos as fallback to ensure display
    if (filtered.isEmpty && videos.isNotEmpty) {
      final fallbackCount = videos.length > 3 ? 3 : videos.length;
      filtered.addAll(videos.take(fallbackCount));
      print(
        'YOUTUBE_SERVICE: Using fallback - returning $fallbackCount videos',
      );
    }

    return filtered;
  }

  /// Check if content is educational
  /// Enhanced to better identify comprehensive course content
  bool _isEducationalContent(YouTubeVideo video) {
    final lowerTitle = video.title.toLowerCase();
    final lowerDescription = video.description.toLowerCase();

    // Educational keywords - expanded for better course content detection
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

    // Keywords that indicate high-quality educational content
    final qualityIndicators = [
      'complete',
      'comprehensive',
      'full course',
      'entire series',
      'in depth',
      'detailed',
      'thorough',
    ];

    // Check if any educational keyword is present
    bool hasEducationalKeyword = false;
    for (final keyword in educationalKeywords) {
      if (lowerTitle.contains(keyword) || lowerDescription.contains(keyword)) {
        hasEducationalKeyword = true;
        break;
      }
    }

    // If no basic educational keywords, reject
    if (!hasEducationalKeyword) {
      return false;
    }

    // Check for quality indicators to prioritize better content
    bool hasQualityIndicator = false;
    for (final indicator in qualityIndicators) {
      if (lowerTitle.contains(indicator) ||
          lowerDescription.contains(indicator)) {
        hasQualityIndicator = true;
        break;
      }
    }

    // Videos with quality indicators are preferred, but not required
    // This helps us identify more comprehensive course content
    return true;
  }

  /// Simple fallback videos
  List<YouTubeVideo> _getFallbackVideos(String query) {
    print('YOUTUBE_SERVICE: Using fallback videos for: $query');
    return [
      YouTubeVideo(
        id: 'rfscVS0vtbw',
        title: '$query Fundamentals',
        description: 'Learn the basics of $query',
        thumbnailUrl: 'https://img.youtube.com/vi/rfscVS0vtbw/mqdefault.jpg',
        channelTitle: 'Educational Channel',
        publishedAt: DateTime.now().toIso8601String(),
        duration: 'PT25M', // 25 minutes
      ),
      YouTubeVideo(
        id: '8mAITcNt710',
        title: 'Introduction to $query',
        description: 'Beginner guide to $query',
        thumbnailUrl: 'https://img.youtube.com/vi/8mAITcNt710/mqdefault.jpg',
        channelTitle: 'Learning Platform',
        publishedAt: DateTime.now().toIso8601String(),
        duration: 'PT30M', // 30 minutes
      ),
    ];
  }

  Future<bool> isVideoAccessible(String videoId) async {
    try {
      final response = await _executeWithRetry((apiKey) async {
        final url = Uri.https('www.googleapis.com', '/youtube/v3/videos', {
          'part': 'id',
          'id': videoId,
          'key': apiKey,
        });

        final resp = await http
            .get(url)
            .timeout(Duration(seconds: _timeoutSeconds));
        
        if (resp.statusCode == 403) {
             throw Exception('Quota Exceeded (403)');
        }
        return resp;
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Validate and create a video object from a URL (No API Key needed)
  /// Checks if the video thumbnail exists to verify validity
  Future<YouTubeVideo?> getVideoFromUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      String? videoId;
      
      if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      } else if (uri.host.contains('youtube.com')) {
        videoId = uri.queryParameters['v'];
      }

      if (videoId == null || videoId.isEmpty) return null;

      // Validate by checking thumbnail existence (No API Quota check)
      final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';
      final response = await http.head(Uri.parse(thumbnailUrl));
      
      if (response.statusCode != 200) {
        print('YOUTUBE_SERVICE: ⚠️ Invalid AI video URL (Thumbnail not found): $url');
        return null;
      }

      return YouTubeVideo(
        id: videoId,
        title: 'Watch Module Video', // We don't have title without API, will be updated or generic
        description: 'Recommended video for this module',
        thumbnailUrl: thumbnailUrl,
        channelTitle: 'YouTube',
        publishedAt: DateTime.now().toIso8601String(),
        duration: null,
      );
    } catch (e) {
      print('YOUTUBE_SERVICE: Error validating URL: $e');
      return null;
    }
  }

  /// Check if video is understandable (has descriptive title/description)
  /// Enhanced to better identify educational content and filter out spam
  bool _isUnderstandableVideo(YouTubeVideo video) {
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

    // Should contain educational indicators
    final educationalIndicators = [
      'tutorial',
      'course',
      'learn',
      'introduction',
      'basics',
      'fundamentals',
      'guide',
      'lesson',
      'module',
      'chapter',
      'complete',
      'comprehensive',
      'step by step',
    ];

    bool hasEducationalIndicator = false;
    for (final indicator in educationalIndicators) {
      if (lowerTitle.contains(indicator) ||
          lowerDescription.contains(indicator)) {
        hasEducationalIndicator = true;
        break;
      }
    }

    // Prefer videos with educational indicators, but don't reject those without
    // This helps filter for more relevant content while still allowing some flexibility
    return true;
  }
}

class YouTubeVideo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final String publishedAt;
  final String? duration;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
    this.duration,
  });

  String get watchUrl => 'https://www.youtube.com/watch?v=$id';
  String get embedUrl => 'https://www.youtube.com/embed/$id';

  // Helper method to check if video duration is within course range
  // Enhanced to support different module types with appropriate durations
  bool get isCourseAppropriateDuration {
    if (duration == null) return true; // If no duration info, assume it's OK

    // Parse ISO 8601 duration format (PT1H30M15S = 1 hour 30 minutes 15 seconds)
    try {
      final regExp = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
      final match = regExp.firstMatch(duration!);
      if (match == null) return true;

      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

      final totalMinutes = hours * 60 + minutes + (seconds / 60).round();

      // Different duration ranges based on content type:
      // - Short tutorials/introductions: 5-20 minutes
      // - Comprehensive lessons: 15-45 minutes
      // - Full course modules: 30-90 minutes
      // - Project walkthroughs: 20-120 minutes

      // For now, we'll use a flexible range that accommodates most educational content
      // Course videos should generally be between 5-120 minutes
      return totalMinutes >= 5 && totalMinutes <= 120;
    } catch (e) {
      return true; // If parsing fails, assume it's OK
    }
  }
}
