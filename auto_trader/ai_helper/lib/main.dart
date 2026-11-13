import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_ai/firebase_ai.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    providerApple: const AppleDebugProvider(),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Code Explainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExplainScreen(),
    );
  }
}

class ExplainScreen extends StatefulWidget {
  const ExplainScreen({super.key});

  @override
  State<ExplainScreen> createState() => _ExplainScreenState();
}

class _ExplainScreenState extends State<ExplainScreen> {
  final TextEditingController _codeController = TextEditingController();

  String _explanation = '';
  String _error = '';
  bool _isLoading = false;

  Future<void> explainCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _error = 'Please enter some code first.';
        _explanation = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _explanation = '';
    });

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
        systemInstruction: Content.system(
          'You are a programming tutor. Explain the code provided '
          'in clear, beginner-friendly language. Only answer questions '
          'about programming and the submitted code. If the input is '
          'not code or is unrelated to programming, explain that this '
          'tool is only for explaining code.',
        ),
      );

      final response = await model.generateContent([
        Content.text('Explain this code step by step:\n\n$code'),
      ]);

      setState(() {
        _explanation = response.text ?? 'No explanation was returned.';
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Code Explainer'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Understand Your Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste your code below and let AI explain what it does.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _codeController,
              maxLength: 500,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Paste your code here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : explainCode,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Explain Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('AI is analyzing your code...'),
                  ],
                ),
              ),

            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),

            if (_explanation.isNotEmpty) ...[
              const Text(
                'Code Explanation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  _explanation,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],

            const SizedBox(height: 24),

            const Text(
              'AI Disclaimer: Explanations are generated by AI and '
              'may contain mistakes. Always review the code yourself.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
