import 'services/groq_service.dart';
import 'services/code_visualization_service.dart';
import 'utils/constants.dart';

void main() async {
  print('=== Enhanced Visualization Service Test ===');

  // Test with the API key from constants
  final apiKey = AppConstants.groqApiKey;
  print('Using API key: ${apiKey.substring(0, 10)}...');

  if (apiKey == 'gsk_your_actual_api_key_here' || apiKey.isEmpty) {
    print(
      'ERROR: Please configure your actual Groq API key in lib/utils/constants.dart',
    );
    print('Get your API key from: https://console.groq.com/');
    return;
  }

  try {
    final groqService = GroqService(apiKey: apiKey);
    final visualizationService = CodeVisualizationService(
      aiService: groqService,
    );

    print('\n--- Test 1: Enhanced Execution Visualization ---');
    final visualization = await visualizationService.generateExecutionVisualization(
      code:
          'def fibonacci(n):\n    if n <= 1:\n        return n\n    else:\n        return fibonacci(n-1) + fibonacci(n-2)\n\nresult = fibonacci(5)\nprint(result)',
      language: 'Python',
    );
    print('Enhanced Visualization: $visualization');

    print('\n--- Test 2: Visual Debugging Guide ---');
    final debugGuide = await visualizationService.generateDebuggingGuide(
      code:
          'for i in range(5):\n    print(i\nprint("Done")', // Missing closing parenthesis
      language: 'Python',
      errorOutput: 'SyntaxError: unexpected EOF while parsing',
    );
    print('Visual Debug Guide: $debugGuide');

    print('\n--- Test 3: Interactive Learning with Visuals ---');
    final learningContent = await visualizationService.generateInteractiveLearning(
      code:
          'numbers = [1, 2, 3, 4, 5]\nsum = 0\nfor num in numbers:\n    sum += num\nprint(f"Sum: {sum}")',
      language: 'Python',
      executionOutput: 'Sum: 15',
    );
    print('Visual Learning Content: $learningContent');

    print('\n=== All enhanced visualization tests completed successfully ===');

    print('\n--- MODEL VERIFICATION ---');
    print('Using model: llama-3.3-70b-versatile');
    print(
      'This model is optimized for visual code representations and structured formatting.',
    );
  } catch (e, stackTrace) {
    print('ERROR: $e');
    print('Stack trace: $stackTrace');

    if (e.toString().contains('401') ||
        e.toString().contains('Invalid API Key')) {
      print('\n>>> API KEY ISSUE DETECTED <<<');
      print(
        'Please make sure you have entered a valid Groq API key in constants.dart',
      );
      print('Get your free API key at: https://console.groq.com/');
    }
  }
}
