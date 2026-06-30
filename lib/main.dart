import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/app_prefs.dart';
import 'splash/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppPrefs.instance.loadLargeTextNotifier();

  runApp(const HandeeApp());
}

class HandeeApp extends StatelessWidget {
  const HandeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppPrefs.largeTextNotifier,
      builder: (context, largeText, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(largeText ? 1.15 : 1.0),
              ),
              child: child!,
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
