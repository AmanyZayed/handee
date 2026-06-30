import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';

import '../services/sign_player.dart';
import '../theme/app_theme.dart';
import '../widgets/hd_button.dart';

/// Fingerspell — all letters in a uniform grid.
class FingerspellPage extends StatefulWidget {
  const FingerspellPage({super.key, this.initialText = ''});

  final String initialText;

  @override
  State<FingerspellPage> createState() => _FingerspellPageState();
}

class _FingerspellPageState extends State<FingerspellPage> {
  final _ctrl = TextEditingController();
  bool _playing = false;

  static const _tileBg = Color(0xFF1A2448);

  List<String> get _chars => _ctrl.text
      .toUpperCase()
      .split('')
      .where((c) => c.trim().isNotEmpty && c != ' ')
      .toList();

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialText;
    _ctrl.addListener(() => setState(() {}));
  }

  String? _assetFor(String char) {
    final c = char.toLowerCase();
    if (RegExp(r'^[a-z0-9]$').hasMatch(c)) return 'assets/asl/$c.png';
    return null;
  }

  Future<void> _spell() async {
    final word = _ctrl.text.trim().toLowerCase();
    if (word.isEmpty) return;
    setState(() => _playing = true);
    try {
      await SignPlayer.play(context, word);
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chars = _chars;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
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
          'Fingerspell',
          style: AppFonts.spaceGrotesk(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16204F), Color(0xFF0C1336)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xxxl),
                ),
                clipBehavior: Clip.hardEdge,
                child: chars.isEmpty
                    ? Center(
                        child: Text(
                          'Type a word below to see all signs',
                          style: AppFonts.plusJakarta(
                            color: const Color(0xFF9DB0E8),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              "Spelling '${_ctrl.text.trim().toUpperCase()}'",
                              style: AppFonts.plusJakarta(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          Expanded(child: _signGrid(chars)),
                        ],
                      ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              12,
              18,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: _inputCard(),
          ),
        ],
      ),
    );
  }

  Widget _signGrid(List<String> chars) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: chars.length,
      itemBuilder: (_, i) => _SignTile(
        index: i + 1,
        letter: chars[i],
        asset: _assetFor(chars[i]),
        background: _tileBg,
      ),
    );
  }

  Widget _inputCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              style: AppFonts.plusJakarta(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Type a word…',
                filled: true,
                fillColor: AppColors.surface2,
                border: InputBorder.none,
                hintStyle: AppFonts.plusJakarta(color: AppColors.textHint),
              ),
            ),
          ),
          const SizedBox(height: 12),
          HdPrimaryButton(
            label: 'Spell it',
            isLoading: _playing,
            leading: const Icon(Icons.back_hand_outlined,
                color: Colors.white, size: 20),
            onPressed: _playing ? null : _spell,
          ),
        ],
      ),
    );
  }
}

class _SignTile extends StatelessWidget {
  const _SignTile({
    required this.index,
    required this.letter,
    required this.asset,
    required this.background,
  });

  final int index;
  final String letter;
  final String? asset;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                '$index',
                style: AppFonts.plusJakarta(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: asset != null
                  ? Image.asset(
                      asset!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _letterText(letter),
                    )
                  : _letterText(letter),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              letter,
              style: AppFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _letterText(String letter) {
    return Text(
      letter,
      style: AppFonts.spaceGrotesk(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AppColors.cyan,
      ),
    );
  }
}
