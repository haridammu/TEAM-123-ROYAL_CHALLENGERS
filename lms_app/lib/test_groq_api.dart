import 'services/groq_service.dart';
import 'utils/constants.dart';

void main() async {
  print('=== Groq API Test ===');

  // Test with the API key from constants
  final apiKey = AppConstants.groqApiKey;
  print('Using API key length: ${apiKey.length}');

  if (apiKey.isEmpty || !apiKey.startsWith('gsk_')) {
    print(
      'ERROR: Please configure your actual Groq API key in lib/utils/constants.dart',
    );
    print('Get your API key from: https://console.groq.com/');
    print('Current API key: "${apiKey}"');
    return;
  }

  try {
    final groqService = GroqService(apiKey: apiKey);

    print('\n--- Test: Simple message ---');
    final response = await groqService.sendMessage('Hello, what is 2+2?');
    print('Response: $response');

    print('\n=== Test completed successfully ===');
  } catch (e, stackTrace) {
    print('ERROR: $e');
    print('Stack trace: $stackTrace');

    if (e.toString().contains('401') ||
        e.toString().contains('Invalid API Key') ||
        e.toString().contains('authorization failed')) {
      print('\n>>> API KEY ISSUE DETECTED <<<');
      print(
        'Please make sure you have entered a valid Groq API key in constants.dart',
      );
      print('Get your free API key at: https://console.groq.com/');
      print('Current API key length: ${apiKey.length}');
    }
  }
}
