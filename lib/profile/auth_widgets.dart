import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import '../theme/app_theme.dart';

// Field label above inputs
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppFonts.plusJakarta(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSubtle,
      ),
    );
  }
}

// 56px styled input field with focus ring
class AuthStyledField extends StatefulWidget {
  const AuthStyledField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;

  @override
  State<AuthStyledField> createState() => _AuthStyledFieldState();
}

class _AuthStyledFieldState extends State<AuthStyledField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused ? AppColors.primary : AppColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            widget.icon,
            size: 19,
            color: _focused ? AppColors.primary : AppColors.textHint,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              style: AppFonts.plusJakarta(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: widget.obscureText ? 3 : 0,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppFonts.plusJakarta(
                  fontSize: 15,
                  color: AppColors.textHint,
                  letterSpacing: 0,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            widget.trailing!,
            const SizedBox(width: 16),
          ] else
            const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// Gradient CTA button used on Login and Sign-up
class AuthGradientButton extends StatelessWidget {
  const AuthGradientButton({
    super.key,
    required this.label,
    required this.loading,
    this.onTap,
    this.leading,
  });

  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryMid],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.button,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: loading
                ? [
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white,
                      ),
                    ),
                  ]
                : [
                    if (leading != null) ...[leading!, const SizedBox(width: 8)],
                    Text(
                      label,
                      style: AppFonts.plusJakarta(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

// Outlined social / secondary button (e.g. Google sign-in)
class AuthOutlineButton extends StatelessWidget {
  const AuthOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: loading
                ? [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ]
                : [
                    if (leading != null) ...[leading!, const SizedBox(width: 8)],
                    Text(
                      label,
                      style: AppFonts.plusJakarta(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
