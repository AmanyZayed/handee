import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';

import '../services/auth_session.dart';
import '../theme/app_theme.dart';
import 'login_widget.dart';
import 'sign_up_widget.dart';

/// Full-screen sign-in shown after splash + onboarding.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    _redirectIfAlreadySignedIn();
  }

  Future<void> _redirectIfAlreadySignedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await AuthSession.persistUser(user);
    if (!mounted) return;
    await AuthSession.goHome(context);
  }

  Future<void> _goHome(BuildContext context, User user) async {
    await AuthSession.persistUser(user);
    if (!context.mounted) return;
    await AuthSession.goHome(context);
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
                          const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Continue as ${user.email ?? user.displayName ?? 'you'}',
                              style: AppFonts.plusJakarta(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Expanded(
              child: LoginWidget(
                embedded: true,
                onLogin: (u) => _goHome(context, u),
                onContinueAsGuest: () => AuthSession.continueAsGuest(context),
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
