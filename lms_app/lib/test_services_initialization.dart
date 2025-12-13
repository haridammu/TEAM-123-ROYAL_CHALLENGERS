import 'services/groq_service.dart';
import 'services/code_ai_service.dart';
import 'services/code_visualization_service.dart';
import 'utils/constants.dart';

void main() async {
  print('=== Services Initialization Test ===');

  try {
    // Test GroqService initialization
    print('\n--- Testing GroqService ---');
    final groqService = GroqService(apiKey: AppConstants.groqApiKey);
    print('GroqService initialized successfully');

    // Test CodeAIService initialization
    print('\n--- Testing CodeAIService ---');
    final codeAiService = CodeAIService(aiService: groqService);
    print('CodeAIService initialized successfully');

    // Test CodeVisualizationService initialization
    print('\n--- Testing CodeVisualizationService ---');
    final visualizationService = CodeVisualizationService(
      aiService: groqService,
    );
    print('CodeVisualizationService initialized successfully');

    print('\n=== All services initialized successfully ===');

    // Test a simple API call if API key is valid
    if (AppConstants.groqApiKey != 'YOUR_GROQ_API_KEY_HERE' &&
        AppConstants.groqApiKey.isNotEmpty) {
      print('\n--- Testing API Connection ---');
      try {
        final response = await groqService.sendMessage('Hello, what is 2+2?');
        print('API test successful. Response: $response');
      } catch (e) {
        print('API test failed: $e');
      }
    } else {
      print('\n--- API Key Not Configured ---');
      print('Please configure your Groq API key in lib/utils/constants.dart');
      print('Get your free API key at: https://console.groq.com/');
    }
  } catch (e, stackTrace) {
    print('ERROR: $e');
    print('Stack trace: $stackTrace');
  }
}
