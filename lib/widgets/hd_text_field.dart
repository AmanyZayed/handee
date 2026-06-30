import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import '../theme/app_theme.dart';

// ─── Handee styled text field ──────────────────────────────────────────────────
// h=54–56, white bg, border #E6EAF7, focus: #05347E border + ring shadow.

class HdTextField extends StatefulWidget {
  const HdTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.leading,
    this.trailing,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? leading;
  final Widget? trailing;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final bool enabled;

  @override
  State<HdTextField> createState() => _HdTextFieldState();
}

class _HdTextFieldState extends State<HdTextField> {
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
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? AppColors.error
        : _focused
            ? AppColors.primary
            : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppFonts.plusJakarta(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: _focused && !hasError
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
              if (widget.leading != null) ...[
                const SizedBox(width: 16),
                IconTheme(
                  data: IconThemeData(
                    color: _focused ? AppColors.primary : AppColors.textHint,
                    size: 19,
                  ),
                  child: widget.leading!,
                ),
                const SizedBox(width: 11),
              ] else
                const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  enabled: widget.enabled,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: AppFonts.plusJakarta(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppFonts.plusJakarta(
                      fontSize: 15,
                      color: AppColors.textHint,
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
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: AppFonts.plusJakarta(
              fontSize: 12,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
