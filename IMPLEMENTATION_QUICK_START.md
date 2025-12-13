# Flutter LMS Implementation - Step-by-Step Guide

## 📋 Current Status

### ✅ Completed
- Database schema (`SUPABASE_COMPLETE_SCHEMA.sql`)
- Authentication service
- Storage service
- User profile handling
- Basic structure for all services

### 🔄 Needs Enhancement  
All services exist but need proper method implementations using Supabase Dart SDK

### ❌ Not Implemented
- Screen integrations with services
- Real-time chat subscriptions
- Payment processing
- Proctoring system
- Analytics engine

---

## 🚀 IMMEDIATE NEXT STEPS (Today)

### Step 1: Verify Database Schema
Execute this in Supabase SQL Editor:

```sql
-- Copy entire contents of SUPABASE_COMPLETE_SCHEMA.sql
-- Paste into Supabase SQL Editor
-- Click Run
-- Verify all tables created successfully
```

**Expected Result:** 30+ tables created with RLS policies

---

### Step 2: Fix/Enhance ChatService for Real-Time

Open `/lms_app/lib/services/chat_service.dart` and add:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ChatService {
  final SupabaseService _supabaseService = SupabaseService();
  late final SupabaseClient _supabase = _supabaseService.client;

  // Subscribe to messages in real-time
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((error) {
          print('[ChatService] Real-time subscription error: $error');
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
      print('[ChatService] Message sent to room: $roomId');
    } catch (e) {
      print('[ChatService] Error sending message: $e');
      rethrow;
    }
  }

  // Get chat rooms for user
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
      
      return List<Map<String, dynamic>>.from(response).reversed.toList();
    } catch (e) {
      print('[ChatService] Error fetching messages: $e');
      return [];
    }
  }
}
```

---

### Step 3: Enhance PaymentService

Open `/lms_app/lib/services/payment_service.dart`:

```dart
import 'supabase_service.dart';

class PaymentService {
  final SupabaseService _supabaseService = SupabaseService();
  late final _supabase = _supabaseService.client;

  // Get subscription plans
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final response = await _supabase
          .from('subscription_plans')
          .select()
          .order('price', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[PaymentService] Error fetching plans: $e');
      return [];
    }
  }

  // Create subscription
  Future<void> createSubscription(
    String userId,
    String planId,
    String paymentMethodId,
  ) async {
    try {
      // This would integrate with Stripe/Razorpay
      // For now, just create subscription record
      await _supabase.from('subscriptions').insert({
        'user_id': userId,
        'plan_id': planId,
        'status': 'active',
        'started_at': DateTime.now().toIso8601String(),
        'renewal_date': DateTime.now()
            .add(Duration(days: 30))
            .toIso8601String(),
      });
      
      print('[PaymentService] Subscription created for user: $userId');
    } catch (e) {
      print('[PaymentService] Error creating subscription: $e');
      rethrow;
    }
  }

  // Get user's active subscription
  Future<Map<String, dynamic>?> getActiveSubscription(String userId) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select('*, subscription_plans(*)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('[PaymentService] Error fetching subscription: $e');
      return null;
    }
  }

  // Check subscription is valid
  Future<bool> isSubscriptionActive(String userId) async {
    try {
      final subscription = await getActiveSubscription(userId);
      if (subscription == null) return false;

      final renewalDate = DateTime.parse(subscription['renewal_date']);
      return DateTime.now().isBefore(renewalDate);
    } catch (e) {
      return false;
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    try {
      await _supabase
          .from('subscriptions')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('status', 'active');
      
      print('[PaymentService] Subscription cancelled for user: $userId');
    } catch (e) {
      print('[PaymentService] Error cancelling subscription: $e');
      rethrow;
    }
  }
}
```

---

### Step 4: Create PermissionService

Create `/lms_app/lib/services/permission_service.dart`:

```dart
import 'supabase_service.dart';

class PermissionService {
  final SupabaseService _supabaseService = SupabaseService();
  late final _supabase = _supabaseService.client;

