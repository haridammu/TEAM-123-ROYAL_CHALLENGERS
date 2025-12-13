# Next 48 Hours: Core Feature Implementation

## 🎯 Goal
Get Courses, Quizzes, and Chat fully functional and integrated with UI

---

## 📋 Task List

### TASK 1: Enhance CourseService (6-8 Hours)
**File:** `lms_app/lib/services/course_service.dart`

**What to Add:**

```dart
// 1. Get all courses with pagination and filtering
Future<Map<String, dynamic>> getAllCourses({
  int page = 1,
  int pageSize = 10,
  String? category,
  String? searchQuery,
  String sortBy = 'created_at',
}) async {
  try {
    var query = _supabase
        .from('courses')
        .select('*, modules(count)');
    
    // Apply filters
    if (category != null) {
      query = query.eq('category', category);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('title', '%$searchQuery%');
    }
    
    // Apply sorting and pagination
    query = query.order(sortBy, ascending: false);
    
    final offset = (page - 1) * pageSize;
    final response = await query.range(offset, offset + pageSize - 1);
    
    return {
      'courses': response,
      'page': page,
      'pageSize': pageSize,
      'total': response.length,
    };
  } catch (e) {
    print('[CourseService] Error fetching courses: $e');
    throw Exception('Failed to load courses: $e');
  }
}

// 2. Get user's enrolled courses
Future<List<Map<String, dynamic>>> getMyEnrolledCourses(String userId) async {
  try {
    final response = await _supabase
        .from('course_enrollments')
        .select('*, courses(*), lesson_progress(count)')
        .eq('user_id', userId);
    
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('[CourseService] Error fetching enrolled courses: $e');
    throw Exception('Failed to load enrolled courses: $e');
  }
}

// 3. Check if user is enrolled
Future<bool> isEnrolled(String userId, String courseId) async {
  try {
    final response = await _supabase
        .from('course_enrollments')
        .select()
        .eq('user_id', userId)
        .eq('course_id', courseId)
        .maybeSingle();
    
    return response != null;
  } catch (e) {
    return false;
  }
}

// 4. Get lesson with content
Future<Map<String, dynamic>> getLessonDetails(String lessonId) async {
  try {
    final response = await _supabase
        .from('lessons')
        .select()
        .eq('id', lessonId)
        .single();
    
    return response;
  } catch (e) {
    print('[CourseService] Error fetching lesson: $e');
    throw Exception('Failed to load lesson: $e');
  }
}

// 5. Mark lesson complete
Future<void> markLessonComplete(String userId, String lessonId) async {
  try {
    await _supabase.from('lesson_progress').upsert({
      'user_id': userId,
      'lesson_id': lessonId,
      'completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    });
    
    print('[CourseService] Lesson marked complete: $lessonId');
  } catch (e) {
    print('[CourseService] Error marking lesson complete: $e');
    rethrow;
  }
}

// 6. Update watch time
Future<void> updateWatchTime(
  String userId,
  String lessonId,
  int watchTimeSeconds,
) async {
  try {
    await _supabase.from('lesson_progress').upsert({
      'user_id': userId,
      'lesson_id': lessonId,
      'watch_time_seconds': watchTimeSeconds,
      'last_watched_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    print('[CourseService] Error updating watch time: $e');
  }
}

// 7. Get course stats
Future<Map<String, dynamic>> getCourseStats(String courseId) async {
  try {
    // Get enrollment count
    final enrollments = await _supabase
        .from('course_enrollments')
        .select()
        .eq('course_id', courseId);
    
    // Get completion rate
    final completedEnrollments = await _supabase
        .from('course_enrollments')
        .select()
        .eq('course_id', courseId)
        .eq('completed', true);
    
    final totalEnrolled = enrollments.length;
    final totalCompleted = completedEnrollments.length;
    final completionRate = totalEnrolled > 0
        ? ((totalCompleted / totalEnrolled) * 100).toInt()
        : 0;
    
    return {
      'totalEnrollments': totalEnrolled,
      'completedEnrollments': totalCompleted,
      'completionRate': completionRate,
    };
  } catch (e) {
    print('[CourseService] Error getting course stats: $e');
    return {
      'totalEnrollments': 0,
      'completedEnrollments': 0,
      'completionRate': 0,
    };
  }
}

// 8. Search courses
Future<List<Map<String, dynamic>>> searchCourses(String query) async {
  try {
    final response = await _supabase
        .from('courses')
        .select()
        .ilike('title', '%$query%')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('[CourseService] Error searching courses: $e');
    return [];
  }
}
```

---

### TASK 2: Complete QuizService (4-6 Hours)
**File:** `lms_app/lib/services/quiz_service.dart`

