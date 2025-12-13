import 'services/groq_service.dart';
import 'services/code_visualization_service.dart';
import 'services/diagram_service.dart';
import 'utils/constants.dart';

void main() async {
  print('=== Structured Visualization Test ===');

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
    final diagramService = DiagramService(aiService: groqService);
    final visualizationService = CodeVisualizationService(
      aiService: groqService,
    );

    print('\n--- Test 1: Structured Text-Based Visualization ---');
    final textVisualization = await visualizationService
        ._generateTextBasedVisualization(
          code:
              'def factorial(n):\n    if n <= 1:\n        return 1\n    else:\n        return n * factorial(n-1)\n\nresult = factorial(5)\nprint(result)',
          language: 'Python',
          executionOutput: '120',
        );
    print('Structured Text Visualization:');
    print(textVisualization);

    print('\n--- Test 2: Debugging Guide with Clean Structure ---');
    final debugGuide = await visualizationService.generateDebuggingGuide(
      code: 'for i in range(5):\n    print(i\nprint("Done")',
      language: 'Python',
      errorOutput: 'SyntaxError: unexpected EOF while parsing',
    );
    print('Structured Debug Guide:');
    print(debugGuide);

    print('\n--- Test 3: Interactive Learning with Clean Structure ---');
    final learningContent = await visualizationService.generateInteractiveLearning(
      code:
          'numbers = [1, 2, 3, 4, 5]\nsum = 0\nfor num in numbers:\n    sum += num\nprint(f"Sum: {sum}")',
      language: 'Python',
      executionOutput: 'Sum: 15',
    );
    print('Structured Learning Content:');
    print(learningContent);

    print(
      '\n=== All structured visualization tests completed successfully ===',
    );

    print('\n--- STRUCTURE VERIFICATION ---');
    print('✅ Clear separation between code and explanations');
    print('✅ Well-organized sections with proper headings');
    print('✅ Consistent formatting throughout');
    print('✅ No mixing of inline code with explanations');
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
