import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/password_validator.dart';
import 'auth_widgets.dart';
import 'human_check_screen.dart';
import 'signup_draft.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure  = true;
  bool _obscureConfirm = true;
  bool _agreed   = false;

  int get _passwordStrength =>
      PasswordValidator.strengthScore(_passwordCtrl.text);

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() => setState(() {}));
  }

  Future<void> _register() async {
    final username = _usernameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }
    final pwdError = PasswordValidator.validate(password);
    if (pwdError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pwdError)),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Privacy Policy.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HumanCheckScreen(
          draft: SignUpDraft(
            username: username,
            email: email,
            password: password,
            phone: phone,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showLegalInfo(String title) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(
          title == 'Terms'
              ? 'By using HANDee you agree to use the app responsibly and respect sign language communities.'
              : 'HANDee stores account and usage data locally and in Firebase to provide translation and learning features.',
          style: AppFonts.plusJakarta(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _agreed = true);
              Navigator.pop(context);
            },
            child: const Text('I agree'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),

              Text(
                'Create account',
                style: AppFonts.spaceGrotesk(
                  fontSize: 33,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Free forever. No card needed.',
                style: AppFonts.plusJakarta(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 26),

              // ── Full name ─────────────────────────────────────────────────
              const AuthFieldLabel(label: 'Full name'),
              const SizedBox(height: 8),
              AuthStyledField(
                controller: _usernameCtrl,
                hint: 'Your name',
                icon: Icons.person_outline_rounded,
              ),

              const SizedBox(height: 14),

              // ── Email ─────────────────────────────────────────────────────
              const AuthFieldLabel(label: 'Email'),
              const SizedBox(height: 8),
              AuthStyledField(
                controller: _emailCtrl,
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              const AuthFieldLabel(label: 'Phone number'),
              const SizedBox(height: 8),
              AuthStyledField(
                controller: _phoneCtrl,
                hint: '+1 555 000 4821',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 14),

              // ── Password ──────────────────────────────────────────────────
              const AuthFieldLabel(label: 'Password'),
              const SizedBox(height: 8),
              AuthStyledField(
                controller: _passwordCtrl,
                hint: 'Min. 8 chars · letter · number · symbol',
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

              // Password strength bar
              if (_passwordCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 9),
                Row(
                  children: List.generate(4, (i) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i < strength
                            ? _strengthColor(strength)
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 6),
                Text(
                  _strengthLabel(strength),
                  style: AppFonts.plusJakarta(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _strengthColor(strength),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              const AuthFieldLabel(label: 'Confirm password'),
              const SizedBox(height: 8),
              AuthStyledField(
                controller: _confirmCtrl,
                hint: 'Repeat password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureConfirm,
                trailing: GestureDetector(
                  onTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  child: Text(
                    _obscureConfirm ? 'Show' : 'Hide',
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Terms checkbox ────────────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        gradient: _agreed
                            ? const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryMid],
                              )
                            : null,
                        color: _agreed ? null : AppColors.surface,
                        border: Border.all(
                          color: _agreed ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: _agreed
                          ? const Icon(Icons.check_rounded,
                              size: 13, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "I agree to HANDee's ",
                              style: AppFonts.plusJakarta(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () => _showLegalInfo('Terms'),
                                child: Text(
                                  'Terms',
                                  style: AppFonts.plusJakarta(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: ' and ',
                              style: AppFonts.plusJakarta(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () => _showLegalInfo('Privacy Policy'),
                                child: Text(
                                  'Privacy Policy',
                                  style: AppFonts.plusJakarta(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: '.',
                              style: AppFonts.plusJakarta(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              AuthGradientButton(
                label: 'Create account',
                loading: false,
                onTap: _register,
                leading: const Icon(Icons.check_rounded,
                    size: 19, color: Colors.white),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppFonts.plusJakarta(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Log in',
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
        ),
      ),
    );
  }

  Color _strengthColor(int s) {
    if (s <= 1) return AppColors.error;
    if (s == 2) return AppColors.warning;
    return AppColors.success;
  }

  String _strengthLabel(int s) => PasswordValidator.strengthLabel(s);
}