**What's Already There:** Basic quiz listing and fetching

**What to Enhance:**

```dart
// Already complete in the file, verify these work:
// - startQuizAttempt()
// - submitAnswer()
// - submitQuizAttempt() with scoring
// - getQuizLeaderboard()
// - getQuizStatistics()

// Verify they call the correct database methods
// Test with sample quiz data
```

---

### TASK 3: Implement ChatService Real-Time (3-4 Hours)
**File:** `lms_app/lib/services/chat_service.dart`

**Add Stream Support:**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseService _supabaseService = SupabaseService();
  late final SupabaseClient _supabase = _supabaseService.client;

  // Real-time message subscription
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((error) {
          print('[ChatService] Stream error: $error');
        });
  }

  // Send message
  Future<void> sendMessage(
    String roomId,
    String userId,
    String content, {
    String? mediaUrl,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'room_id': roomId,
        'user_id': userId,
        'content': content,
        'media_url': mediaUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[ChatService] Error sending message: $e');
      rethrow;
    }
  }

  // Get message history
  Future<List<Map<String, dynamic>>> getMessageHistory(
    String roomId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response)
          .reversed
          .toList();
    } catch (e) {
      print('[ChatService] Error fetching messages: $e');
      return [];
    }
  }

  // Get user's chat rooms
  Future<List<Map<String, dynamic>>> getUserChatRooms(String userId) async {
    try {
      final response = await _supabase
          .from('chat_room_members')
          .select('*, chat_rooms(*)')
          .eq('user_id', userId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[ChatService] Error fetching chat rooms: $e');
      return [];
    }
  }
}
```

---

### TASK 4: Create CourseDetailScreen (3-4 Hours)
**File:** `lms_app/lib/screens/course_detail_screen.dart`

**Template:**

```dart
import 'package:flutter/material.dart';
import '../services/course_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late CourseService _courseService;
  late Future<Map<String, dynamic>> _courseFuture;
  bool _isEnrolled = false;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _courseService = CourseService();
    _courseFuture = _courseService.getCourseDetails(widget.courseId);
    _checkEnrollment();
  }

  Future<void> _checkEnrollment() async {
    // Get current user ID from auth service
    final isEnrolled = await _courseService.isEnrolled('userId', widget.courseId);
    setState(() => _isEnrolled = isEnrolled);
  }

  Future<void> _enrollCourse() async {
    setState(() => _isEnrolling = true);
    try {
      await _courseService.enrollInCourse(
        userId: 'userId',
        courseId: widget.courseId,
      );
      setState(() => _isEnrolled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrolled successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _courseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final course = snapshot.data!;
          final modules = course['modules'] as List? ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  color: Colors.blue,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'] ?? 'No Title',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course['description'] ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                
                // Enroll Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _isEnrolling || _isEnrolled ? null : _enrollCourse,
                    child: Text(_isEnrolled ? 'Already Enrolled' : 'Enroll Now'),
                  ),
                ),

                // Modules
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Content',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        modules.length,
                        (index) => Card(
                          child: ListTile(
                            title: Text(modules[index]['title'] ?? 'Module'),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: _isEnrolled
                                ? () {
                                    // Navigate to lessons
                                  }
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

### TASK 5: Create QuizAttemptScreen (3-4 Hours)
**File:** `lms_app/lib/screens/quiz_attempt_screen.dart`

**Key Features:**
- Display questions one at a time
- Show timer
- Multiple choice options
- Navigation between questions
- Submit button

```dart
// See IMPLEMENTATION_QUICK_START.md for complete example
```

---

## ⏱️ Timeline

| Time | Task | Estimated |
|------|------|-----------|
| Day 1 AM | Enhance CourseService | 4-5 hours |
| Day 1 PM | Create CourseDetailScreen | 3-4 hours |
| Day 2 AM | Complete QuizService | 2-3 hours |
| Day 2 PM | Create QuizAttemptScreen | 3-4 hours |
| Anytime | Implement ChatService | 3-4 hours |

---

## ✅ Validation Checklist

After implementing each task:

- [ ] Code compiles without errors
- [ ] Test with real Supabase data
- [ ] Error handling works (bad network, missing data)
- [ ] Screens display correctly
- [ ] Data persists after app restart
- [ ] Real-time updates work (for chat)

---

## 📞 Key Code Snippets Ready to Use

### Getting Current User ID
```dart
final user = Supabase.instance.client.auth.currentUser;
final userId = user?.id ?? '';
```

### Testing Service Directly
```dart
void testCourse() async {
  final courseService = CourseService();
  final courses = await courseService.getAllCourses();
  print('Found ${courses['courses'].length} courses');
}
```

---

Good luck! Focus on getting one feature complete and working before moving to the next. 🚀
