import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class SignVideoPage extends StatefulWidget {
  final String word;

  const SignVideoPage({super.key, required this.word});

  @override
  State<SignVideoPage> createState() => _SignVideoPageState();
}

class _SignVideoPageState extends State<SignVideoPage> {
  VideoPlayerController? _controller;

  final List<String> _folders = const [
    'assets/signs_final_300',
    'assets/signs_cropped',
    'assets/signs',
    'assets/signs_cutout',
  ];

  List<String> _words = [];
  int _currentIndex = 0;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _words = widget.word
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (_words.isEmpty) {
      _error = 'No word entered';
      _loading = false;
    } else {
      _loadVideo(_words[_currentIndex]);
    }
  }

  Future<void> _loadVideo(String word) async {
    await _controller?.dispose();
    if (!mounted) return;

    setState(() {
      _error = null;
      _controller = null;
      _loading = true;
    });

    for (final folder in _folders) {
      final path = '$folder/$word.mp4';
      final controller = VideoPlayerController.asset(path);
      try {
        await controller.initialize();
        if (!mounted) {
          await controller.dispose();
          return;
        }

        controller.addListener(() {
          if (!mounted) return;
          final v = controller.value;
          if (v.isInitialized &&
              v.duration > Duration.zero &&
              v.position >= v.duration - const Duration(milliseconds: 200) &&
              !v.isPlaying) {
            _playNext();
          }
        });

        setState(() {
          _controller = controller;
          _loading = false;
        });
        await controller.play();
        return;
      } catch (_) {
        await controller.dispose();
      }
    }

    _playNext();
  }

  void _playNext() {
    if (_currentIndex < _words.length - 1) {
      _currentIndex++;
      _loadVideo(_words[_currentIndex]);
    } else if (mounted) {
      setState(() {
        _loading = false;
        _error = 'No sign video found for "${widget.word}"';
      });
    }
  }

  void _replayVideo() {
    _controller?.seekTo(Duration.zero);
    _controller?.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWord = _words.isEmpty ? widget.word : _words[_currentIndex];
    final hasMultiple = _words.length > 1;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Column(
          children: [
            Text(
              currentWord.toUpperCase(),
              style: AppFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (hasMultiple)
              Text(
                '${_currentIndex + 1} of ${_words.length}',
                style: AppFonts.plusJakarta(
                  fontSize: 11,
                  color: const Color(0xFF7C8AC0),
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_controller != null && !_loading && _error == null)
            IconButton(
              icon: const Icon(Icons.replay_rounded, color: Colors.white),
              tooltip: 'Replay',
              onPressed: _replayVideo,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Word progress bar (multi-word) ──────────────────────────────
          if (hasMultiple)
            Container(
              color: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: List.generate(_words.length, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      decoration: BoxDecoration(
                        color: i <= _currentIndex
                            ? AppColors.electric
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

          // ── Video area ──────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: _loading
                  ? SizedBox(
                      width: 36, height: 36,
                      child: CircularProgressIndicator(
                        color: AppColors.electric,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _error != null
                      ? _ErrorState(error: _error!, word: widget.word)
                      : _controller != null &&
                              _controller!.value.isInitialized
                          ? GestureDetector(
                              onTap: () {
                                if (_controller!.value.isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                                setState(() {});
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio:
                                        _controller!.value.aspectRatio,
                                    child: VideoPlayer(_controller!),
                                  ),
                                  if (!_controller!.value.isPlaying)
                                    Container(
                                      width: 64, height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                            alpha: 0.5),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                              alpha: 0.25),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 38,
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
            ),
          ),

          // ── Bottom label ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.ink,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sign_language_rounded,
                    color: AppColors.electric, size: 15),
                const SizedBox(width: 8),
                Text(
                  'Sign for: ${widget.word}',
                  style: AppFonts.plusJakarta(
                    color: const Color(0xFF9DB0E8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.word});
  final String error;
  final String word;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.videocam_off_rounded,
                size: 38, color: AppColors.error),
          ),
          const SizedBox(height: 20),
          Text(
            'No Video Found',
            style: AppFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Could not find a sign video for "$word".',
            textAlign: TextAlign.center,
            style: AppFonts.plusJakarta(
              fontSize: 13,
              color: const Color(0xFF9DB0E8),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
