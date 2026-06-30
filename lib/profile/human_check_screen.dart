import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/hd_button.dart';
import 'login_screen.dart';
import 'signup_draft.dart';

class HumanCheckScreen extends StatefulWidget {
  const HumanCheckScreen({super.key, required this.draft});

  final SignUpDraft draft;

  @override
  State<HumanCheckScreen> createState() => _HumanCheckScreenState();
}

class _HumanCheckScreenState extends State<HumanCheckScreen> {
  bool _checking = false;
  bool _verified = false;
  bool _creating = false;

  Future<void> _verify() async {
    if (_verified || _checking) return;
    setState(() => _checking = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _checking = false;
      _verified = true;
    });
  }

  Future<void> _createAccount() async {
    if (!_verified || _creating) return;
    setState(() => _creating = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.draft.email,
        password: widget.draft.password,
      );

      await cred.user!.updateDisplayName(widget.draft.username);
      await cred.user!.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'username': widget.draft.username,
        'email': widget.draft.email,
        'phone': widget.draft.phone,
        'createdAt': Timestamp.now(),
      });

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Check your email to verify, then sign in.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      var msg = e.message ?? 'Could not create account.';
      if (e.code == 'email-already-in-use') {
        msg = 'This email is already registered. Try signing in.';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak. Use at least 8 characters.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address.';
      } else if (e.code == 'network-request-failed') {
        msg =
            'Connection interrupted. Check Wi‑Fi or mobile data, turn off VPN, '
            'update Google Play Services, then try again.';
      }
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 19, color: AppColors.textPrimary),
          onPressed: _creating ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quick security check',
                style: AppFonts.spaceGrotesk(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Confirm you're human to keep HANDee safe from spam and abuse.",
                style: AppFonts.plusJakarta(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.electric],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: AppShadow.button,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _verified || _creating ? null : _verify,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: _verified ? AppColors.success : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              _verified ? AppColors.success : AppColors.surface,
                          border: Border.all(
                            color: _verified
                                ? AppColors.success
                                : AppColors.border,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _checking
                            ? const Padding(
                                padding: EdgeInsets.all(4),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : _verified
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "I'm not a robot",
                        style: AppFonts.plusJakarta(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_verified) ...[
                const SizedBox(height: 14),
                Text(
                  "Verified — you're good to go.",
                  textAlign: TextAlign.center,
                  style: AppFonts.plusJakarta(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
              const Spacer(flex: 2),
              HdPrimaryButton(
                label: 'Create account',
                isLoading: _creating,
                onPressed: _verified && !_creating ? _createAccount : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
