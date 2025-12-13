import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course.dart';

class CourseService {
  static const String baseUrl =
      'https://9qcb6b3j-8000.inc1.devtunnels.ms/api/courses';
  final String? token;

  CourseService({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  // Get all courses
  Future<List<Course>> getCourses() async {
    final url = Uri.parse(baseUrl); // Remove the extra slash
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Course.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load courses');
    }
  }

  // Get course by ID
  Future<Course> getCourse(int id) async {
    final url = Uri.parse('$baseUrl$id/'); // Remove the extra slash
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Course.fromJson(data);
    } else {
      throw Exception('Failed to load course');
    }
  }

  // Get modules for a course
  Future<List<Module>> getModules(int courseId) async {
    final url = Uri.parse(
      '${baseUrl}modules/?course=$courseId',
    ); // Remove extra slash
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Module.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load modules');
    }
  }

  // Get lessons for a module
  Future<List<Lesson>> getLessons(int moduleId) async {
    final url = Uri.parse(
      '${baseUrl}lessons/?module=$moduleId',
    ); // Remove extra slash
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Lesson.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load lessons');
    }
  }

  // Enroll in a course
  Future<Enrollment> enrollInCourse(int courseId) async {
    final url = Uri.parse('${baseUrl}enroll/'); // Remove extra slash
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'course': courseId}),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Enrollment.fromJson(data);
    } else {
      throw Exception('Failed to enroll in course');
    }
  }

  // Get user enrollments
  Future<List<Enrollment>> getUserEnrollments() async {
    final url = Uri.parse('${baseUrl}enrollments/'); // Remove extra slash
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Enrollment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load enrollments');
    }
  }
}
