import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Sign video page (option 2) when the avatar cannot sign the word.
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _words.isEmpty
        ? widget.word
        : '${_words[_currentIndex]} (${_currentIndex + 1}/${_words.length})';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 243, 244),
      appBar: AppBar(
        title: Text('Sign video — $title'),
        backgroundColor: const Color.fromARGB(255, 21, 38, 107),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        )
                      : _controller != null &&
                              _controller!.value.isInitialized
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: VideoPlayer(_controller!),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Text(
              'Showing sign for: ${widget.word}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
