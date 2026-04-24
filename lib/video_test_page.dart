import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoTestPage extends StatefulWidget {
  final String word;

  const VideoTestPage({super.key, required this.word});

  @override
  State<VideoTestPage> createState() => _VideoTestPageState();
}

class _VideoTestPageState extends State<VideoTestPage> {
  VideoPlayerController? _controller;

  List<String> words = [];
  List<String> missingWords = [];

  int currentIndex = 0;
  String? error;

  @override
  void initState() {
    super.initState();

    words = widget.word
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      error = "No words entered";
    } else {
      _loadVideo(words[currentIndex]);
    }
  }

  Future<void> _loadVideo(String word) async {
    await _controller?.dispose();

    setState(() {
      error = null;
      _controller = null;
    });

    final path = 'assets/signs_cropped/$word.mp4';
    final controller = VideoPlayerController.asset(path);
    _controller = controller;

    try {
      await controller.initialize();

      controller.addListener(() {
        if (controller.value.isInitialized &&
            controller.value.position >= controller.value.duration &&
            !controller.value.isPlaying) {
          _playNextVideo();
        }
      });

      setState(() {});
      controller.play();
    } catch (e) {
      missingWords.add(word);
      _playNextVideo();
    }
  }

  void _playNextVideo() {
    if (currentIndex < words.length - 1) {
      currentIndex++;
      _loadVideo(words[currentIndex]);
    } else {
      if (_controller == null || !_controller!.value.isInitialized) {
        setState(() {
          error = "No valid videos found";
        });
      } else {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = words.isEmpty
        ? widget.word
        : '${words[currentIndex]} (${currentIndex + 1}/${words.length})';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔥 Missing words banner
          if (missingWords.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Text(
                "Missing: ${missingWords.join(', ')}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ),

          // 🎬 Video area
          Expanded(
            child: Center(
              child: error != null
                  ? Text(
                      error!,
                      style: const TextStyle(fontSize: 18),
                    )
                  : _controller != null && _controller!.value.isInitialized
                      ? Container(
                          width: 280,
                          height: 420,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _controller!.value.size.width,
                              height: _controller!.value.size.height,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                        )
                      : const CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}