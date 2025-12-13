import 'package:flutter/material.dart';

import '../models/course.dart';

import '../services/course_service.dart';

class CoursesScreen extends StatefulWidget {
  final String? token;

  const CoursesScreen({super.key, this.token});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late CourseService _courseService;
  List<Course> _courses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _courseService = CourseService(token: widget.token);
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _courseService.getCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load courses: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCourses,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadCourses,
                child: ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(
                            Icons.school,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(
                          course.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(course.description),
                            const SizedBox(height: 4),
                            Text(
                              '\$${course.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Make the entire list tile tappable
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/course-detail',
                            arguments: {
                              'courseTopic':
                                  course
                                      .title, // Pass course title as topic for AI generation
                            },
                          );
                        },
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
      // Add a floating action button to navigate to the course search screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/course-search');
        },
        child: const Icon(Icons.search),
        tooltip: 'Search Courses',
      ),
    );
  }
}
