import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechPage extends StatefulWidget {
  const TextToSpeechPage({super.key});

  @override
  State<TextToSpeechPage> createState() => _TextToSpeechPageState();
}

class _TextToSpeechPageState extends State<TextToSpeechPage> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _tts = FlutterTts();

  Future<void> _speak() async {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> _stop() async {
    await _tts.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F4),
      appBar: AppBar(
        title: const Text('Text to Speech'),
        backgroundColor: const Color.fromARGB(255, 21, 38, 107),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Type text here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _speak,
              icon: const Icon(Icons.volume_up),
              label: const Text('Speak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 21, 38, 107),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _stop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}