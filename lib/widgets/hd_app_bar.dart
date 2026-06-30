import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import '../theme/app_theme.dart';

// ─── Handee logo mark (icon-only) ─────────────────────────────────────────────
// The blue gradient rounded-square icon used throughout the app.

class HdLogoMark extends StatelessWidget {
  const HdLogoMark({super.key, this.size = 40, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.30;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.electric],
        ),
        borderRadius: BorderRadius.circular(r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2905347E),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _HandMarkPainter(),
      ),
    );
  }
}

// Draws the HANDee hand-bar motif in white — matches the SVG in the design.
class _HandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Four vertical bars (fingers) — scaled from the SVG viewBox (0 0 34 34)
    // Original bar positions in a 34×34 viewBox translated/scaled:
    //   translate(6,2) scale(0.3) → effective origin offset + 0.3× scale
    final rects = [
      _bar(18, 22, 14, 40, w, h),
      _bar(35, 14, 14, 48, w, h),
      _bar(52, 18, 14, 44, w, h),
      _bar(69, 26, 14, 36, w, h),
    ];
    for (final r in rects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(r.width / 2)),
        paint,
      );
    }

    // Thumb arc bar (rotate 40° around 9,62 in original)
    // Approximate with a rounded rect then rotate
    canvas.save();
    final thumbRect = _bar(2, 56, 14, 32, w, h);
    final thumbCenter = thumbRect.center;
    canvas.translate(thumbCenter.dx, thumbCenter.dy);
    canvas.rotate(40 * 3.14159 / 180);
    canvas.translate(-thumbCenter.dx, -thumbCenter.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(thumbRect, Radius.circular(thumbRect.width / 2)),
      paint,
    );
    canvas.restore();

    // Palm rounded rect
    final palmRect = _bar(14, 50, 72, 36, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(palmRect, const Radius.circular(5.4)),
      paint,
    );
  }

  // Maps a bar from the SVG coordinate space (86×64 effective) to the canvas.
  Rect _bar(double x, double y, double bw, double bh, double cw, double ch) {
    // SVG origin after translate(6,2) scale(0.3): space is ~84×64 (orig 280×214 at 0.3)
    const ox = 6.0, oy = 2.0, sc = 0.3;
    final sx = (x * sc + ox) / 34.0 * cw;
    final sy = (y * sc + oy) / 34.0 * ch;
    final sw = bw * sc / 34.0 * cw;
    final sh = bh * sc / 34.0 * ch;
    return Rect.fromLTWH(sx, sy, sw, sh);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Inline home-screen app bar row ───────────────────────────────────────────
// Used inside screen content (not as a PreferredSizeWidget) — matches the
// design's top bar showing logo + "Good morning / HANDee." + notification bell.

class HdHomeBar extends StatelessWidget {
  const HdHomeBar({
    super.key,
    this.greeting,
    this.actionIcon,
    this.onAction,
  });

  final String? greeting;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          const HdLogoMark(size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (greeting != null)
                Text(
                  greeting!,
                  style: AppFonts.plusJakarta(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  ),
                ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'HAND',
                      style: AppFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: 'ee',
                      style: AppFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: '.',
                      style: AppFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.electric,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          if (actionIcon != null)
            _NavIconButton(
              icon: actionIcon!,
              onTap: onAction,
              dark: false,
            ),
        ],
      ),
    );
  }
}

// ─── Sub-screen app bar (back + title) ────────────────────────────────────────
// Used on Fingerspell, Speech, etc. — shows a back button and a title.

class HdSubBar extends StatelessWidget {
  const HdSubBar({
    super.key,
    this.parent,
    required this.title,
    this.trailing,
    this.dark = false,
  });

  final String? parent;
  final String title;
  final Widget? trailing;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          _NavIconButton(
            icon: Icons.chevron_left,
            onTap: () => Navigator.maybePop(context),
            dark: dark,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (parent != null)
                Text(
                  parent!,
                  style: AppFonts.plusJakarta(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dark ? AppColors.darkTextHint : AppColors.textHint,
                  ),
                ),
              Text(
                title,
                style: AppFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: dark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Camera-overlay top bar ────────────────────────────────────────────────────
// Used on the Recognize screen (dark / translucent blur buttons, white title).

class HdCameraBar extends StatelessWidget {
  const HdCameraBar({
    super.key,
    required this.title,
    this.onBack,
    this.onAction,
    this.actionIcon = Icons.flip_camera_ios_outlined,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onAction;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          _GlassButton(icon: Icons.chevron_left, onTap: onBack),
          const Spacer(),
          Text(
            title,
            style: AppFonts.plusJakarta(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _GlassButton(icon: actionIcon, onTap: onAction),
        ],
      ),
    );
  }
}

// ─── Internals ─────────────────────────────────────────────────────────────────

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({required this.icon, this.onTap, required this.dark});
  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: dark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: dark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
    );
  }
}
