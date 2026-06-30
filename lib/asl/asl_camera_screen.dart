import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:handee/theme/app_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'asl_ai_mode.dart';
import 'asl_recognition_mode.dart';
import 'asl_skeleton_overlay.dart';
import 'native_asl_bridge.dart';
import 'tflite_asl_service.dart';
import 'yolo_prediction_smoother.dart';
import '../theme/app_theme.dart';

class AslCameraScreen extends StatefulWidget {
  const AslCameraScreen({super.key, this.isTab = false});

  /// When true the back button in the overlay is hidden (used when embedded as a tab).
  final bool isTab;

  @override
  State<AslCameraScreen> createState() => _AslCameraScreenState();
}

enum _PredictionProfile {
  fast,
  balanced,
  stable,
}

class _PredictionProfileConfig {
  const _PredictionProfileConfig({
    required this.predictionStrideFrames,
    required this.fastAcceptConfidence,
    required this.requiredStableRepeats,
    required this.recentHandWindowSize,
    required this.minRecentHandRatioForAccept,
    required this.stablePredictionHold,
  });

  final int predictionStrideFrames;
  final double fastAcceptConfidence;
  final int requiredStableRepeats;
  final int recentHandWindowSize;
  final double minRecentHandRatioForAccept;
  final Duration stablePredictionHold;
}

class _AslCameraScreenState extends State<AslCameraScreen> {
  static const int _maxSequenceFrames = 30;
  static const int _minFramesBeforePrediction = 1;
  static const double _minPredictionConfidence = 0.70;

  static const _PredictionProfile _predictionProfile = _PredictionProfile.balanced;
  static const Map<_PredictionProfile, _PredictionProfileConfig> _profileConfigs = {
    _PredictionProfile.fast: _PredictionProfileConfig(
      predictionStrideFrames: 2,
      fastAcceptConfidence: 0.82,
      requiredStableRepeats: 1,
      recentHandWindowSize: 10,
      minRecentHandRatioForAccept: 0.25,
      stablePredictionHold: Duration(milliseconds: 900),
    ),
    _PredictionProfile.balanced: _PredictionProfileConfig(
      predictionStrideFrames: 3,
      fastAcceptConfidence: 0.85,
      requiredStableRepeats: 2,
      recentHandWindowSize: 12,
      minRecentHandRatioForAccept: 0.35,
      stablePredictionHold: Duration(milliseconds: 1400),
    ),
    _PredictionProfile.stable: _PredictionProfileConfig(
      predictionStrideFrames: 4,
      fastAcceptConfidence: 0.88,
      requiredStableRepeats: 3,
      recentHandWindowSize: 15,
      minRecentHandRatioForAccept: 0.45,
      stablePredictionHold: Duration(milliseconds: 1800),
    ),
  };

  final TfliteAslService _tfliteService = TfliteAslService();
  final YoloPredictionSmoother _yoloSmoother = YoloPredictionSmoother();
  final List<List<double>> _landmarkFrames = <List<double>>[];
  final List<bool> _handDetectedFrames = <bool>[];
  StreamSubscription? _nativeStreamSubscription;

  AslRecognitionPipeline _pipeline = AslRecognitionPipeline.words;
  AslYoloClassFilter _yoloFilter = AslYoloClassFilter.both;
  String? _yoloRawLabel;
  double _yoloRawConfidence = 0;
  String? _yoloStableLabel;

  bool _isModelLoaded = false;
  bool _isRecognitionStarted = false;
  bool _cameraPermissionGranted = false;
  bool _isSettingUp = true;

  String? _errorMessage;
  String? _predictedLabel;
  int _analyzedFramesSincePrediction = 0;
  String? _stableLabel;
  double _stableConfidence = 0;
  DateTime? _stableUpdatedAt;
  String? _candidateLabel;
  int _candidateRepeatCount = 0;
  late final _PredictionProfileConfig _profileConfig;

  final ValueNotifier<List<double>?> _skeletonLandmarks =
      ValueNotifier<List<double>?>(null);
  bool _showSkeletonOverlay = false;