  // Check if user has specific role
  Future<bool> hasRole(String userId, String roleName) async {
    try {
      final response = await _supabase
          .from('user_roles')
          .select('roles(name)')
          .eq('user_id', userId)
          .then((data) {
            return data.any((item) => 
              item['roles']['name']?.toString().toLowerCase() == 
              roleName.toLowerCase()
            );
          });
      
      return response;
    } catch (e) {
      print('[PermissionService] Error checking role: $e');
      return false;
    }
  }

  // Get all user roles
  Future<List<String>> getUserRoles(String userId) async {
    try {
      final response = await _supabase
          .from('user_roles')
          .select('roles(name)')
          .eq('user_id', userId);
      
      return response
          .map((item) => item['roles']['name'] as String)
          .toList();
    } catch (e) {
      print('[PermissionService] Error fetching user roles: $e');
      return [];
    }
  }

  // Quick role checks
  Future<bool> isAdmin(String userId) => hasRole(userId, 'admin');
  Future<bool> isInstructor(String userId) => hasRole(userId, 'instructor');
  Future<bool> isStudent(String userId) => hasRole(userId, 'student');

  // Check if can edit course
  Future<bool> canEditCourse(String userId, String courseId) async {
    try {
      // Check if admin or course instructor
      if (await isAdmin(userId)) return true;

      final response = await _supabase
          .from('courses')
          .select()
          .eq('id', courseId)
          .eq('instructor_id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Check if can grade quiz
  Future<bool> canGradeQuiz(String userId, String quizId) async {
    try {
      if (await isAdmin(userId)) return true;

      // Get quiz's course, then check if user is instructor
      final response = await _supabase
          .from('quizzes')
          .select('course_id')
          .eq('id', quizId)
          .single();

      return canEditCourse(userId, response['course_id']);
    } catch (e) {
      return false;
    }
  }

  // Check if can access admin panel
  Future<bool> canAccessAdminPanel(String userId) => isAdmin(userId);
}
```

---

### Step 5: Create AnalyticsService

Create `/lms_app/lib/services/analytics_service.dart`:

```dart
import 'supabase_service.dart';

class AnalyticsService {
  final SupabaseService _supabaseService = SupabaseService();
  late final _supabase = _supabaseService.client;

  // Log user activity
  Future<void> logActivity(
    String userId,
    String activityType,
    String? courseId,
    String? relatedId,
  ) async {
    try {
      await _supabase.from('user_activities').insert({
        'user_id': userId,
        'activity_type': activityType,
        'course_id': courseId,
        'related_id': relatedId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[AnalyticsService] Error logging activity: $e');
    }
  }

  // Get user activity history
  Future<List<Map<String, dynamic>>> getUserActivityHistory(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final response = await _supabase
          .from('user_activities')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[AnalyticsService] Error fetching activity history: $e');
      return [];
    }
  }

  // Get course completion rate
  Future<double> getCourseCompletionRate(String courseId) async {
    try {
      // Get total enrollments
      final enrollments = await _supabase
          .from('course_enrollments')
          .select('COUNT', const QueryOption(count: CountOption.exact))
          .eq('course_id', courseId);

      // Get completed enrollments
      final completed = await _supabase
          .from('course_enrollments')
          .select('COUNT', const QueryOption(count: CountOption.exact))
          .eq('course_id', courseId)
          .eq('completed', true);

      final totalCount = enrollments.length;
      final completedCount = completed.length;

      if (totalCount == 0) return 0;
      return (completedCount / totalCount) * 100;
    } catch (e) {
      print('[AnalyticsService] Error calculating completion rate: $e');
      return 0;
    }
  }

  // Get average quiz score for course
  Future<double> getAverageQuizScore(String courseId) async {
    try {
      final response = await _supabase
          .from('quiz_attempts')
          .select('percentage')
          .eq('quiz_id', courseId); // Assuming quiz_id or get via course
      
      if (response.isEmpty) return 0;

      final total = response
          .map((item) => item['percentage'] as int)
          .reduce((a, b) => a + b);
      
      return total / response.length;
    } catch (e) {
      print('[AnalyticsService] Error calculating average score: $e');
      return 0;
    }
  }
}
```

---

## 📱 Screen Integration Examples

### Example 1: Chat Screen with Real-Time Updates

```dart
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class RealtimeChatScreen extends StatefulWidget {
  final String roomId;
  final String userId;

  const RealtimeChatScreen({
    required this.roomId,
    required this.userId,
  });

  @override
  State<RealtimeChatScreen> createState() => _RealtimeChatScreenState();
}

class _RealtimeChatScreenState extends State<RealtimeChatScreen> {
  late ChatService _chatService;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          // Messages list with real-time subscription
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.subscribeToMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['user_id'] == widget.userId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['content'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () async {
                    final content = _messageController.text;
                    if (content.isNotEmpty) {
                      await _chatService.sendMessage(
                        widget.roomId,
                        widget.userId,
                        content,
                      );
                      _messageController.clear();
                    }
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
```

### Example 2: Quiz Attempt Screen

```dart
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';

class QuizAttemptScreen extends StatefulWidget {
  final String quizId;
  final String userId;

  const QuizAttemptScreen({
    required this.quizId,
    required this.userId,
  });

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  late QuizService _quizService;
  late Future<Map<String, dynamic>> _quizFuture;
  late String _attemptId;
  Map<String, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    // Start quiz attempt
    _attemptId = await _quizService.startQuizAttempt(
      widget.userId,
      widget.quizId,
    );
    
    // Load quiz details
    _quizFuture = _quizService.getQuizDetails(widget.quizId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final quiz = snapshot.data!;
          final questions = quiz['questions'] as List;

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    quiz['title'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ...List.generate(
                  questions.length,
                  (index) => _buildQuestionWidget(
                    questions[index],
                    index,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _submitQuiz,
                    child: const Text('Submit Quiz'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question, int index) {
    final choices = question['choices'] as List;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1}: ${question['text']}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...List.generate(
              choices.length,
              (choiceIndex) => RadioListTile<String>(
                title: Text(choices[choiceIndex]['text'] ?? ''),
                value: choices[choiceIndex]['id'],
                groupValue: _answers[question['id']],
                onChanged: (value) {
                  setState(() {
                    _answers[question['id']] = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitQuiz() async {
    // Submit all answers
    for (var questionId in _answers.keys) {
      await _quizService.submitAnswer(
        _attemptId,
        questionId,
        _answers[questionId]!,
      );
    }

    // Complete quiz
    final result = await _quizService.submitQuizAttempt(_attemptId);

    if (mounted) {
      Navigator.pop(context, result);
    }
  }
}
```

---

## 📊 Testing Services

Test each service independently:

```dart
// Test course service
void testCourseService() async {
  final courseService = CourseService();
  
  // Test getting courses
  final courses = await courseService.getCoursesList();
  print('Courses loaded: ${courses.length}');
  
  // Test getting course details
  final course = await courseService.getCoursesDetail(courses[0]['id']);
  print('Course: ${course['title']}');
}

// Test gamification service
void testGamificationService() async {
  final gamService = GamificationService();
  
  // Test adding points
  await gamService.addPoints('user123', 50, 'quiz_pass');
  
  // Test getting points
  final points = await gamService.getUserTotalPoints('user123');
  print('Total points: $points');
  
  // Test leaderboard
  final leaderboard = await gamService.getGlobalLeaderboard();
  print('Top users: ${leaderboard.length}');
}
```

---

## 🎯 Implementation Priority

### Week 1: Foundation
- [x] Database schema ready
- [ ] ChatService real-time working
- [ ] PaymentService complete
- [ ] PermissionService complete

### Week 2: Screens Integration
- [ ] Chat screens using real-time
- [ ] Quiz screens with services
- [ ] Course screens with services
- [ ] Leaderboard screens

### Week 3: Features
- [ ] Complete flow testing
- [ ] Error handling refinement
- [ ] Performance optimization

---

## 📞 Quick Reference

**All Services Location:** `/lms_app/lib/services/`

**All Screens Location:** `/lms_app/lib/screens/`

**Database Schema:** `SUPABASE_COMPLETE_SCHEMA.sql`

**Implementation Guide:** `FLUTTER_SUPABASE_IMPLEMENTATION_SUMMARY.md`

Good luck! 🚀
