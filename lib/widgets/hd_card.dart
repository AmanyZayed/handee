import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── White surface card ────────────────────────────────────────────────────────
// Used for input panels, transcript boxes, settings lists, etc.

class HdCard extends StatelessWidget {
  const HdCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = AppRadius.xxl,
    this.color = AppColors.surface,
    this.border = true,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final bool border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border
            ? Border.all(color: AppColors.border, width: 1)
            : null,
        boxShadow: shadow ? AppShadow.card : null,
      ),
      child: child,
    );
  }
}

// ─── Dark sign-avatar stage ────────────────────────────────────────────────────
// The dark gradient panel used behind the 3D avatar / camera view.

class HdSignStage extends StatelessWidget {
  const HdSignStage({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 18),
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16204F), Color(0xFF0C1336)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3315305A),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        child: child,
      ),
    );
  }
}

// ─── Premium / highlight banner card ──────────────────────────────────────────
// Dark gradient card used for "Go Premium" and daily practice widgets.

class HdBannerCard extends StatelessWidget {
  const HdBannerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22.0,
    this.colors = const [Color(0xFF05347E), Color(0xFF1E5BB5)],
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: begin, end: end),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadow.button,
      ),
      child: child,
    );
  }
}

// ─── Settings list row ─────────────────────────────────────────────────────────
// Row used in Profile settings list (Account, Accessibility, Language, etc.)

class HdSettingsRow extends StatelessWidget {
  const HdSettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.isLast = false,
    this.onTap,
  });

  final Widget icon;
  final String label;
  final Widget? trailing;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF0F3FB), width: 1),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: IconTheme(
                data: const IconThemeData(
                  color: AppColors.primary,
                  size: 18,
                ),
                child: icon,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFFC2CBE0)),
          ],
        ),
      ),
    );
  }
}