  AslAiMode _aiMode = AslAiMode.detect;
  String _composedText = '';
  String? _lastAcceptedLabel;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _profileConfig = _profileConfigs[_predictionProfile]!;
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.45);
    _listenToNativeStream();
    _startSetup();
  }

  Future<void> _onAiModeChanged(AslAiMode mode) async {
    if (_isRecognitionStarted) {
      await NativeAslBridge.stopRecognition();
    }
    setState(() {
      _aiMode = mode;
      _composedText = '';
      _lastAcceptedLabel = null;
      _isRecognitionStarted = false;
    });

    if (mode == AslAiMode.buildSentence) {
      await _onPipelineChanged(AslRecognitionPipeline.words);
    } else if (mode == AslAiMode.buildWord) {
      await _onPipelineChanged(AslRecognitionPipeline.yoloFast);
      await _onYoloFilterChanged(AslYoloClassFilter.both);
    } else if (mode == AslAiMode.signToSpeech) {
      await _onPipelineChanged(AslRecognitionPipeline.words);
    }
  }

  void _acceptSign(String rawLabel) {
    final label = rawLabel.trim();
    if (label.isEmpty || label == _lastAcceptedLabel) return;
    _lastAcceptedLabel = label;

    switch (_aiMode) {
      case AslAiMode.detect:
        return;
      case AslAiMode.buildSentence:
        setState(() {
          _composedText =
              _composedText.isEmpty ? label : '$_composedText $label';
        });
      case AslAiMode.buildWord:
        setState(() {
          _composedText = '$_composedText$label';
        });
      case AslAiMode.signToSpeech:
        setState(() => _composedText = label);
        _tts.speak(label);
    }
  }

  void _clearComposed() {
    setState(() {
      _composedText = '';
      _lastAcceptedLabel = null;
    });
  }

  Future<void> _speakComposed() async {
    if (_composedText.trim().isEmpty) return;
    await _tts.speak(_composedText.trim());
  }

  void _maybeAcceptFromWords() {
    if (_aiMode == AslAiMode.detect || _stableLabel == null) return;
    _acceptSign(_stableLabel!);
  }

  void _maybeAcceptFromYolo() {
    if (_aiMode != AslAiMode.buildWord) return;
    final label = _yoloStableLabel ?? _yoloRawLabel;
    if (label == null || label.isEmpty) return;
    _acceptSign(label);
  }

  void _listenToNativeStream() {
    _nativeStreamSubscription = NativeAslBridge.nativeStream.listen(
      (event) {
        if (!mounted || event == null || event is! Map) {
          return;
        }

        final type = event['type'];

        if (type == 'status' || type == 'frame_update') {
          final message = event['message']?.toString() ?? '';
          if (type == 'status' &&
              (message.contains('Failed') ||
                  message.contains('failed') ||
                  message.contains('error'))) {
            setState(() {
              _errorMessage = message;
            });
          }
          return;
        }

        if (type == 'yolo_prediction') {
          _handleYoloPrediction(event);
          return;
        }

        if (type != 'landmark_update') {
          return;
        }

        final leftHandCount = (event['leftHandCount'] as num?)?.toInt() ?? 0;
        final rightHandCount = (event['rightHandCount'] as num?)?.toInt() ?? 0;
        final frameCount = (event['frameCount'] as num?)?.toInt() ?? 0;
        final landmarkValues =
            (event['landmarks'] as List?)
                ?.map((value) => (value as num).toDouble())
                .toList() ??
            const <double>[];

        if (_showSkeletonOverlay && landmarkValues.isNotEmpty) {
          _skeletonLandmarks.value = List<double>.from(landmarkValues);
        }

        _handleLandmarkFrame(
          frameCount: frameCount,
          leftHandCount: leftHandCount,
          rightHandCount: rightHandCount,
          landmarkValues: landmarkValues,
        );
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
    await _requestCameraPermission();
    if (_errorMessage != null) return;

    await _initializeNative();
    if (_errorMessage != null) return;

    await _applyNativeRecognitionSettings();
    if (_errorMessage != null) return;

    await _loadModel();
    if (!mounted) return;
    setState(() {
      _isSettingUp = false;
    });
  }

  Future<void> _retrySetup() async {
    setState(() {
      _errorMessage = null;
      _isSettingUp = true;
      _isModelLoaded = false;
      _cameraPermissionGranted = false;
    });
    await _startSetup();
  }

  Future<void> _openCameraSettings() async {
    await openAppSettings();
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();

      if (!mounted) return;

      if (status.isGranted) {
        setState(() {
          _cameraPermissionGranted = true;
        });
        return;
      }

      setState(() {
        _errorMessage = 'Camera permission is required to use ASL recognition.';
        _isSettingUp = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not request camera permission. Please try again.';
        _isSettingUp = false;
      });
    }
  }

  Future<void> _initializeNative() async {
    try {
      final message = await NativeAslBridge.initializeAslEngine();
      debugPrint('initializeAslEngine -> $message');

      if (!mounted) return;
    } catch (e, st) {
      debugPrint('initializeNative error: $e');
      debugPrintStack(stackTrace: st);

      setState(() {
        _errorMessage = 'Could not initialize the camera engine.';
        _isSettingUp = false;
      });
    }
  }

  Future<void> _applyNativeRecognitionSettings() async {
    try {
      final message = await NativeAslBridge.setRecognitionSettings(
        pipeline: _pipeline.nativePipelineName,
        classFilter: _yoloFilter.nativeName,
        confThreshold: _yoloFilter.defaultConfidenceThreshold,
      );
      debugPrint('setRecognitionSettings -> $message');
    } catch (e, st) {
      debugPrint('setRecognitionSettings error: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not configure recognition pipeline.';
        _isSettingUp = false;
      });
    }
  }

  Future<void> _loadModel() async {
    if (_pipeline != AslRecognitionPipeline.words) {
      if (!mounted) return;
      setState(() {
        _isModelLoaded = true;
      });
      return;
    }

    try {
      await _tfliteService.loadModel();

      final dryRunOutput = _tfliteService.runDryInference();

      debugPrint('SIGN MODEL DRY RUN -> ${dryRunOutput.take(5).toList()}');

      if (!mounted) return;

      setState(() {
        _isModelLoaded = true;
      });
    } catch (e, st) {
      debugPrint('loadModel error: $e');
      debugPrintStack(stackTrace: st);

      setState(() {
        _errorMessage = 'Could not load the sign recognition model.';
        _isSettingUp = false;
      });
    }
  }

  void _handleYoloPrediction(Map<dynamic, dynamic> event) {
    if (!_isRecognitionStarted || _pipeline == AslRecognitionPipeline.words) {
      return;
    }

    final rawLabel = event['rawLabel'] as String?;
    final rawConfidence = (event['rawConfidence'] as num?)?.toDouble() ?? 0;
    final topLabel = event['topLabel']?.toString() ?? '';

    _yoloRawLabel = rawLabel;
    _yoloRawConfidence = rawConfidence;

    if (_pipeline == AslRecognitionPipeline.yoloApp) {
      _yoloSmoother.addRaw(rawLabel);
      _yoloStableLabel = _yoloSmoother.stableLabel();
    } else {
      _yoloStableLabel = rawLabel;
    }

    if (!mounted) return;
    setState(() {
      _updateYoloDisplayText(topLabel: topLabel);
      _maybeAcceptFromYolo();
    });
  }

  void _updateYoloDisplayText({required String topLabel}) {
    if (_pipeline == AslRecognitionPipeline.yoloApp) {
      final rawPart = _yoloRawLabel != null
          ? '${_yoloRawLabel!} (${(_yoloRawConfidence * 100).toStringAsFixed(0)}%)'
          : 'None';
      final stablePart = _yoloStableLabel ?? 'None';
      _predictedLabel = 'RAW: $rawPart · STABLE: $stablePart';
      return;
    }

    if (_yoloRawLabel != null) {
      final percent = (_yoloRawConfidence * 100).toStringAsFixed(0);
      _predictedLabel = '${_yoloRawLabel!} ($percent%)';
    } else if (topLabel.isNotEmpty) {
      final percent = (_yoloRawConfidence * 100).toStringAsFixed(0);
      _predictedLabel = 'Uncertain ($topLabel $percent%)';
    } else {
      _predictedLabel = 'No hand';
    }
  }

  void _handleLandmarkFrame({
    required int frameCount,
    required int leftHandCount,
    required int rightHandCount,
    required List<double> landmarkValues,
  }) {
    if (!_isRecognitionStarted || !_isModelLoaded) {
      return;
    }

    if (_pipeline != AslRecognitionPipeline.words) {
      return;
    }

    final hasHand = leftHandCount > 0 || rightHandCount > 0;
    final frameValues = (landmarkValues.isEmpty)
        ? List<double>.filled(
            TfliteAslService.landmarkCount * TfliteAslService.coordinateCount,
            double.nan,
          )
        : List<double>.from(landmarkValues);

    _landmarkFrames.add(frameValues);
    _handDetectedFrames.add(hasHand);
    if (_landmarkFrames.length > _maxSequenceFrames) {
      _landmarkFrames.removeAt(0);
      _handDetectedFrames.removeAt(0);
    }
    _analyzedFramesSincePrediction++;

    if (_landmarkFrames.length < _minFramesBeforePrediction) return;

    if (_analyzedFramesSincePrediction < _profileConfig.predictionStrideFrames) {
      return;
    }

    final sequence = _landmarkFrames
        .map((frame) => List<double>.from(frame))
        .toList(growable: false);
    final sequencePrediction = _tfliteService.predictFromLandmarks(sequence);
    _analyzedFramesSincePrediction = 0;

    if (!mounted) return;

    setState(() {
      if (sequencePrediction == null) {
        _renderPredictionUnavailable();
      } else {
        _updateSmoothedPrediction(sequencePrediction);
      }
    });
  }

  void _updateSmoothedPrediction(PredictionResult prediction) {
    final isAboveMinConfidence = prediction.confidence >= _minPredictionConfidence;
    final recentHandRatio = _getRecentHandRatio();
    final hasEnoughRecentHandSignal =
        recentHandRatio >= _profileConfig.minRecentHandRatioForAccept;

    if (isAboveMinConfidence && hasEnoughRecentHandSignal) {
      if (_candidateLabel == prediction.label) {
        _candidateRepeatCount++;
      } else {
        _candidateLabel = prediction.label;
        _candidateRepeatCount = 1;
      }

      final canFastAccept =
          prediction.confidence >= _profileConfig.fastAcceptConfidence;
      final canStableAccept =
          _candidateRepeatCount >= _profileConfig.requiredStableRepeats;
      if (canFastAccept || canStableAccept) {
        final prev = _stableLabel;
        _stableLabel = prediction.label;
        _stableConfidence = prediction.confidence;
        _stableUpdatedAt = DateTime.now();
        if (prev != prediction.label) {
          _maybeAcceptFromWords();
        }
      }
    } else {
      _candidateLabel = null;
      _candidateRepeatCount = 0;
    }

    if (_stableLabel != null && _stableUpdatedAt != null) {
      final isWithinHold =
          DateTime.now().difference(_stableUpdatedAt!) <=
              _profileConfig.stablePredictionHold;
      if (isWithinHold || isAboveMinConfidence) {
        final percent = (_stableConfidence * 100).toStringAsFixed(0);
        _predictedLabel = '$_stableLabel ($percent%)';
        return;
      }
    }

    final percent = (prediction.confidence * 100).toStringAsFixed(0);
    _predictedLabel = 'Low confidence (${prediction.label} $percent%)';
  }

  void _renderPredictionUnavailable() {
    if (_stableLabel != null && _stableUpdatedAt != null) {
      final isWithinHold =
          DateTime.now().difference(_stableUpdatedAt!) <=
              _profileConfig.stablePredictionHold;
      if (isWithinHold) {
        final percent = (_stableConfidence * 100).toStringAsFixed(0);
        _predictedLabel = '$_stableLabel ($percent%)';
        return;
      }
    }
    _predictedLabel = 'Prediction unavailable';
  }

  String get _predictionDisplayText {
    if (_predictedLabel != null) return _predictedLabel!;
    if (!_isRecognitionStarted) {
      return 'Tap Start · ${_pipeline.displayName}';
    }
    if (_pipeline == AslRecognitionPipeline.words) {
      return 'Reading sign...';
    }
    return 'Show your hand...';
  }

  double _getRecentHandRatio() {
    if (_handDetectedFrames.isEmpty) {
      return 0;
    }
    final startIndex =
        _handDetectedFrames.length > _profileConfig.recentHandWindowSize
        ? _handDetectedFrames.length - _profileConfig.recentHandWindowSize
        : 0;
    final recentWindow = _handDetectedFrames.sublist(startIndex);
    final detectedCount = recentWindow.where((value) => value).length;
    return detectedCount / recentWindow.length;
  }

  Future<void> _onPipelineChanged(AslRecognitionPipeline pipeline) async {
    if (_isRecognitionStarted) {
      await NativeAslBridge.stopRecognition();
    }

    setState(() {
      _pipeline = pipeline;
      _isRecognitionStarted = false;
      _isModelLoaded = false;
      _predictedLabel = null;
      _yoloRawLabel = null;
      _yoloStableLabel = null;
      _yoloRawConfidence = 0;
      _yoloSmoother.reset();
      _landmarkFrames.clear();
      _handDetectedFrames.clear();
    });

    await _applyNativeRecognitionSettings();
    await _loadModel();
  }

  Future<void> _onYoloFilterChanged(AslYoloClassFilter filter) async {
    setState(() {
      _yoloFilter = filter;
      _yoloSmoother.reset();
      _yoloRawLabel = null;
      _yoloStableLabel = null;
    });
    await _applyNativeRecognitionSettings();
    if (_isRecognitionStarted) {
      await NativeAslBridge.setRecognitionSettings(
        pipeline: _pipeline.nativePipelineName,
        classFilter: _yoloFilter.nativeName,
        confThreshold: _yoloFilter.defaultConfidenceThreshold,
      );
    }
  }

  Future<void> _toggleRecognition() async {
    try {
      if (_isRecognitionStarted) {
        debugPrint('STOP button pressed');

        final stopMessage = await NativeAslBridge.stopRecognition();
        debugPrint('stopRecognition -> $stopMessage');

        if (!mounted) return;

        setState(() {
          _isRecognitionStarted = false;
          _predictedLabel = null;
          _skeletonLandmarks.value = null;
          _landmarkFrames.clear();
          _handDetectedFrames.clear();
          _analyzedFramesSincePrediction = 0;
          _stableLabel = null;
          _stableConfidence = 0;
          _stableUpdatedAt = null;
          _candidateLabel = null;
          _candidateRepeatCount = 0;
          _yoloSmoother.reset();
          _yoloRawLabel = null;
          _yoloStableLabel = null;
          _lastAcceptedLabel = null;
        });
      } else {
        debugPrint('START button pressed');

        _landmarkFrames.clear();
        _handDetectedFrames.clear();
        _analyzedFramesSincePrediction = 0;
        _stableLabel = null;
        _stableConfidence = 0;
        _stableUpdatedAt = null;
        _candidateLabel = null;
        _candidateRepeatCount = 0;
        _yoloSmoother.reset();
        _yoloRawLabel = null;
        _yoloStableLabel = null;
        await _applyNativeRecognitionSettings();
        final startMessage = await NativeAslBridge.startRecognition();
        debugPrint('startRecognition -> $startMessage');
        if (startMessage.contains('not ready') ||
            startMessage.contains('Failed') ||
            startMessage.contains('failed')) {
          if (!mounted) return;
          setState(() {
            _errorMessage = startMessage;
          });
          return;
        }

        debugPrint('NativeAslBridge.startRecognition() finished');

        if (!mounted) return;

        setState(() {
          _isRecognitionStarted = true;
          _predictedLabel = null;
        });
      }
    } catch (e, st) {
      debugPrint('toggleRecognition error: $e');
      debugPrintStack(stackTrace: st);

      setState(() {
        _errorMessage = 'Could not change recognition state. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _nativeStreamSubscription?.cancel();
    NativeAslBridge.stopRecognition();
    _skeletonLandmarks.dispose();
    _tfliteService.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _CameraError(
        message: _errorMessage!,
        onRetry: _retrySetup,
        onOpenSettings: _errorMessage!.toLowerCase().contains('permission')
            ? _openCameraSettings
            : null,
      );
    }

    if (_isSettingUp || !_isModelLoaded) {
      return const _CameraLoading();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Native camera view
        const AndroidView(viewType: 'handee/native_camera_preview'),

        // Skeleton overlay
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<List<double>?>(
              valueListenable: _skeletonLandmarks,
              builder: (context, landmarks, _) {
                if (!_showSkeletonOverlay ||
                    landmarks == null ||
                    landmarks.isEmpty) {
                  return const SizedBox.shrink();
                }
                return HolisticSkeletonOverlay(
                  landmarks: landmarks,
                  mirrorX: true,
                );
              },
            ),
          ),
        ),

        // Top bar: back + skeleton toggle
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (!widget.isTab)
                    _GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  const SizedBox(width: 8),
                  // Mode label pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sign_language_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _pipeline.displayName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _GlassIconButton(
                    icon: _showSkeletonOverlay
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_outlined,
                    active: _showSkeletonOverlay,
                    onTap: () {
                      setState(() {
                        _showSkeletonOverlay = !_showSkeletonOverlay;
                        if (!_showSkeletonOverlay) {
                          _skeletonLandmarks.value = null;
                        }
                      });
                    },
                    tooltip: _showSkeletonOverlay
                        ? 'Hide skeleton'
                        : 'Show skeleton',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Live prediction — anchored just below the top bar
        Positioned(
          top: 80,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: _StatusPill(
              text: _predictionDisplayText,
              fontSize:
                  _pipeline == AslRecognitionPipeline.yoloApp ? 15 : 20,
            ),
          ),
        ),

        // Bottom controls — compose panel, mode bar, mode selector, FAB
        // All in one fluid column so heights are never hard-coded.
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_aiMode != AslAiMode.detect)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AiComposePanel(
                        mode: _aiMode,
                        text: _composedText,
                        onClear: _clearComposed,
                        onSpeak: _speakComposed,
                      ),
                    ),
                  _AiModeBar(
                    selected: _aiMode,
                    enabled: !_isRecognitionStarted,
                    onChanged: _onAiModeChanged,
                  ),
                  const SizedBox(height: 10),
                  _ModeSelector(
                    pipeline: _pipeline,
                    yoloFilter: _yoloFilter,
                    enabled: !_isRecognitionStarted,
                    onPipelineChanged: _onPipelineChanged,
                    onYoloFilterChanged: _onYoloFilterChanged,
                  ),
                  if (_isModelLoaded && _cameraPermissionGranted && !_isSettingUp) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: _CameraFab(
                        isRunning: _isRecognitionStarted,
                        onTap: _toggleRecognition,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera FAB – gradient circle, stop=red / start=electric blue
// ─────────────────────────────────────────────────────────────────────────────
class _CameraFab extends StatelessWidget {
  const _CameraFab({required this.isRunning, required this.onTap});
  final bool isRunning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isRunning
                ? [const Color(0xFFE53935), const Color(0xFFEF5350)]
                : [AppColors.primary, AppColors.electric],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isRunning ? const Color(0xFFE53935) : AppColors.primary)
                  .withValues(alpha: 0.55),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass icon button
// ─────────────────────────────────────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.active = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: active
                ? AppColors.electric.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.48),
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? AppColors.cyan.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            icon,
            color: active ? AppColors.cyan : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading screen
