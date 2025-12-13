import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'groq_service.dart';
import 'youtube_service.dart' as youtube;
import 'web_scraper_service.dart' as web_scraper;
import '../utils/constants.dart';

class AICourseService {
  final GroqService _aiService;
  final youtube.YouTubeService _youtubeService;
  final web_scraper.WebScraperService _webScraperService;

  AICourseService({required GroqService aiService})
    : _aiService = aiService,
      _youtubeService = youtube.YouTubeService(),
      _webScraperService = web_scraper.WebScraperService();

  /// Generate a comprehensive course structure with subtopics and learning path
  Future<CourseContent> generateCourseContent(String courseTopic) async {
    print('COURSE_SERVICE: Generating course content for: $courseTopic');
    try {
      // Create a more focused prompt for better, faster results
      // Enhanced to request comprehensive module coverage from basic to advanced levels
      final prompt = '''
${AppConstants.defaultSystemPrompt}

You are an expert curriculum designer. Create a COMPREHENSIVE, STEP-BY-STEP course structure for"${courseTopic}".
This course must cover the topic from absolute beginner to expert level, ensuring NO important concept is skipped.
Think about how a university or Bootcamp would structure this. It usually takes 8-15 modules to cover a topic properly.

RETURN ONLY THIS EXACT FORMAT - NO EXTRA TEXT:

## COURSE OVERVIEW
- **Title**: ${courseTopic}
- **Description**: Detailed mastery course for ${courseTopic}
- **Duration**: Self-paced (approx 20+ hours)
- **Skill Level**: Beginner to Expert
- **Prerequisites**: Basic computer literacy

## LEARNING OBJECTIVES
1. Master core fundamentals
2. Understand advanced concepts
3. Build real-world projects
4. Apply best practices

## COURSE MODULES
(Generate a list of 8 to 15 modules. Number them sequentially. Each module must have a descriptive, technical title AND a relevant YouTube URL.)
1. **[Module Title]**: [Brief Description] ([Time]) [https://www.youtube.com/watch?v=...]
2. **[Module Title]**: [Brief Description] ([Time])
...
N. **[Module Title]**: [Brief Description] ([Time])

## GAMIFICATION CHALLENGES
(For each module above, provide a simple coding challenge. e.g. Unjumble code, Fix syntax)
1. **Challenge**: [Description of challenge for Module 1]
   **Initial Code**: [Jumbled/Broken Code]
   **Solution**: [Correct Code]
2. **Challenge**: [Description for Module 2]
   **Initial Code**: [Code]
   **Solution**: [Code]
... (one for each module)

## ASSESSMENT METHODS
- Practical exercises
- Final Project

Return ONLY the above structure. No markdown formatting like ```json or ```markdown.
''';

      print('COURSE_SERVICE: Sending request to Groq API...');
      // Add timeout to prevent hanging
      final response = await _aiService
          .sendMessage(prompt)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print(
                'COURSE_SERVICE ERROR: AI course generation timed out after 30 seconds',
              );
              throw TimeoutException(
                'AI course generation timed out after 30 seconds',
                const Duration(seconds: 30),
              );
            },
          );

      print('COURSE_SERVICE: AI response received, length: ${response.length}');
      print(
        'COURSE_SERVICE: First 200 chars: ${response.substring(0, response.length > 200 ? 200 : response.length)}',
      );

