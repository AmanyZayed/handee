import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handee/theme/app_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../pages/fingerspell_page.dart';
import '../theme/app_theme.dart';
import '../widgets/hd_button.dart';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _text = '';
  bool _isListening = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _listen() async {
    if (!_isListening) {
      final available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _pulseController.repeat(reverse: true);
        _speech.listen(
          onResult: (result) {
            setState(() => _text = result.recognizedWords);
          },
          listenOptions: stt.SpeechListenOptions(localeId: 'en_US'),
        );
      }
    } else {
      await _speech.stop();
      _pulseController.stop();
      _pulseController.reset();
      setState(() => _isListening = false);
    }
  }

  void _clear() => setState(() => _text = '');

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
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
          'Speech to Text',
          style: AppFonts.spaceGrotesk(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textSecondary),
              tooltip: 'Clear',
              onPressed: _clear,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          children: [
            // Status pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: _isListening
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: _isListening ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? AppColors.primary
                          : AppColors.textHint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'Listening...' : 'Tap mic to start',
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isListening
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Transcription card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: _isListening ? AppColors.primary : AppColors.border,
                    width: _isListening ? 1.5 : 1,
                  ),
                  boxShadow: AppShadow.card,
                ),
                child: _text.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            size: 52,
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Your speech will appear here',
                            style: AppFonts.plusJakarta(
                              fontSize: 15,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          _text,
                          style: AppFonts.plusJakarta(
                            fontSize: 20,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            height: 1.55,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // Mic button with pulse
            ScaleTransition(
              scale: _isListening
                  ? _pulseAnim
                  : const AlwaysStoppedAnimation(1.0),
              child: GestureDetector(
                onTap: _listen,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [const Color(0xFFE53935), const Color(0xFFEF5350)]
                          : [AppColors.primary, AppColors.electric],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening
                                ? const Color(0xFFE53935)
                                : AppColors.primary)
                            .withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              _isListening ? 'Tap to stop' : 'Tap to speak',
              style: AppFonts.plusJakarta(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: HdSecondaryButton(
                    label: 'Copy',
                    leading: const Icon(Icons.copy_rounded,
                        size: 18, color: AppColors.textSubtle),
                    onPressed: _text.isEmpty
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: _text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard')),
                            );
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HdPrimaryButton(
                    label: 'To Sign',
                    height: 56,
                    leading: const Icon(Icons.back_hand_outlined,
                        color: Colors.white, size: 18),
                    onPressed: _text.trim().isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FingerspellPage(initialText: _text.trim()),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
