import 'package:flutter/material.dart';
import 'course_detail_screen.dart';

class CourseSearchScreen extends StatefulWidget {
  const CourseSearchScreen({super.key});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _popularCourses = [
    'Python Programming',
    'Web Development',
    'Data Science',
    'Machine Learning',
    'Mobile App Development',
    'Cybersecurity',
    'Digital Marketing',
    'Graphic Design',
  ];
  String _errorMessage = '';

  void _searchCourse() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a course topic';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
    });

    // Navigate to course detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(courseTopic: query),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Course Finder'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discover Courses with AI',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter any topic and our AI will create a comprehensive course for you',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for a course...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchCourse(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchCourse,
                  child: const Text('Search'),
                ),
              ],
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 24),

            // Popular courses
            const Text(
              'Popular Courses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: _popularCourses.length,
                itemBuilder: (context, index) {
                  return _buildCourseCard(_popularCourses[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(String courseName) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          _searchController.text = courseName;
          _searchCourse();
        },
        child: Center(
          child: Text(
            courseName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
