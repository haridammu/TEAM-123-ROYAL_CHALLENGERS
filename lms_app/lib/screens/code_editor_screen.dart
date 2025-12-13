import 'package:flutter/material.dart';
import '../services/code_execution_service.dart';
import '../services/code_ai_service.dart';
import '../services/code_visualization_service.dart';
import '../services/groq_service.dart';
import '../services/ai_course_service.dart';
import '../utils/constants.dart';

class CodeEditorScreen extends StatefulWidget {
  final dynamic userId;
  final GamificationChallenge? challenge;

  const CodeEditorScreen({super.key, required this.userId, this.challenge});

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen> {
  final List<Map<String, dynamic>> _languages = [
    {
      'name': 'Python',
      'value': 'python',
      'helloWorld': '''print("Hello, World!")''',
    },
    {
      'name': 'Java',
      'value': 'java',
      'helloWorld':
          '''public class Main {\n    public static void main(String[] args) {\n        System.out.println("Hello, World!");\n    }\n}''',
    },
    {
      'name': 'C',
      'value': 'c',
      'helloWorld':
          '''#include <stdio.h>\n\nint main() {\n    printf("Hello, World!");\n    return 0;\n}''',
    },
    {
      'name': 'C++',
      'value': 'cpp',
      'helloWorld':
          '''#include <iostream>\nusing namespace std;\n\nint main() {\n    cout << "Hello, World!";\n    return 0;\n}''',
    },
    {
      'name': 'JavaScript',
      'value': 'javascript',
      'helloWorld': '''console.log("Hello, World!");''',
    },
    {
      'name': 'Dart',
      'value': 'dart',
      'helloWorld': '''void main() {\n  print('Hello, World!');\n}''',
    },
  ];

  String _selectedLanguage = 'python';
  String _code = 'print("Hello, World!")';
  String _output = '';
  bool _isRunning = false;
  bool _isAiProcessing = false;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _aiPromptController = TextEditingController();
  late CodeExecutionService _codeService;
  late CodeAIService _codeAiService;
  late CodeVisualizationService _codeVisualizationService;

  @override
  void initState() {
    super.initState();
    _codeController.text = widget.challenge?.initialCode ?? _code;
    _code = widget.challenge?.initialCode ?? _code;
    
    if (widget.challenge != null) {
       _selectedLanguage = widget.challenge?.language ?? 'python';
    }
    
    _codeService = CodeExecutionService();

    // Initialize AI services with error handling
    try {
      final groqService = GroqService(apiKey: AppConstants.groqApiKey);
      _codeAiService = CodeAIService(aiService: groqService);
      _codeVisualizationService = CodeVisualizationService(
        aiService: groqService,
      );
    } catch (e) {
      print('Error initializing AI services: $e');
      // Initialize with dummy services if API key is invalid
      final fallbackService = GroqService(apiKey: 'dummy_key');
      _codeAiService = CodeAIService(aiService: fallbackService);
      _codeVisualizationService = CodeVisualizationService(
        aiService: fallbackService,
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  void _onLanguageChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedLanguage = newValue;
        // Set default code for the selected language
        final language = _languages.firstWhere(
          (lang) => lang['value'] == newValue,
          orElse: () => _languages[0],
        );
        _code = language['helloWorld'];
        _codeController.text = _code;
        _output = '';
      });
    }
  }