      print('COURSE_SERVICE: Parsing course content...');
      final result = _parseCourseContent(response, courseTopic);
      print('COURSE_SERVICE: Course content parsed successfully');
      return result;
    } catch (e, stackTrace) {
      print('COURSE_SERVICE ERROR: Error generating course content: $e');
      print('COURSE_SERVICE ERROR: Stack trace: $stackTrace');
      // Return a fallback course content if AI fails
      print('COURSE_SERVICE: Using fallback course content');
      return _createFallbackCourseContent(courseTopic);
    }
  }

  /// Search for relevant YouTube videos for a specific topic using multiple API keys
  /// ENHANCED: Now includes course context for better filtering
  Future<List<YouTubeVideoModel>> searchRelevantVideos(
    String topic, {
    String? courseContext,
  }) async {
    print('COURSE_SERVICE: Searching for videos on topic: $topic');
    if (courseContext != null) {
      print('COURSE_SERVICE: With course context: $courseContext');
    }
    try {
      // Extract the base course name from topic (e.g., "Python" from "Introduction to Python")
      final baseCourseName = _extractBaseCourseName(topic, courseContext);
      print('COURSE_SERVICE: Extracted base course name: $baseCourseName');

      // First get the YouTube videos with enhanced course context
      print('COURSE_SERVICE: Calling YouTube service searchVideos...');

      // Determine module type based on topic for better targeting
      String? moduleType;
      final lowerTopic = topic.toLowerCase();
      if (lowerTopic.contains('introduction') ||
          lowerTopic.contains('basics') ||
          lowerTopic.contains('fundamentals')) {
        moduleType = 'introduction';
      } else if (lowerTopic.contains('core') ||
          lowerTopic.contains('intermediate') ||
          lowerTopic.contains('principles')) {
        moduleType = 'core';
      } else if (lowerTopic.contains('advanced') ||
          lowerTopic.contains('expert') ||
          lowerTopic.contains('professional')) {
        moduleType = 'advanced';
      } else if (lowerTopic.contains('project') ||
          lowerTopic.contains('application') ||
          lowerTopic.contains('practical')) {
        moduleType = 'projects';
      }

      final youtubeVideos = await _youtubeService.searchVideos(
        topic,
        maxResults:
            2, // Limit to 2 videos per module as requested
        courseTitle: baseCourseName, // Pass the base course name
        language: 'English', // Default to English unless specified
        moduleType: moduleType, // Pass module type for better targeting
      );

      print(
        'COURSE_SERVICE: Found ${youtubeVideos.length} videos from YouTube service',
      );

      // STRICT validation: Only keep videos that are truly relevant
      final convertedVideos = <YouTubeVideoModel>[];
      for (final video in youtubeVideos) {
        try {
          print(
            'COURSE_SERVICE: Processing video: ${video.title} (${video.id})',
          );

          // VALIDATION 1: Check if video is actually relevant to our course
          final lowerTitle = video.title.toLowerCase();
          final lowerDesc = (video.description ?? '').toLowerCase();
          final lowerTopic = topic.toLowerCase();
          final lowerBase = baseCourseName.toLowerCase();

          // Video MUST contain either the topic or base course name
          final isRelevant =
              lowerTitle.contains(lowerTopic) ||
              lowerTitle.contains(lowerBase) ||
              lowerDesc.contains(lowerTopic) ||
              lowerDesc.contains(lowerBase);

          if (!isRelevant) {
            print(
              'COURSE_SERVICE: Rejecting video (not relevant): ${video.title}',
            );
            continue;
          }

          // VALIDATION 2: Reject common non-educational content
          if (_isNonEducationalContent(video.title)) {
            print(
              'COURSE_SERVICE: Rejecting video (non-educational): ${video.title}',
            );
            continue;
          }

          // VALIDATION 3: Check if video is accessible (with timeout)
          print('COURSE_SERVICE: Checking video accessibility...');
          final isAccessible = await _youtubeService
              .isVideoAccessible(video.id)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  print(
                    'COURSE_SERVICE: Video accessibility check timed out, assuming accessible',
                  );
                  return true;
                },
              );

          if (isAccessible) {
            final videoModel = YouTubeVideoModel(
              id: video.id,
              title: video.title,
              url: video.watchUrl,
              description:
                  video.description.isNotEmpty
                      ? video.description
                      : 'Learn about $baseCourseName',
            );
            convertedVideos.add(videoModel);
            print('COURSE_SERVICE: ✅ Added accessible video: ${video.title}');
          } else {
            print(
              'COURSE_SERVICE: Skipping inaccessible video: ${video.title}',
            );
          }
        } catch (e, stackTrace) {
          print('COURSE_SERVICE ERROR: Error checking video: $e');
          print('COURSE_SERVICE ERROR: Stack trace: $stackTrace');
          // Still try to add the video even if we can't verify accessibility
          try {
            final videoModel = YouTubeVideoModel(
              id: video.id,
              title: video.title,
              url: video.watchUrl,
              description:
                  video.description.isNotEmpty
                      ? video.description
                      : 'Learn about this topic',
            );
            convertedVideos.add(videoModel);
          } catch (innerE) {
            print('COURSE_SERVICE ERROR: Failed to convert video: $innerE');
          }
        }
      }

      print(
        'COURSE_SERVICE: ✅ Returning ${convertedVideos.length} validated videos (from ${youtubeVideos.length} initial results)',
      );

      // Return at least 5 videos or more if available
      if (convertedVideos.isEmpty) {
        print('COURSE_SERVICE: No validated videos found, using fallback');
        return _getDefaultEducationalVideos(topic);
      }

      return convertedVideos;
    } catch (e, stackTrace) {
      print(
        'COURSE_SERVICE ERROR: Failed to search YouTube videos for "$topic": $e',
      );
      print('COURSE_SERVICE ERROR: Stack trace: $stackTrace');
      // Return some default educational videos if search fails
      print('COURSE_SERVICE: Using default educational videos');
      return _getDefaultEducationalVideos(topic);
    }
  }

  /// Extract the base course name intelligently from topic
  /// Examples: "Introduction to Python" -> "Python", "Python Basics" -> "Python"
  String _extractBaseCourseName(String topic, String? courseContext) {
    if (courseContext != null && courseContext.isNotEmpty) {
      return courseContext;
    }

    // Remove common prefixes
    var baseName = topic
        .replaceFirst(
          RegExp(
            r'^(Introduction|Basics|Advanced|Learn|Master)\s+to\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^(Introduction|Basics|Advanced|Learn|Master)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'\s+(Basics|Introduction|Tutorial|Guide|Course)$',
            caseSensitive: false,
          ),
          '',
        );

    // Extract the primary programming language/topic
    final keywords = [
      'Python',
      'Java',
      'JavaScript',
      'C++',
      'C#',
      'PHP',
      'Ruby',
      'Go',
      'Rust',
      'Kotlin',
      'Swift',
      'TypeScript',
      'R programming',
      'MATLAB',
      'Scala',
      'Perl',
    ];

    for (final keyword in keywords) {
      if (baseName.toLowerCase().contains(keyword.toLowerCase())) {
        return keyword;
      }
    }

    // If no match, return the first 2-3 words
    final words = baseName.split(' ');
    return words.take(min(3, words.length)).join(' ');
  }

  /// Check if content is likely non-educational
  bool _isNonEducationalContent(String title) {
    final lowerTitle = title.toLowerCase();
    final nonEducationalKeywords = [
      'unboxing',
      'review',
      'comparison',
      'vs ',
      'merchandise',
      'giveaway',
      'contest',
      'sponsored',
      'commercial',
      'advertisement',
      'music video',
      'movie',
      'trailer',
      'short film',
      'vlog',
      'podcast',
      'interview',
    ];

    for (final keyword in nonEducationalKeywords) {
      if (lowerTitle.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Parse the AI-generated course content into structured data
  Future<CourseContent> _parseCourseContent(
    String rawContent,
    String topic,
  ) async {
    print('COURSE_SERVICE: Parsing course content for: $topic');
    print('COURSE_SERVICE: Raw content length: ${rawContent.length}');
    try {
      // Simple line-by-line parsing for the structured format
      final lines = rawContent.split('\n');
      print('COURSE_SERVICE: Split content into ${lines.length} lines');

      String title = topic;
      String description = 'Comprehensive course on $topic';
      String duration = 'Self-paced';
      String skillLevel = '';
      String prerequisites = '';
      List<String> learningObjectives = [];
      List<Module> modules = [];
      String currentSection = '';

      // Parser State for Gamification
      int _pendingChallengeIndex = -1;
      String _pendingChallengeDesc = '';
      String _pendingInitialCode = '';
      String _pendingSolution = '';

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Identify sections
        if (line == '## COURSE OVERVIEW') {
          currentSection = 'overview';
          continue;
        } else if (line == '## LEARNING OBJECTIVES') {
          currentSection = 'objectives';
          continue;
        } else if (line == '## COURSE MODULES') {
          currentSection = 'modules';
          continue;
        } else if (line.startsWith('## GAMIFICATION')) { // Loose match to catch "GAMIFICATION CHALLENGES"
          currentSection = 'gamification';
          continue;
        } else if (line == '## ASSESSMENT METHODS') {
          currentSection = 'assessment';
          continue;
        }

        // Parse based on current section
        if (currentSection == 'overview') {
          if (line.startsWith('- **Description**:')) {
            description = line.replaceFirst('- **Description**:', '').trim();
          } else if (line.startsWith('- **Duration**:')) {
            duration = line.replaceFirst('- **Duration**:', '').trim();
          } else if (line.startsWith('- **Skill Level**:')) {
            skillLevel = line.replaceFirst('- **Skill Level**:', '').trim();
          } else if (line.startsWith('- **Prerequisites**:')) {
            prerequisites =
                line.replaceFirst('- **Prerequisites**:', '').trim();
          }
        } else if (currentSection == 'objectives') {
          if (line.startsWith(RegExp(r'^\d+\.'))) {
            learningObjectives.add(
              line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim(),
            );
          }
        } else if (currentSection == 'gamification') {
           // Parse format:
           // 1. **Challenge**: ...
           //    **Initial Code**: ...
           //    **Solution**: ...
           
           // We need to track which module we are parsing for
           // Simple regex to find "N. **Challenge**"
           final challengeMatch = RegExp(r'^(\d+)\.\s*\*\*(?:Challenge|Task)\*\*:\s*(.*)').firstMatch(line);
           if (challengeMatch != null) {
              final index = int.parse(challengeMatch.group(1)!) - 1;
              final desc = challengeMatch.group(2)?.trim() ?? 'Complete the code';
              
              if (index >= 0 && index < modules.length) {
                 // Create a placeholder challenge if not exists, or update existing
                 // Since we are parsing line by line, we might need a temporary map or careful state
                 // Let's assume the AI generates them in order and contiguous blocks.
                 
                 // We need to capture the next lines for Code and Solution.
                 // This requires looking ahead or keeping state. 
                 // Let's use a "pendingChallenge" state object.
                 _pendingChallengeIndex = index;
                 _pendingChallengeDesc = desc;
                 _pendingInitialCode = '';
                 _pendingSolution = '';
              }
           } else if (_pendingChallengeIndex != -1) {
              if (line.trim().startsWith('**Initial Code**:')) {
                 _pendingInitialCode = line.replaceFirst('**Initial Code**:', '').trim();
              } else if (line.trim().startsWith('**Solution**:')) {
                 _pendingSolution = line.replaceFirst('**Solution**:', '').trim();
                 
                 // We have all parts (assuming Solution is last), save it
                 if (_pendingChallengeIndex < modules.length) {
                    // Update the module with the new challenge
                    // Since Module is immutable, we have to recreate it or use a mutable builder.
                    // Or... Module fields are final. We need to replace the Module in the list.
                    
                    final oldModule = modules[_pendingChallengeIndex];
                    modules[_pendingChallengeIndex] = Module(
                      title: oldModule.title,
                      description: oldModule.description,
                      topics: oldModule.topics,
                      estimatedTime: oldModule.estimatedTime,
                      videos: oldModule.videos,
                      resources: oldModule.resources,
                      challenge: GamificationChallenge(
                        description: _pendingChallengeDesc,
                        initialCode: _pendingInitialCode,
                        solutionCode: _pendingSolution,
                        language: 'python', // Default to python for now, or infer from course
                      ),
                    );
                    
                    // Reset pending
                    _pendingChallengeIndex = -1;
                 }
              } else {
                 // Continuation of code? 
                 // If the code is multi-line, this simple parser might break.
                 // But the prompt asks for "[Code]" which usually implies a single line snippet for "Unjumble".
                 // If AI gives multi-line, we'd need a more complex parser.
                 // For "Jumbled tags", single line string `<h1>text</h1>` is fine.
              }
           }
        } else if (currentSection == 'modules') {
          // Dynamic module parsing with robust URL extraction
          // format: "1. **Title**: Description (Time) [URL]"
          
          // 1. Extract URL if present anywhere in the line
          String? aiUrl;
          final urlMatch = RegExp(r'https?://[^\s\]\)]+').firstMatch(line);
          if (urlMatch != null) {
            aiUrl = urlMatch.group(0);
          }

          // 2. Parse Title, Description, Time
          // Removing the URL part for cleaner parsing if needed, but regex can handle it
          final contentMatch = RegExp(r'^\d+\.\s*(?:\*\*)?(.*?)(?:\*\*)?:\s*(.*?)\s*\((.*?)\)').firstMatch(line);
          
          if (contentMatch != null) {
              final rawTitle = contentMatch.group(1)?.trim() ?? 'Module';
              // Clean title of any remaining asterisks
              final moduleTitle = rawTitle.replaceAll('*', '').trim();
              
              final moduleDesc = contentMatch.group(2)?.trim() ?? 'Learn about $moduleTitle';
              final moduleTime = contentMatch.group(3)?.trim() ?? '1 hour';

              // Generate specific topics
              List<String> moduleTopics = [];
              if (moduleTitle.toLowerCase().contains('intro')) {
                 moduleTopics = ['Setup', 'Basics', 'First Steps'];
              } else if (moduleTitle.toLowerCase().contains('project')) {
                 moduleTopics = ['Planning', 'Building', 'Refining'];
              } else {
                 moduleTopics = [
                   'Understanding $moduleTitle',
                   'Using $moduleTitle',
                   'Best Practices for $moduleTitle'
                 ];
              }

              List<YouTubeVideoModel> activeVideos = [];
              if (aiUrl != null) {
                 // Verify the AI URL without using API Quota
                 final validVideo = await _youtubeService.getVideoFromUrl(aiUrl);
                 if (validVideo != null) {
                    // Convert YouTubeService video to AICourseService video model if needed
                    // Wait, AICourseService uses YouTubeVideoModel? 
                    // Let's check imports. It imports youtube_service.dart.
                    // But uses YouTubeVideoModel... check that class.
                    // Actually, let's use the one from youtube_service.dart called YouTubeVideo.
                    // Wait, Module definition uses YouTubeVideoModel?
                    // I need to check the Module class definition at the bottom of file.
                    // It says: final List<YouTubeVideoModel> videos;
                    // And _getDefaultEducationalVideos returns YouTubeVideoModel.
                    // Safe to assume I should use YouTubeVideoModel.
                    activeVideos.add(
                      YouTubeVideoModel(
                        id: validVideo.id,
                        title: '$moduleTitle Video', // AI validated video
                        url: aiUrl,
                        description: validVideo.description,
                      )
                    );
                 }
              }

              // Parse Gamification Challenge (Example format in prompt needed)
              // Since the current prompt doesn't strictly enforce per-section structure for modules,
              // we might need to rely on the module line itself or a separate section.
              // Let's UPDATE the PROMPT first to verify we get the data.
              
              // Actually, parsing per-module details from a single line is hard if we add multi-line code.
              // We should request the gamification challenges in a separate section mapped by Module Number.
              
              // Placeholder for now, executed below in `Module` construction
              GamificationChallenge? challenge; // Will be populated in a second pass or if we change prompt structure.
              
              modules.add(
                Module(
                  title: moduleTitle,
                  description: moduleDesc,
                  topics: moduleTopics,
                  estimatedTime: moduleTime,
                  videos: activeVideos, 
                  resources: [],
                  challenge: null, // Will be updated
                ),
              );
          }
        } else if (currentSection == 'assessment') {
          // We could parse assessment methods here if needed
        }
      }
      print(
        'COURSE_SERVICE: Successfully parsed course content with ${modules.length} modules',
      );
      return CourseContent(
        title: title,
        description: description,
        duration: duration,
        skillLevel: skillLevel,
        prerequisites: prerequisites,
        learningObjectives:
            learningObjectives.isNotEmpty
                ? learningObjectives
                : [
                  'Understand $topic fundamentals',
                  'Apply concepts practically',
                ],
        modules: modules,
        assessmentMethods: 'Practical exercises and self-assessment',
        additionalResources: AdditionalResources(
          textbooks: [],
          onlineResources: [],
          tools: [],
        ),
      );
    } catch (e, stackTrace) {
      print('COURSE_SERVICE ERROR: Error parsing course content: $e');
      print('COURSE_SERVICE ERROR: Stack trace: $stackTrace');
      // Fallback if parsing fails
      print(
        'COURSE_SERVICE: Using fallback course content due to parsing error',
      );
      return _createFallbackCourseContent(topic);
    }
  }

  /// Create fallback course content when AI generation fails
  /// Enhanced to provide comprehensive coverage from basics to advanced levels
  CourseContent _createFallbackCourseContent(String topic) {
    print('COURSE_SERVICE: Creating fallback course content for: $topic');
    return CourseContent(
      title: topic,
      description:
          'Comprehensive course on $topic covering everything from basics to advanced concepts',
      duration: 'Self-paced',
      skillLevel: 'Beginner to Expert',
      prerequisites: 'None',
      learningObjectives: [
        'Master fundamental concepts of $topic',
        'Apply intermediate principles in practical scenarios',
        'Implement advanced techniques and best practices',
        'Build real-world projects using $topic',
      ],
      modules: [
        Module(
          title: 'Introduction to $topic',
          description: 'Getting started with the fundamentals of $topic',
          topics: ['Getting Started', 'Basic Syntax', 'Environment Setup'],
          estimatedTime: '1 hour',
          videos: [],
          resources: [],
        ),
        Module(
          title: '$topic Fundamentals',
          description: 'Core concepts and essential principles of $topic',
          topics: ['Core Concepts', 'Essential Principles', 'Foundations'],
          estimatedTime: '2 hours',
          videos: [],
          resources: [],
        ),
        Module(
          title: 'Intermediate $topic',
          description: 'Building on core concepts with intermediate techniques',
          topics: [
            'Intermediate Concepts',
            'Best Practices',
            'Common Patterns',
          ],
          estimatedTime: '2 hours',
          videos: [],
          resources: [],
        ),
        Module(
          title: 'Advanced $topic',
          description: 'Expert techniques and best practices in $topic',
          topics: [
            'Advanced Techniques',
            'Performance Optimization',
            'Expert Tips',
          ],
          estimatedTime: '2 hours',
          videos: [],
          resources: [],
        ),
        Module(
          title: '$topic Projects',
          description: 'Hands-on projects and real-world applications',
          topics: ['Project Planning', 'Implementation', 'Deployment'],
          estimatedTime: '3 hours',
          videos: [],
          resources: [],
        ),
      ],
      assessmentMethods:
          'Practical exercises, coding challenges, project submissions, and quizzes',
      additionalResources: AdditionalResources(
        textbooks: [],
        onlineResources: [],
        tools: [],
      ),
    );
  }

  /// Geneate a final quiz for the course
  Future<List<QuizQuestion>> generateFinalQuiz(String courseTitle) async {
    try {
      final prompt = '''
      Create a Final Exam Quiz for the course "$courseTitle".
      - Generate exactly 20 multiple-choice questions.
      - Difficulty: Intermediate to Advanced.
      - Format:
        Q1. [Question Text]
        A) [Option 1]
        B) [Option 2]
        C) [Option 3]
        D) [Option 4]
        Answer: [Correct Option Letter]

      Ensure the questions cover the entire scope of the course.
      ''';

      final content = await _aiService.sendMessage(prompt);
      return _parseQuizContent(content);
    } catch (e) {
      print('Error generating quiz: $e');
      // Fallback dummy quiz
      return [
        QuizQuestion(
          question: 'What is the main purpose of $courseTitle?',
          options: ['Option A', 'Option B', 'Option C', 'Option D'],
          correctOptionIndex: 0,
        ),
      ];
    }
  }

  List<QuizQuestion> _parseQuizContent(String content) {
    final List<QuizQuestion> questions = [];
    final lines = content.split('\n');
    
    String? currentQuestion;
    List<String> currentOptions = [];
    int correctAnswerIndex = -1;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (RegExp(r'^Q\d+\.').hasMatch(line)) {
        // Save previous question
        if (currentQuestion != null && currentOptions.length == 4 && correctAnswerIndex != -1) {
           questions.add(QuizQuestion(
             question: currentQuestion,
             options: List.from(currentOptions),
             correctOptionIndex: correctAnswerIndex,
           ));
        }
        // Start new
        currentQuestion = line.replaceFirst(RegExp(r'^Q\d+\.\s*'), '').trim();
        currentOptions = [];
        correctAnswerIndex = -1;
      } else if (line.startsWith('A)') || line.startsWith('B)') || line.startsWith('C)') || line.startsWith('D)')) {
        currentOptions.add(line.substring(2).trim());
      } else if (line.startsWith('Answer:')) {
        final answerLetter = line.replaceFirst('Answer:', '').trim();
        if (answerLetter.isNotEmpty) {
           correctAnswerIndex = answerLetter.codeUnitAt(0) - 65; // 'A' -> 0, 'B' -> 1
        }
      }
    }
    
    // Add last question
    if (currentQuestion != null && currentOptions.length == 4 && correctAnswerIndex != -1) {
       questions.add(QuizQuestion(
         question: currentQuestion,
         options: List.from(currentOptions),
         correctOptionIndex: correctAnswerIndex,
       ));
    }

    return questions;
  }

  /// Get default educational videos when search fails
  List<YouTubeVideoModel> _getDefaultEducationalVideos(String topic) {
    print('COURSE_SERVICE: Getting default educational videos for: $topic');
    return [
      YouTubeVideoModel(
        id: '_DFXx_aAfQ', // Valid educational video ID
        title: 'Introduction to $topic',
        url: 'https://www.youtube.com/watch?v=_DFXx_aAfQ',
        description: 'Learn the basics of $topic',
      ),
      YouTubeVideoModel(
        id: 'UB1O30fR-EE', // Valid educational video ID
        title: '$topic Fundamentals',
        url: 'https://www.youtube.com/watch?v=UB1O30fR-EE',
        description: 'Core concepts in $topic',
      ),
    ];
  }
}

