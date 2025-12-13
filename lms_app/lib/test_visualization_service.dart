import 'services/groq_service.dart';
import 'services/code_visualization_service.dart';
import 'utils/constants.dart';

void main() async {
  print('=== Code Visualization Service Test ===');

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

    print('\n--- Test 1: Execution Visualization ---');
    final visualization = await visualizationService.generateExecutionVisualization(
      code:
          'def add(a, b):\n    return a + b\n\nresult = add(3, 5)\nprint(result)',
      language: 'Python',
    );
    print('Visualization: $visualization');

    print('\n--- Test 2: Debugging Guide ---');
    final debugGuide = await visualizationService.generateDebuggingGuide(
      code: 'print("Hello, World!"', // Missing closing parenthesis
      language: 'Python',
      errorOutput: 'SyntaxError: unexpected EOF while parsing',
    );
    print('Debug Guide: $debugGuide');

    print('\n--- Test 3: Interactive Learning ---');
    final learningContent = await visualizationService
        .generateInteractiveLearning(
          code: 'for i in range(5):\n    print(f"Number: {i}")',
          language: 'Python',
          executionOutput:
              'Number: 0\nNumber: 1\nNumber: 2\nNumber: 3\nNumber: 4',
        );
    print('Learning Content: $learningContent');

    print('\n=== All tests completed successfully ===');
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