  Future<void> _executeCode() async {
    setState(() {
      _isRunning = true;
      _output = 'Running code...\n';
    });

    try {
      final result = await _codeService.executeCode(
        language: _selectedLanguage,
        code: _code,
      );

      if (result['success']) {
        final data = result['data'];
        final output = data['output'] ?? 'No output';
        
        setState(() {
          _output = output;
          _isRunning = false;
        });

        // GAMIFICATION CHECK
        if (widget.challenge != null) {
           // Normalize code for comparison (remove whitespace/newlines)
           final cleanUserCode = _code.replaceAll(RegExp(r'\s+'), '');
           final cleanSolution = widget.challenge!.solutionCode.replaceAll(RegExp(r'\s+'), '');
           
           // Also check if output matches expectation if we had it, but for now Code Match is requested "Unjumble"
           // Or we can ask AI to validate "Is this code correct?" (expensive)
           // Simple string match for "Jumbled Tags" is effective.
           
           if (cleanUserCode == cleanSolution || _code.trim() == widget.challenge!.solutionCode.trim()) {
              _showSuccessDialog();
           } else {
              // Should we show a hint?
              if (!output.toLowerCase().contains('error')) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Code ran successfully, but is not the correct solution yet! Try again.')),
                 );
              }
           }
        }

      } else {
        setState(() {
          _output = 'Error: ${result['error']}';
          _isRunning = false;
        });
      }
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
        _isRunning = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Challenge Completed!'),
        content: const Text('You fixed the code successfully!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Close screen with Success result
            },
            child: const Text('Next Module'),
          ),
        ],
      ),
    );
  }


  Future<void> _saveSnippet() async {
    if (_titleController.text.trim().isEmpty) {
      // Show dialog to enter title
      final title = await _showTitleInputDialog();
      if (title == null || title.trim().isEmpty) {
        return;
      }
      _titleController.text = title;
    }

    try {
      final result = await _codeService.saveSnippet(
        language: _selectedLanguage,
        code: _code,
        title: _titleController.text,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Snippet saved successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving snippet: $e')));
      }
    }
  }

  Future<String?> _showTitleInputDialog() async {
    final titleController = TextEditingController();
    String? title;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Snippet'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'Enter snippet title'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                title = titleController.text;
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    return title;
  }

  void _clearCode() {
    setState(() {
      _codeController.text = '';
      _code = '';
      _output = '';
    });
  }

  void _loadDefaultCode() {
    final language = _languages.firstWhere(
      (lang) => lang['value'] == _selectedLanguage,
      orElse: () => _languages[0],
    );
    setState(() {
      _code = language['helloWorld'];
      _codeController.text = _code;
      _output = '';
    });
  }

  // AI Features
  Future<void> _correctCode() async {
    if (_code.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write some code first')),
        );
      }
      return;
    }

    setState(() {
      _isAiProcessing = true;
    });

    try {
      final correction = await _codeAiService.correctCode(
        code: _code,
        language: _selectedLanguage,
        errorOutput: _output.contains('Error:') ? _output : null,
      );

      if (mounted) {
        // Show the correction in a dialog
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Code Correction'),
              content: SingleChildScrollView(child: Text(correction)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    } finally {
      setState(() {
        _isAiProcessing = false;
      });
    }
  }

  Future<void> _generateCode() async {
    final prompt = await _showAIPromptDialog();
    if (prompt == null || prompt.trim().isEmpty) {
      return;
    }

    setState(() {
      _isAiProcessing = true;
    });

    try {
      final generatedCode = await _codeAiService.generateCode(
        description: prompt,
        language: _selectedLanguage,
      );

      if (mounted) {
        // Show the generated code in a dialog
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Generated Code'),
              content: SingleChildScrollView(child: Text(generatedCode)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    // Extract code from the AI response and put it in the editor
                    _extractAndApplyCode(generatedCode);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Use Code'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    } finally {
      setState(() {
        _isAiProcessing = false;
      });
    }
  }

  Future<String?> _showAIPromptDialog() async {
    _aiPromptController.clear();
    String? prompt;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate Code'),
          content: TextField(
            controller: _aiPromptController,
            decoration: const InputDecoration(
              hintText: 'Describe what you want to create...',
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                prompt = _aiPromptController.text;
                Navigator.of(context).pop();
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );

    return prompt;
  }

  void _extractAndApplyCode(String aiResponse) {
    // Simple extraction - in a real implementation, you might want to parse code blocks more carefully
    final codeBlockPattern = RegExp(r'```(?:[a-zA-Z]+)?\s*([\s\S]*?)```');
    final match = codeBlockPattern.firstMatch(aiResponse);

    if (match != null) {
      final extractedCode = match.group(1)?.trim() ?? '';
      setState(() {
        _code = extractedCode;
        _codeController.text = extractedCode;
        _output = 'Code generated by AI';
      });
    } else {
      // If no code block found, use the entire response
      setState(() {
        _code = aiResponse;
        _codeController.text = aiResponse;
        _output = 'Code generated by AI';
      });
    }
  }

  Future<void> _explainCode() async {
    if (_code.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write some code first')),
        );
      }
      return;
    }

    setState(() {
      _isAiProcessing = true;
    });

    try {
      final explanation = await _codeAiService.explainCode(
        code: _code,
        language: _selectedLanguage,
      );

      if (mounted) {
        // Show the explanation in a dialog
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Code Explanation'),
              content: SingleChildScrollView(child: Text(explanation)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    } finally {
      setState(() {
        _isAiProcessing = false;
      });
    }
  }

  // Visualization Features
  Future<void> _visualizeExecution() async {
    if (_code.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write some code first')),
        );
      }
      return;
    }

    setState(() {
      _isAiProcessing = true;
    });

    try {
      final visualization = await _codeVisualizationService
          .generateExecutionVisualization(
            code: _code,
            language: _selectedLanguage,
            executionOutput: _output.contains('Error:') ? null : _output,
            errorOutput: _output.contains('Error:') ? _output : null,
          );

      if (mounted) {
        // Show the visualization in a fullscreen dialog with better formatting
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.9,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🎨 Execution Visualization',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 2),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_buildStyledContent(visualization)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check),
                        label: const Text('Got It!'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Visualization Error: $e')));
      }
    } finally {
      setState(() {
        _isAiProcessing = false;
      });
    }
  }

  /// Build styled content with proper formatting
  Widget _buildStyledContent(String content) {
    // Split content into sections
    final lines = content.split('\n');
    final List<Widget> widgets = [];

    StringBuffer currentSection = StringBuffer();
    String currentHeader = '';

    for (final line in lines) {
      if (line.startsWith('## ') ||
          line.startsWith('# ') ||
          line.isEmpty && currentSection.isNotEmpty) {
        // Add previous section
        if (currentSection.isNotEmpty) {
          widgets.add(
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentHeader,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      currentSection.toString().trim(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          currentSection.clear();
        }

        // Start new section
        currentHeader = line.replaceAll('#', '').trim();
      } else {
        currentSection.writeln(line);
      }
    }

    // Add last section
    if (currentSection.isNotEmpty) {
      widgets.add(
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentHeader,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  currentSection.toString().trim(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Future<void> _debugCode() async {
    if (_code.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write some code first')),
        );
      }
      return;
    }

    if (!_output.contains('Error:')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No errors detected. Run the code first to see if there are any errors.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isAiProcessing = true;
    });

    try {
      final debugGuide = await _codeVisualizationService.generateDebuggingGuide(
        code: _code,
        language: _selectedLanguage,
        errorOutput: _output,
      );

      if (mounted) {
        // Show the debugging guide in a dialog with better formatting
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.9,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🔧 Debugging Guide',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 2),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_buildStyledContent(debugGuide)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check),
                        label: const Text('Fixed It!'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Debugging Error: $e')));
      }
    } finally {
      setState(() {
        _isAiProcessing = false;
      });
    }
  }

  Future<void> _interactiveLearning() async {
    if (_code.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write some code first')),
        );
      }
      return;
    }

    setState(() {
      _isAiProcessing = true;
    });

    try {
      final learningContent = await _codeVisualizationService
          .generateInteractiveLearning(
            code: _code,
            language: _selectedLanguage,
            executionOutput: _output.contains('Error:') ? null : _output,
          );

      if (mounted) {
        // Show the interactive learning content in a dialog with better formatting
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.9,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🎓 Interactive Learning',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 2),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_buildStyledContent(learningContent)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.school),
                        label: const Text('Learned!'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Learning Content Error: $e')));
      }
    } finally {
      setState(() {
        _isAiProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Editor'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'clear':
                  _clearCode();
                  break;
                case 'default':
                  _loadDefaultCode();
                  break;
                case 'save':
                  _saveSnippet();
                  break;
                // AI Features
                case 'correct':
                  _correctCode();
                  break;
                case 'generate':
                  _generateCode();
                  break;
                case 'explain':
                  _explainCode();
                  break;
                // Visualization Features
                case 'visualize':
                  _visualizeExecution();
                  break;
                case 'debug':
                  _debugCode();
                  break;
                case 'learn':
                  _interactiveLearning();
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'clear',
                    child: Text('Clear Code'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'default',
                    child: Text('Load Default Code'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'save',
                    child: Text('Save Snippet'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'correct',
                    child: Text('Auto-Correct Code'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'generate',
                    child: Text('Generate Code'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'explain',
                    child: Text('Explain Code'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'visualize',
                    child: Text('Visualize Execution'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'debug',
                    child: Text('Debug Code'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'learn',
                    child: Text('Interactive Learning'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Challenge Banner
          if (widget.challenge != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videogame_asset, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        "Code Challenge",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.challenge!.description, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          
          // Language selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Language:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    items:
                        _languages.map((language) {
                          return DropdownMenuItem<String>(
                            value: language['value'],
                            child: Text(language['name']),
                          );
                        }).toList(),
                    onChanged: _onLanguageChanged,
                  ),
                ),
              ],
            ),
          ),

          // Code editor
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _codeController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: 'Write your code here...',
                  ),
                  onChanged: (value) {
                    _code = value;
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isRunning || _isAiProcessing ? null : _executeCode,
                    icon:
                        _isRunning || _isAiProcessing
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.play_arrow),
                    label: Text(
                      _isRunning
                          ? 'Running...'
                          : _isAiProcessing
                          ? 'AI Processing...'
                          : 'Run Code',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveSnippet,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Output section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Output:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _output.isEmpty ? 'Output will appear here...' : _output,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
