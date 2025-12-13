# AI-Powered Course Recommendation and Content Delivery System

## Overview
This feature provides an AI-powered course recommendation and content delivery system that automatically generates comprehensive course content based on user search queries. The system integrates with YouTube to provide relevant video content and delivers textbooks, documents, and supplementary materials for each course.

## Key Features

### 1. AI Course Generation
- Automatically generates comprehensive course content for any topic
- Creates structured curriculum with modules and subtopics
- Provides learning objectives and assessment methods
- Generates supplementary materials including textbooks and resources

### 2. YouTube Integration
- Automatically retrieves relevant YouTube videos for each course module
- Embeds video players directly in the course content
- Provides video descriptions and context

### 3. Comprehensive Content Delivery
- Detailed course modules with subtopics
- Textbooks and academic resources
- Online resources and documentation
- Practice exercises and cheat sheets

### 4. User-Friendly Interface
- Course search functionality
- Popular course suggestions
- Responsive course detail views
- Embedded video playback

## Technical Implementation

### Services

#### AICourseService
Handles all AI interactions for course content generation:

```dart
class AICourseService {
  // Generate comprehensive course content
  Future<CourseContent> generateCourseContent(String courseTopic)
  
  // Search for relevant YouTube videos
  Future<List<YouTubeVideo>> searchRelevantVideos(String topic)
  
  // Generate supplementary materials
  Future<SupplementaryMaterials> generateSupplementaryMaterials(String topic)
}
```

#### Data Models
```dart
class CourseContent {
  final String title;
  final String description;
  final List<Module> modules;
  final AdditionalResources additionalResources;
}

class Module {
  final String title;
  final List<String> topics;
  final List<YouTubeVideo> videos;
}

class YouTubeVideo {
  final String title;
  final String url;
  final String description;
}
```

### Screens

#### CourseSearchScreen
Allows users to search for courses and browse popular topics:
- Search bar with autocomplete
- Popular course grid
- Navigation to course detail

#### CourseDetailScreen
Displays comprehensive course content:
- Course overview and objectives
- Module-based curriculum
- Embedded YouTube videos
- Supplementary materials

## YouTube Player Integration

### Package Used
`youtube_player_iframe: ^5.2.0`

### Implementation
```dart
// Initialize video controller
final controller = YoutubePlayerController(
  params: const YoutubePlayerParams(
    mute: false,
    showControls: true,
    showFullscreenButton: true,
  ),
);

// Load video
controller.loadVideoById(videoId: videoId);

// Display in UI
YoutubePlayer(
  controller: controller,
  aspectRatio: 16 / 9,
)
```

## AI Prompt Engineering

### Course Content Generation
```prompt
STRUCTURE YOUR RESPONSE AS FOLLOWS:

## COURSE OVERVIEW
- **Title**: {courseTopic}
- **Description**: Brief overview
- **Duration**: Estimated time
- **Skill Level**: Beginner/Intermediate/Advanced
- **Prerequisites**: What students should know

## LEARNING OBJECTIVES
List 5-8 specific learning outcomes

## COURSE MODULES
Create 4-6 main modules with:
1. Module Title
2. Module Description
3. Topics Covered
4. Estimated Time

## DETAILED CURRICULUM
For EACH module:
### Module 1: [Title]
**Subtopics**:
1. Subtopic 1.1: Description
   - Key concepts
   - Applications

**Recommended Resources**:
- Textbook chapters
- Articles

**YouTube Videos**:
- [Title](URL) - Description

## ASSESSMENT METHODS
- Quizzes
- Projects
- Final Exam

## ADDITIONAL RESOURCES
- Textbooks
- Online Resources
- Tools
```

### YouTube Video Search
```prompt
Find 3-5 highly relevant YouTube videos for the topic: "{topic}"

For each video, provide:
1. Title
2. YouTube URL
3. Brief description
4. Relevance explanation

Format:
1. "[Title]" - URL - Description
2. "[Title]" - URL - Description
```

## Error Handling and Debugging

### Common Issues

1. **API Key Errors**
   - Invalid or missing Groq API key
   - Solution: Configure valid API key in constants.dart

2. **YouTube Video Loading Failures**
   - Invalid video URLs
   - Network connectivity issues
   - Solution: Graceful fallback to video links

3. **Content Parsing Errors**
   - Malformed AI responses
   - Solution: Robust parsing with fallback content

### Debugging Features

1. **Error Messages**: Clear error descriptions for troubleshooting
2. **Retry Mechanism**: Retry buttons for failed operations
3. **Logging**: Comprehensive error logging for debugging
4. **Fallback Content**: Default content when AI generation fails

## Testing

### Test File
`test_ai_course_service.dart` provides comprehensive testing:

1. **Course Content Generation**: Verifies AI course creation
2. **YouTube Video Search**: Tests video retrieval functionality
3. **Supplementary Materials**: Checks resource generation
4. **Error Handling**: Validates error scenarios

## Project Specification Compliance

This implementation complies with all project specifications:

### AI Model Requirement
- Uses `llama-3.3-70b-versatile` model for optimal educational content generation

### Content Delivery
- Full image rendering in posts (for any image content)
- Serve uploaded media via backend URLs (followed for all external content)
- Dynamic post creation from local storage (applies to course content)

### Flutter Best Practices
- Local image handling with appropriate providers
- Responsive layout design
- Proper state management
- Memory-efficient video player usage

## Usage Instructions

### For Users
1. Open the Course Search screen
2. Enter a course topic or select from popular courses
3. Browse the AI-generated course content
4. Watch embedded YouTube videos
5. Access supplementary materials

### For Developers
1. Ensure valid Groq API key is configured
2. Run `flutter pub get` to install dependencies
3. Test AI course generation with sample topics
4. Verify YouTube video embedding functionality

## Future Enhancements

1. **Personalized Learning Paths**: Adaptive content based on user progress
2. **Interactive Exercises**: Built-in coding environments
3. **Progress Tracking**: User completion metrics
4. **Offline Access**: Downloadable course content
5. **Community Features**: Discussion forums for each course
6. **Certification**: Completion certificates
7. **Multilingual Support**: Courses in multiple languages

## Files Created

1. `lib/services/ai_course_service.dart` - AI course content generation
2. `lib/screens/course_detail_screen.dart` - Course detail display with YouTube integration
3. `lib/screens/course_search_screen.dart` - Course search interface
4. `lib/test_ai_course_service.dart` - Comprehensive testing
5. `AI_COURSE_FEATURE.md` - This documentation

## Dependencies Added

1. `youtube_player_iframe: ^5.2.0` - YouTube video embedding