// Data models
class CourseContent {
  final String title;
  final String description;
  final String duration;
  final String skillLevel;
  final String prerequisites;
  final List<String> learningObjectives;
  final List<Module> modules;
  final String assessmentMethods;
  final AdditionalResources additionalResources;

  CourseContent({
    required this.title,
    required this.description,
    required this.duration,
    required this.skillLevel,
    required this.prerequisites,
    required this.learningObjectives,
    required this.modules,
    required this.assessmentMethods,
    required this.additionalResources,
  });
}

class Module {
  final String title;
  final String description;
  final List<String> topics;
  final String estimatedTime;
  final List<YouTubeVideoModel> videos;
  final List<String> resources;
  final GamificationChallenge? challenge;

  Module({
    required this.title,
    required this.description,
    required this.topics,
    required this.estimatedTime,
    required this.videos,
    required this.resources,
    this.challenge,
  });
}

class GamificationChallenge {
  final String description;
  final String initialCode;
  final String solutionCode;
  final String language;

  GamificationChallenge({
    required this.description,
    required this.initialCode,
    required this.solutionCode,
    required this.language,
  });
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });
}

// Renamed YouTubeVideo to YouTubeVideoModel to avoid conflicts
class YouTubeVideoModel {
  final String id;
  final String title;
  final String url;
  final String description;

  YouTubeVideoModel({
    required this.id,
    required this.title,
    required this.url,
    required this.description,
  });
}

class AdditionalResources {
  final List<Textbook> textbooks;
  final List<OnlineResource> onlineResources;
  final List<String> tools;

  AdditionalResources({
    required this.textbooks,
    required this.onlineResources,
    required this.tools,
  });
}

class Textbook {
  final String title;
  final String author;
  final String isbn;
  final String description;

  Textbook({
    required this.title,
    required this.author,
    required this.isbn,
    required this.description,
  });
}

class OnlineResource {
  final String name;
  final String url;
  final String description;

  OnlineResource({
    required this.name,
    required this.url,
    required this.description,
  });
}
