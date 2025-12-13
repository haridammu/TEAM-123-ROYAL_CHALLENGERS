import 'services/groq_service.dart';
import 'services/code_ai_service.dart';
import 'utils/constants.dart';

void main() async {
  print('=== Code AI Service Test ===');

  // Test with the API key from constants
  final apiKey = AppConstants.groqApiKey;
  print('Using API key: ${apiKey.substring(0, 10)}...');

  if (apiKey == 'YOUR_GROQ_API_KEY_HERE' || apiKey.isEmpty) {
    print(
      'ERROR: Please configure your Groq API key in lib/utils/constants.dart',
    );
    return;
  }

  try {
    final groqService = GroqService(apiKey: apiKey);
    final codeAiService = CodeAIService(aiService: groqService);

    print('\n--- Test 1: Code Explanation ---');
    final explanation = await codeAiService.explainCode(
      code: 'print("Hello, World!")',
      language: 'Python',
    );
    print('Explanation: $explanation');

    print('\n--- Test 2: Code Generation ---');
    final generatedCode = await codeAiService.generateCode(
      description: 'Create a function that adds two numbers',
      language: 'Python',
    );
    print('Generated Code: $generatedCode');

    print('\n--- Test 3: Code Correction ---');
    final correction = await codeAiService.correctCode(
      code: 'print("Hello, World!"', // Missing closing parenthesis
      language: 'Python',
      errorOutput: 'SyntaxError: unexpected EOF while parsing',
    );
    print('Correction: $correction');

    print('\n=== All tests completed successfully ===');
  } catch (e, stackTrace) {
    print('ERROR: $e');
    print('Stack trace: $stackTrace');
  }
}
