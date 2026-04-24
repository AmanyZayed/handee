import 'dart:async';

import 'package:flutter/material.dart';

import 'native_asl_bridge.dart';
import 'tflite_asl_service.dart';

class AslCameraScreen extends StatefulWidget {
  const AslCameraScreen({super.key});

  @override
  State<AslCameraScreen> createState() => _AslCameraScreenState();
}

class _AslCameraScreenState extends State<AslCameraScreen> {
  final TfliteAslService _tfliteService = TfliteAslService();
  StreamSubscription? _nativeStreamSubscription;

  bool _isModelLoaded = false;
  bool _isRecognitionStarted = false;

  String? _errorMessage;
  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _listenToNativeStream();
    _startSetup();
  }

  void _listenToNativeStream() {
    _nativeStreamSubscription = NativeAslBridge.nativeStream.listen(
      (event) {
        debugPrint('NATIVE EVENT -> $event');

        if (!mounted || event == null) return;

        if (event is Map) {
          final type = event['type'];

          if (type == 'status') {
            setState(() {
              _statusText = event['message']?.toString() ?? _statusText;
            });
          } else if (type == 'frame_update') {
            setState(() {
              _statusText = event['message']?.toString() ?? _statusText;
            });
          } else if (type == 'landmark_update') {
            final faceCount = (event['faceCount'] as num?)?.toInt() ?? 0;
            final poseCount = (event['poseCount'] as num?)?.toInt() ?? 0;
            final leftHandCount =
                (event['leftHandCount'] as num?)?.toInt() ?? 0;
            final rightHandCount =
                (event['rightHandCount'] as num?)?.toInt() ?? 0;
            final frameCount = (event['frameCount'] as num?)?.toInt() ?? 0;

            debugPrint(
              'LANDMARKS -> frame=$frameCount '
              'face=$faceCount pose=$poseCount '
              'lh=$leftHandCount rh=$rightHandCount',
            );

            setState(() {
              _statusText = 'Frame $frameCount';
            });
          }
        }
      },
      onError: (error) {
        debugPrint('NATIVE STREAM ERROR -> $error');

        if (!mounted) return;
        setState(() {
          _errorMessage = 'Native stream error: $error';
        });
      },
    );
  }

  Future<void> _startSetup() async {
    await _initializeNative();
    if (_errorMessage != null) return;

    await _loadModel();
  }

  Future<void> _initializeNative() async {
    try {
      final message = await NativeAslBridge.initializeAslEngine();
      debugPrint('initializeAslEngine -> $message');

      if (!mounted) return;

      setState(() {
        _statusText = message;
      });
    } catch (e, st) {
      debugPrint('initializeNative error: $e');
      debugPrintStack(stackTrace: st);

      setState(() {
        _errorMessage = 'Native bridge error: $e';
      });
    }
  }

  Future<void> _loadModel() async {
    try {
      await _tfliteService.loadModel();

      final inputShape = _tfliteService.getInputShape();
      final outputShape = _tfliteService.getOutputShape();
      final inputType = _tfliteService.getInputType();
      final outputType = _tfliteService.getOutputType();
      final labelCount = _tfliteService.getLabelCount();

      debugPrint('SIGN MODEL INPUT -> $inputShape ($inputType)');
      debugPrint('SIGN MODEL OUTPUT -> $outputShape ($outputType)');
      debugPrint('SIGN MODEL LABELS -> $labelCount');

      if (!mounted) return;

      setState(() {
        _isModelLoaded = true;
        _statusText = 'Ready ✅';
      });
    } catch (e, st) {
      debugPrint('loadModel error: $e');
      debugPrintStack(stackTrace: st);

      setState(() {
        _errorMessage = 'Failed to load sign model: $e';
      });
    }
  }

  Future<void> _toggleRecognition() async {
    try {
      if (_isRecognitionStarted) {
        debugPrint('STOP button pressed');

        await NativeAslBridge.stopRecognition();

        if (!mounted) return;

        setState(() {
          _isRecognitionStarted = false;
          _statusText = 'Stopped';
        });
      } else {
        debugPrint('START button pressed');

        await NativeAslBridge.startRecognition();

        debugPrint('NativeAslBridge.startRecognition() finished');

        if (!mounted) return;

        setState(() {
          _isRecognitionStarted = true;
          _statusText = 'Running';
        });
      }
    } catch (e, st) {
      debugPrint('toggleRecognition error: $e');
      debugPrintStack(stackTrace: st);

      setState(() {
        _errorMessage = 'Failed to toggle recognition: $e';
      });
    }
  }

  @override
  void dispose() {
    _nativeStreamSubscription?.cancel();
    NativeAslBridge.stopRecognition();
    _tfliteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASL Camera'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isModelLoaded ? _toggleRecognition : null,
        label: Text(_isRecognitionStarted ? 'Stop' : 'Start'),
        icon: Icon(_isRecognitionStarted ? Icons.stop : Icons.play_arrow),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (!_isModelLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const AndroidView(
          viewType: 'handee/native_camera_preview',
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
