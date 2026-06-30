import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:handee/theme/app_fonts.dart';
import '../theme/app_theme.dart';

class TextToSpeechPage extends StatefulWidget {
  const TextToSpeechPage({super.key});

  @override
  State<TextToSpeechPage> createState() => _TextToSpeechPageState();
}

class _TextToSpeechPageState extends State<TextToSpeechPage> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  double _speechRate = 0.45;
  double _pitch = 1.0;

  @override
  void initState() {
    super.initState();
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setCancelHandler(() => setState(() => _isSpeaking = false));
  }

  Future<void> _speak() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);
    await _tts.speak(text);
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
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
          'Text to Speech',
          style: AppFonts.spaceGrotesk(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text input card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: _isSpeaking ? AppColors.primary : AppColors.border,
                  width: _isSpeaking ? 1.5 : 1,
                ),
                boxShadow: AppShadow.card,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.text_fields_rounded,
                            size: 15, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Text(
                          'Enter text to speak',
                          style: AppFonts.plusJakarta(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_controller.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _controller.clear()),
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
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                    style: AppFonts.plusJakarta(
                      fontSize: 17,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type something to hear it spoken…',
                      hintStyle: AppFonts.plusJakarta(
                        fontSize: 15,
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Settings card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Settings',
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SliderRow(
                    icon: Icons.speed_rounded,
                    label: 'Speed',
                    value: _speechRate,
                    min: 0.1,
                    max: 1.0,
                    displayValue: _speechRate.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _speechRate = v),
                  ),
                  const SizedBox(height: 12),
                  _SliderRow(
                    icon: Icons.tune_rounded,
                    label: 'Pitch',
                    value: _pitch,
                    min: 0.5,
                    max: 2.0,
                    displayValue: _pitch.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _pitch = v),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Speak button
            GestureDetector(
              onTap: _isSpeaking ? null : _speak,
              child: AnimatedOpacity(
                opacity: _isSpeaking ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryMid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadow.button,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isSpeaking ? 'Speaking…' : 'Speak',
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
            ),

            const SizedBox(height: 12),

            // Stop button
            GestureDetector(
              onTap: _isSpeaking ? _stop : null,
              child: AnimatedOpacity(
                opacity: _isSpeaking ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: _isSpeaking ? AppColors.error : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop_circle_rounded,
                          color: _isSpeaking
                              ? AppColors.error
                              : AppColors.textSecondary,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Stop',
                        style: AppFonts.plusJakarta(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _isSpeaking
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: AppFonts.plusJakarta(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.primary,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            displayValue,
            textAlign: TextAlign.right,
            style: AppFonts.plusJakarta(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
