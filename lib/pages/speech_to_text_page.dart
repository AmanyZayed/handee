import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _text = 'Press the mic and start speaking...';
  bool _isListening = false;

  Future<void> _listen() async {
    if (!_isListening) {
      final available = await _speech.initialize();

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          localeId: 'en_US',
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F4),
      appBar: AppBar(
        title: const Text('Speech to Text'),
        backgroundColor: const Color.fromARGB(255, 21, 38, 107),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _text,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 21, 38, 107),
              onPressed: _listen,
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );    
  }
}