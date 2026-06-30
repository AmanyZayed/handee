import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_screen.dart';
import '../theme/app_theme.dart';
import 'login_widget.dart';
import 'sign_up_widget.dart';

/// Login shown after splash + onboarding. Never auto-skips to home.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _goHome(BuildContext context, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    if (user.email != null && user.email!.isNotEmpty) {
      await prefs.setString('registeredEmail', user.email!);
    }
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      await prefs.setString('username', name);
    }
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (user != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Material(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _goHome(context, user),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Continue as ${user.email ?? user.displayName ?? 'you'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Expanded(
              child: LoginWidget(
                onLogin: (u) => _goHome(context, u),
                onCreateAccount: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpWidget()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
