import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash/splash_screen.dart';
import 'asl_translator_page.dart';
import 'pages/speech_to_text_page.dart';
import 'pages/text_to_speech_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const HandeeApp());
}

class HandeeApp extends StatelessWidget {
  const HandeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/asl-translator': (context) => const AslTranslatorPage(),
        '/speech-to-text': (context) => const SpeechToTextPage(),
        '/text-to-speech': (context) => const TextToSpeechPage(),
      },
    );
  }
}
