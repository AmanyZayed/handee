import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'asl_recognition_mode.dart';
import 'asl_skeleton_overlay.dart';
import 'native_asl_bridge.dart';
import 'tflite_asl_service.dart';
import 'yolo_prediction_smoother.dart';

class AslCameraScreen extends StatefulWidget {
  const AslCameraScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _profileConfig = _profileConfigs[_predictionProfile]!;
    _listenToNativeStream();
    _startSetup();
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
        _stableLabel = prediction.label;
        _stableConfidence = prediction.confidence;
        _stableUpdatedAt = DateTime.now();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _isModelLoaded && _cameraPermissionGranted && !_isSettingUp
            ? _toggleRecognition
            : null,
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

    if (_isSettingUp || !_isModelLoaded) {
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
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: _showSkeletonOverlay
                    ? 'Hide skeleton overlay'
                    : 'Show skeleton overlay (testing)',
                onPressed: () {
                  setState(() {
                    _showSkeletonOverlay = !_showSkeletonOverlay;
                    if (!_showSkeletonOverlay) {
                      _skeletonLandmarks.value = null;
                    }
                  });
                },
                icon: Icon(
                  _showSkeletonOverlay
                      ? Icons.visibility
                      : Icons.visibility_off_outlined,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 24,
          left: 24,
          right: 72,
          child: SafeArea(
            bottom: false,
            child: _StatusPill(
              text: _predictionDisplayText,
              fontSize: _pipeline == AslRecognitionPipeline.yoloApp ? 16 : 20,
              horizontalPadding: 18,
              verticalPadding: 12,
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 88,
          child: SafeArea(
            top: false,
            child: _ModeSelector(
              pipeline: _pipeline,
              yoloFilter: _yoloFilter,
              enabled: !_isRecognitionStarted,
              onPipelineChanged: _onPipelineChanged,
              onYoloFilterChanged: _onYoloFilterChanged,
            ),
          ),
        ),
      ],
    );
  }
}

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
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Recognition mode',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: AslRecognitionPipeline.values.map((mode) {
                final selected = pipeline == mode;
                return ChoiceChip(
                  label: Text(
                    mode.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? Colors.white : Colors.white70,
                    ),
                  ),
                  selected: selected,
                  onSelected: enabled
                      ? (_) => onPipelineChanged(mode)
                      : null,
                );
              }).toList(),
            ),
            if (pipeline != AslRecognitionPipeline.words) ...[
              const SizedBox(height: 8),
              const Text(
                'YOLO classes',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: AslYoloClassFilter.values.map((filter) {
                  final selected = yoloFilter == filter;
                  return ChoiceChip(
                    label: Text(
                      filter.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white : Colors.white70,
                      ),
                    ),
                    selected: selected,
                    onSelected: enabled
                        ? (_) => onYoloFilterChanged(filter)
                        : null,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    this.fontSize = 14,
    this.horizontalPadding = 14,
    this.verticalPadding = 8,
  });

  final String text;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
