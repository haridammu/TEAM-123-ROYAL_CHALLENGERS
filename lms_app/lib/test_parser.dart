import 'services/ai_course_service.dart';
import 'services/groq_service.dart';

void main() async {
  print('Testing Curriculum Parsing with Mock Data');
  
  // Mock response simulating the new detailed prompt output
  final mockResponse = '''
## COURSE OVERVIEW
- **Title**: Web Development
- **Description**: Master Web Dev
- **Duration**: 20h
- **Skill Level**: All
- **Prerequisites**: None

## LEARNING OBJECTIVES
1. Obj 1
2. Obj 2

## COURSE MODULES
1. **HTML Structure**: Learn semantic HTML tags (1h) [https://www.youtube.com/watch?v=dQw4w9WgXcQ]
2. **CSS Styling**: Colors, fonts, and box model (2h)
3. **Flexbox & Grid**: Modern layouts (2h) https://youtu.be/dQw4w9WgXcQ
4. **JavaScript Basics**: Variables and functions (2h)
5. **DOM Manipulation**: APIs and events (2h)
8. **React State**: Hooks and state management (3h)
9. **Final Project**: Portfolio website (5h)

## GAMIFICATION CHALLENGES
1. **Challenge**: Fix the HTML tag
   **Initial Code**: <h1<Title>/h1>
   **Solution**: <h1>Title</h1>
2. **Challenge**: Fix CSS
   **Initial Code**: color: bloo;
   **Solution**: color: blue;

## ASSESSMENT METHODS
- Projects
''';

  final lines = mockResponse.split('\n');
  int moduleCount = 0;
  List<String> modules = [];
  
  // Minimal Mock Module link
  Map<int, String> challenges = {};

  String currentSection = '';
  // Parser State for Gamification
  int _pendingChallengeIndex = -1;
  String _pendingChallengeDesc = '';
  String _pendingInitialCode = '';
  String _pendingSolution = '';

  for (var line in lines) {
    line = line.trim();
    if (line == '## COURSE MODULES') {
      currentSection = 'modules';
      continue;
    } else if (line.startsWith('## GAMIFICATION')) {
      currentSection = 'gamification';
      continue;
    } else if (line.startsWith('## ASSESSMENT')) {
      currentSection = 'assessment';
    }
    
    if (currentSection == 'modules') {
       // Robust parsing logic
       String? aiUrl;
       final urlMatch = RegExp(r'https?://[^\s\]\)]+').firstMatch(line);
       if (urlMatch != null) {
          aiUrl = urlMatch.group(0);
       }

       final contentMatch = RegExp(r'^\d+\.\s*(?:\*\*)?(.*?)(?:\*\*)?:\s*(.*?)\s*\((.*?)\)').firstMatch(line);
       
       if (contentMatch != null) {
         moduleCount++;
         final rawTitle = contentMatch.group(1)!;
         final title = rawTitle.replaceAll('*', '').trim();
         
         print('Parsed Module: "$title" | URL: ${aiUrl ?? "None"}');
         modules.add(title);
       }
    } else if (currentSection == 'gamification') {
       final challengeMatch = RegExp(r'^(\d+)\.\s*\*\*(?:Challenge|Task)\*\*:\s*(.*)').firstMatch(line);
       if (challengeMatch != null) {
          final index = int.parse(challengeMatch.group(1)!) - 1;
          _pendingChallengeIndex = index;
          _pendingChallengeDesc = challengeMatch.group(2)!;
          challenges[index] = _pendingChallengeDesc;
          print('Found Challenge for Module ${index+1}: $_pendingChallengeDesc');
       }
       if (_pendingChallengeIndex != -1) {
          if (line.startsWith('**Initial Code**:')) {
             print('  Has Initial Code');
          }
       }
    }
  }
  
  print('Total Modules Parsed: $moduleCount');
    print('SUCCESS: Parsed all 9 modules correctly.');
  } else {
    print('FAILURE: Parsed $moduleCount modules. Expected 9.');
  }
}
