import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handee/theme/app_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/auth_session.dart';
import '../theme/app_theme.dart';
import '../widgets/hd_app_bar.dart';
import 'auth_widgets.dart';
import 'sign_up_widget.dart';

class LoginWidget extends StatefulWidget {
  final Future<void> Function(User user) onLogin;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onContinueAsGuest;
  final bool embedded;

  const LoginWidget({
    super.key,
    required this.onLogin,
    this.onCreateAccount,
    this.onContinueAsGuest,
    this.embedded = false,
  });

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingEmail();
  }

  Future<void> _loadPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(AuthSession.pendingLoginEmailKey);
    if (pending == null || pending.isEmpty || !mounted) return;
    _emailCtrl.text = pending;
    await prefs.remove(AuthSession.pendingLoginEmailKey);
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user != null) await widget.onLogin(user);
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') msg = 'No account found for this email.';
      if (e.code == 'wrong-password') msg = 'Incorrect password.';
      if (e.code == 'invalid-email') msg = 'Please enter a valid email address.';
      if (e.code == 'network-request-failed') {
        msg =
            'Connection interrupted. Check your internet and Google Play Services, then try again.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final cred = await AuthService.instance.signInWithGoogle();
      final user = cred.user;
      if (user != null) await widget.onLogin(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'google-sign-in-cancelled') return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Google sign-in failed.'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email address first.')),
      );
      return;
    }

    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'user-not-found'
                ? 'No account found for this email.'
                : 'Could not send reset email. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _googleLoading;

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(26, widget.embedded ? 16 : 0, 26, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded) const SizedBox(height: 64),

          const Align(
            alignment: Alignment.centerLeft,
            child: HdLogoMark(size: 58, radius: 17),
          ),

              const SizedBox(height: 26),

              Text(
                'Welcome back',
                style: AppFonts.spaceGrotesk(
                  fontSize: 33,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to keep translating.',
                style: AppFonts.plusJakarta(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 30),

              const AuthFieldLabel(label: 'Email'),
              const SizedBox(height: 8),
              AuthStyledField(
                controller: _emailCtrl,
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              const AuthFieldLabel(label: 'Password'),
              const SizedBox(height: 8),
              AuthStyledField(
                controller: _passwordCtrl,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                trailing: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Text(
                    _obscure ? 'Show' : 'Hide',
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: busy ? null : _forgotPassword,
                  child: Text(
                    'Forgot password?',
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              AuthGradientButton(
                label: 'Log in',
                loading: _loading,
                onTap: busy ? null : _login,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),

              const SizedBox(height: 14),

              AuthOutlineButton(
                label: 'Continue with Google',
                loading: _googleLoading,
                onTap: busy ? null : _signInWithGoogle,
                leading: const Icon(
                  Icons.g_mobiledata_rounded,
                  size: 24,
                  color: Color(0xFF4285F4),
                ),
              ),

              if (widget.onContinueAsGuest != null) ...[
                const SizedBox(height: 12),
                AuthOutlineButton(
                  label: 'Continue as a guest',
                  onTap: busy ? null : widget.onContinueAsGuest,
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: AppColors.textSubtle,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New to HANDee? ',
                    style: AppFonts.plusJakarta(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: busy
                        ? null
                        : () {
                            if (widget.onCreateAccount != null) {
                              widget.onCreateAccount!();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignUpWidget(),
                                ),
                              );
                            }
                          },
                    child: Text(
                      'Create account',
                      style: AppFonts.plusJakarta(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: content),
    );
  }
}
