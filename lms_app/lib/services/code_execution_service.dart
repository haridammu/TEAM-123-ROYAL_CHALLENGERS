import 'dart:convert';
import 'package:http/http.dart' as http;

class CodeExecutionService {
  final String baseUrl =
      'https://9qcb6b3j-8000.inc1.devtunnels.ms/api/code/'; // Local development server

  CodeExecutionService();

  /// Constructs a proper URL by combining the base URL with the endpoint
  /// This ensures no double slashes occur
  String _buildUrl(String endpoint) {
    // Remove trailing slash from base URL if present
    String cleanBaseUrl = baseUrl;
    if (cleanBaseUrl.endsWith('/')) {
      cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length - 1);
    }

    // Remove leading slash from endpoint if present
    String cleanEndpoint = endpoint;
    if (cleanEndpoint.startsWith('/')) {
      cleanEndpoint = cleanEndpoint.substring(1);
    }

    // Combine them with a single slash
    return '$cleanBaseUrl/$cleanEndpoint';
  }

  Future<Map<String, dynamic>> executeCode({
    required String language,
    required String code,
  }) async {
    try {
      // Validate inputs
      if (code.trim().isEmpty) {
        return {'success': false, 'error': 'Code cannot be empty'};
      }

      if (language.trim().isEmpty) {
        return {'success': false, 'error': 'Language must be selected'};
      }

      final url = Uri.parse(_buildUrl('execute/'));
      print('Executing code at URL: $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'language': language, 'code': code}),
      );

      print('Code execution response status: ${response.statusCode}');
      print('Code execution response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(decodedBody);
        return {'success': true, 'data': jsonData};
      } else if (response.statusCode == 400) {
        return {'success': false, 'error': 'Invalid code or language'};
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'error': 'Server error. Code execution service unavailable.',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to execute code: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Code execution error: $e');
      return {
        'success': false,
        'error': 'Network error: Unable to connect to code execution service',
      };
    }
  }

  Future<Map<String, dynamic>> getUserSnippets() async {
    try {
      final url = Uri.parse(_buildUrl('snippets/'));
      print('Fetching snippets from URL: $url');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(decodedBody);
        return {'success': true, 'data': jsonData};
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'error': 'Server error. Please try again later.',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch snippets: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Error fetching snippets: $e');
      return {
        'success': false,
        'error': 'Network error: Unable to connect to code execution service',
      };
    }
  }

  Future<Map<String, dynamic>> saveSnippet({
    required String language,
    required String code,
    required String title,
  }) async {
    try {
      final url = Uri.parse(_buildUrl('snippets/save/'));
      print('Saving snippet to URL: $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'language': language, 'code': code, 'title': title}),
        encoding: utf8,
      );

      if (response.statusCode == 201) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(decodedBody);
        return {'success': true, 'data': jsonData};
      } else if (response.statusCode == 400) {
        return {'success': false, 'error': 'Invalid snippet data'};
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'error': 'Server error. Please try again later.',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to save snippet: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('Error saving snippet: $e');
      return {
        'success': false,
        'error': 'Network error: Unable to connect to code execution service',
      };
    }
  }
}