// ─────────────────────────────────────────────────────────────────────────────
class _CameraLoading extends StatelessWidget {
  const _CameraLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.electric],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadow.button,
              ),
              child: const Icon(Icons.sign_language_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 22),
            Text(
              'Initializing camera…',
              style: AppFonts.plusJakarta(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(
                color: AppColors.electric,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error screen
// ─────────────────────────────────────────────────────────────────────────────
class _CameraError extends StatelessWidget {
  const _CameraError({
    required this.message,
    required this.onRetry,
    this.onOpenSettings,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      child: Center(
        child: Padding(
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
                    color: AppColors.error.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.videocam_off_rounded,
                    size: 38, color: AppColors.error),
              ),
              const SizedBox(height: 22),
              Text(
                'Camera Error',
                style: AppFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppFonts.plusJakarta(
                  fontSize: 14,
                  color: const Color(0xFF9DB0E8),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              if (onOpenSettings != null) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onOpenSettings,
                  child: Text(
                    'Open settings',
                    style: AppFonts.plusJakarta(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode selector panel (glass card above FAB)
// ─────────────────────────────────────────────────────────────────────────────
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.pipeline,
    required this.yoloFilter,
    required this.enabled,
    required this.onPipelineChanged,
    required this.onYoloFilterChanged,
  });

  final AslRecognitionPipeline pipeline;
  final AslYoloClassFilter yoloFilter;
  final bool enabled;
  final ValueChanged<AslRecognitionPipeline> onPipelineChanged;
  final ValueChanged<AslYoloClassFilter> onYoloFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC0B1030),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'RECOGNITION MODE',
            style: AppFonts.plusJakarta(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7C8AC0),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AslRecognitionPipeline.values.map((mode) {
              final selected = pipeline == mode;
              return GestureDetector(
                onTap: enabled ? () => onPipelineChanged(mode) : null,
                child: AnimatedOpacity(
                  opacity: enabled ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.electric],
                            )
                          : null,
                      color: selected ? null : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      mode.displayName,
                      style: AppFonts.plusJakarta(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (pipeline != AslRecognitionPipeline.words) ...[
            const SizedBox(height: 10),
            Text(
              'YOLO CLASSES',
              style: AppFonts.plusJakarta(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7C8AC0),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: AslYoloClassFilter.values.map((filter) {
                final selected = yoloFilter == filter;
                return GestureDetector(
                  onTap: enabled ? () => onYoloFilterChanged(filter) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.cyan.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: selected
                            ? AppColors.cyan.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      filter.name,
                      style: AppFonts.plusJakarta(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.cyan : Colors.white70,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI mode bar + compose panel
// ─────────────────────────────────────────────────────────────────────────────

class _AiModeBar extends StatelessWidget {
  const _AiModeBar({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final AslAiMode selected;
  final bool enabled;
  final ValueChanged<AslAiMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AslAiMode.values.map((mode) {
          final active = mode == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: enabled ? () => onChanged(mode) : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: active
                        ? AppColors.electric
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  mode.label,
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AiComposePanel extends StatelessWidget {
  const _AiComposePanel({
    required this.mode,
    required this.text,
    required this.onClear,
    required this.onSpeak,
  });

  final AslAiMode mode;
  final String text;
  final VoidCallback onClear;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xE60B1030),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.electric.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mode.hint.toUpperCase(),
            style: AppFonts.plusJakarta(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.cyan,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text.isEmpty ? '…' : text,
            style: AppFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: onClear,
                child: Text(
                  'Clear',
                  style: AppFonts.plusJakarta(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: text.trim().isEmpty ? null : onSpeak,
                icon: const Icon(Icons.volume_up_rounded, size: 16),
                label: const Text('Speak'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Prediction status pill
// ─────────────────────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, this.fontSize = 20});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xBF0B1030),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppColors.electric.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppFonts.spaceGrotesk(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
