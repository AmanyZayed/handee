import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import 'theme/app_theme.dart';

class AslTranslatorPage extends StatefulWidget {
  const AslTranslatorPage({super.key});

  @override
  State<AslTranslatorPage> createState() => _AslTranslatorPageState();
}

class _AslTranslatorPageState extends State<AslTranslatorPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _signs = [];

  String? _getImageName(String char) {
    final c = char.toLowerCase();
    if (RegExp(r'^[a-z]$').hasMatch(c)) return '$c.png';
    if (RegExp(r'^[0-9]$').hasMatch(c)) return '$c.png';
    return null;
  }

  void _onTextChanged(String text) {
    setState(() {
      _signs = text.split('').where((ch) {
        return ch == ' ' || _getImageName(ch) != null;
      }).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Finger Spelling',
          style: AppFonts.spaceGrotesk(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Input card ────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(18, 4, 18, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadow.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_rounded,
                          size: 15, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Text(
                        'Type letters or numbers',
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_controller.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _controller.clear();
                            _onTextChanged('');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: AppColors.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
                TextField(
                  controller: _controller,
                  onChanged: _onTextChanged,
                  autofocus: false,
                  textCapitalization: TextCapitalization.characters,
                  style: AppFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'A B C … 1 2 3',
                    hintStyle: AppFonts.spaceGrotesk(
                      fontSize: 22,
                      color: AppColors.textHint,
                      letterSpacing: 1.0,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: false,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Signs count pill ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sign_language_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        '${_signs.where((s) => s != ' ').length} signs',
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Sign grid ─────────────────────────────────────────────────────
          Expanded(
            child: _signs.isEmpty
                ? _EmptyState()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 14,
                        children: _signs.map((ch) {
                          if (ch == ' ') {
                            return const SizedBox(width: 16, height: 90);
                          }
                          return _SignTile(
                            imagePath: 'assets/asl/${_getImageName(ch)!}',
                            label: ch.toUpperCase(),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sign_language_rounded,
              size: 40,
              color: AppColors.electric,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Signs appear here as you type',
            style: AppFonts.plusJakarta(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Supports A–Z and 0–9',
            style: AppFonts.plusJakarta(
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignTile extends StatelessWidget {
  final String imagePath;
  final String label;

  const _SignTile({required this.imagePath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadow.sm,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md - 1),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.mist,
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: AppFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppFonts.plusJakarta(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
