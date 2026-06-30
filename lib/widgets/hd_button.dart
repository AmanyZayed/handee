import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import '../theme/app_theme.dart';

// ─── Primary gradient button ───────────────────────────────────────────────────
// Matches design: h=56, radius=16, gradient #05347E→#1E5BB5, blue shadow.

class HdPrimaryButton extends StatelessWidget {
  const HdPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.height = 56,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final double height;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.55,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: height,
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
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Text(
                  label,
                  style: AppFonts.plusJakarta(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Secondary / outlined button ──────────────────────────────────────────────
// White bg, border, same size as primary.

class HdSecondaryButton extends StatelessWidget {
  const HdSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.height = 56,
    this.borderColor = AppColors.border,
    this.textColor = AppColors.textSubtle,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final double height;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Text(
              label,
              style: AppFonts.plusJakarta(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stop / danger button ──────────────────────────────────────────────────────
// Red gradient, used on the Recognize screen.

class HdDangerButton extends StatelessWidget {
  const HdDangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.error, AppColors.errorDark],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
    );
  }
}

// ─── Pill / mode-toggle button ─────────────────────────────────────────────────
// Small pill used for Type / Speak / Fingerspell mode toggles.

class HdPillButton extends StatelessWidget {
  const HdPillButton({
    super.key,
    required this.label,
    required this.isActive,
    this.onPressed,
    this.leading,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryMid],
                )
              : null,
          color: isActive ? null : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isActive
              ? null
              : Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppFonts.plusJakarta(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── View-toggle segmented pair ───────────────────────────────────────────────
// Used for "One by one / All signs" switches on Fingerspell.

class HdSegmentedToggle extends StatelessWidget {
  const HdSegmentedToggle({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final active = i == selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              height: 38,
              margin: EdgeInsets.only(right: i < options.length - 1 ? 7 : 0),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryMid],
                      )
                    : null,
                color: active ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: active
                    ? null
                    : Border.all(color: AppColors.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                options[i],
                style: AppFonts.plusJakarta(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
