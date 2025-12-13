import 'package:flutter/material.dart';
import 'services/groq_service.dart';
import 'utils/constants.dart';

class TestGroqServiceScreen extends StatefulWidget {
  const TestGroqServiceScreen({super.key});

  @override
  State<TestGroqServiceScreen> createState() => _TestGroqServiceScreenState();
}

class _TestGroqServiceScreenState extends State<TestGroqServiceScreen> {
  String _status = 'Ready to test';
  bool _isTesting = false;

  Future<void> _testGroqService() async {
    setState(() {
      _status = 'Testing Groq service...';
      _isTesting = true;
    });

    try {
      final groqService = GroqService(apiKey: AppConstants.groqApiKey);

      setState(() {
        _status += '\n\nSending test message to Groq API...';
      });

      final response = await groqService.sendMessage(
        'Say "Hello, this is a test!" in a friendly way.',
      );

      setState(() {
        _status += '\n\n✅ SUCCESS!\nResponse: $response';
      });
    } catch (e) {
      setState(() {
        _status = '❌ ERROR: $e';
        if (e.toString().contains('401') ||
            e.toString().contains('Invalid API Key')) {
          _status +=
              '\n\n>>> API KEY ISSUE DETECTED <<<\n'
              'Please make sure you have entered a valid Groq API key in constants.dart\n'
              'Get your free API key at: https://console.groq.com/';
        }
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Groq Service')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _status,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isTesting ? null : _testGroqService,
              child: Text(_isTesting ? 'Testing...' : 'Test Groq Service'),
            ),
          ],
        ),
      ),
    );
  }
}
