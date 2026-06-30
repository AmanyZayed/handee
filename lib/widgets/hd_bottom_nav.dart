import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import '../theme/app_theme.dart';

// ─── Handee dark bottom navigation bar ────────────────────────────────────────
// Background #0B1030, top corners 28px, 4 tabs.
// Active tab: pill highlight rgba(44,102,194,.28) + white text.
// Inactive: muted icon #7C8AC0.

enum HdNavTab { translate, recognize, learn, profile }

class HdBottomNav extends StatelessWidget {
  const HdBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final HdNavTab current;
  final ValueChanged<HdNavTab> onChanged;

  static const _tabs = [
    _TabDef(HdNavTab.translate, 'Translate', Icons.compare_arrows_rounded),
    _TabDef(HdNavTab.recognize, 'Recognize', Icons.camera_alt_outlined),
    _TabDef(HdNavTab.learn, 'Learn', Icons.school_outlined),
    _TabDef(HdNavTab.profile, 'Profile', Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxxl),
        ),
      ),
      padding: EdgeInsets.only(
        left: 26,
        right: 26,
        top: 12,
        bottom: bottom + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _tabs
            .map((t) => _TabItem(
                  tab: t,
                  isActive: t.value == current,
                  onTap: () => onChanged(t.value),
                ))
            .toList(),
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.value, this.label, this.icon);
  final HdNavTab value;
  final String label;
  final IconData icon;
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final _TabDef tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeIconColor = Colors.white;
    const inactiveIconColor = Color(0xFF7C8AC0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF2C66C2).withValues(alpha: 0.28)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Icon(
              tab.icon,
              size: 22,
              color: isActive ? activeIconColor : inactiveIconColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            tab.label,
            style: AppFonts.plusJakarta(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : inactiveIconColor,
            ),
          ),
        ],
      ),
    );
  }
}
