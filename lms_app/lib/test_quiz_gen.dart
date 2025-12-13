import 'package:lms_app/services/ai_course_service.dart';
import 'package:lms_app/services/groq_service.dart';
import 'package:lms_app/utils/constants.dart';

void main() async {
  print('Testing Quiz Generation...');
  final groqService = GroqService(apiKey: AppConstants.groqApiKey);
  final aiCourseService = AICourseService(aiService: groqService);

  try {
    print('Requesting quiz for "Python Basics"...');
    final quiz = await aiCourseService.generateFinalQuiz('Python Basics');
    
    print('Generated ${quiz.length} questions.');
    for (int i = 0; i < quiz.length; i++) {
      print('Q${i+1}: ${quiz[i].question}');
      print('   A) ${quiz[i].options[0]}');
      print('   B) ${quiz[i].options[1]}');
      print('   C) ${quiz[i].options[2]}');
      print('   D) ${quiz[i].options[3]}');
      print('   Ans Index: ${quiz[i].correctOptionIndex}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
