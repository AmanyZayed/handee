import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteAslService {
  static const int sequenceLength = 30;
  static const int landmarkCount = 543;
  static const int coordinateCount = 3;

  Interpreter? _interpreter;
  Map<String, dynamic>? _labelMap;
  Map<int, String>? _indexToLabelMap;

  bool get isLoaded => _interpreter != null && _labelMap != null;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');

    final String labelsJson = await rootBundle.loadString(
      'assets/models/sign_to_prediction_index_map.json',
    );

    _labelMap = jsonDecode(labelsJson) as Map<String, dynamic>;

    _indexToLabelMap = {};
    _labelMap!.forEach((label, index) {
      _indexToLabelMap![index as int] = label;
    });
  }

  Interpreter? get interpreter => _interpreter;
  Map<String, dynamic>? get labelMap => _labelMap;
  Map<int, String>? get indexToLabelMap => _indexToLabelMap;

  List<int> getInputShape() {
    if (_interpreter == null) {
      throw Exception('Interpreter is not loaded.');
    }
    return _interpreter!.getInputTensor(0).shape;
  }

  List<int> getOutputShape() {
    if (_interpreter == null) {
      throw Exception('Interpreter is not loaded.');
    }
    return _interpreter!.getOutputTensor(0).shape;
  }

  String getInputType() {
    if (_interpreter == null) {
      throw Exception('Interpreter is not loaded.');
    }
    return _interpreter!.getInputTensor(0).type.toString();
  }

  String getOutputType() {
    if (_interpreter == null) {
      throw Exception('Interpreter is not loaded.');
    }
    return _interpreter!.getOutputTensor(0).type.toString();
  }

  int getLabelCount() {
    return _indexToLabelMap?.length ?? 0;
  }

  PredictionResult? predictFromLandmarks(List<List<double>> frames) {
    if (_interpreter == null) {
      throw Exception('Interpreter is not loaded.');
    }

    final inputShape = _interpreter!.getInputTensor(0).shape;
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final input = _buildModelInput(inputShape, frames);
    final output = _buildZeroTensor(outputShape);

    _interpreter!.run(input, output);

    final scores = _flattenToDoubleList(output);
    if (scores.isEmpty || _indexToLabelMap == null || _indexToLabelMap!.isEmpty) {
      return null;
    }

    var bestIndex = 0;
    var bestScore = scores.first;

    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndex = i;
      }
    }

    final label = _indexToLabelMap![bestIndex];
    if (label == null) {
      return null;
    }

    return PredictionResult(
      label: label,
      confidence: bestScore,
      index: bestIndex,
      scores: scores,
      topPredictions: getTopPredictions(scores),
    );
  }

  List<double> runDryInference() {
    if (_interpreter == null) {
      throw Exception('Interpreter is not loaded.');
    }

    final inputShape = _interpreter!.getInputTensor(0).shape;
    final outputShape = _interpreter!.getOutputTensor(0).shape;

    final input = _buildZeroTensor(inputShape);
    final output = _buildZeroTensor(outputShape);

    _interpreter!.run(input, output);

    return _flattenToDoubleList(output);
  }

  List<TopPrediction> getTopPredictions(List<double> scores, {int count = 3}) {
    if (_indexToLabelMap == null || _indexToLabelMap!.isEmpty || scores.isEmpty) {
      return const <TopPrediction>[];
    }

    final indexedScores = List<int>.generate(scores.length, (index) => index);
    indexedScores.sort((a, b) => scores[b].compareTo(scores[a]));

    return indexedScores.take(count).map((index) {
      return TopPrediction(
        index: index,
        label: _indexToLabelMap![index] ?? 'Unknown',
        confidence: scores[index],
      );
    }).toList(growable: false);
  }

  dynamic _buildModelInput(List<int> inputShape, List<List<double>> frames) {
    if (inputShape.length == 3) {
      final frameCount = inputShape[0];
      final landmarkCount = inputShape[1];
      final coordinateCount = inputShape[2];
      final expectedFrameSize = landmarkCount * coordinateCount;
      final normalizedFrames = _padOrTrimFrames(
        frames,
        frameCount,
        expectedFrameSize,
      );

      return normalizedFrames
          .map((frame) => _reshapeFrame(frame, landmarkCount, coordinateCount))
          .toList(growable: false);
    }

    if (inputShape.length == 4) {
      final batchCount = inputShape[0];
      final frameCount = inputShape[1];
      final landmarkCount = inputShape[2];
      final coordinateCount = inputShape[3];
      final expectedFrameSize = landmarkCount * coordinateCount;
      final normalizedFrames = _padOrTrimFrames(
        frames,
        frameCount,
        expectedFrameSize,
      );

      if (batchCount != 1) {
        throw Exception('Unsupported batched model input shape: $inputShape');
      }

      return <List<List<List<double>>>>[
        normalizedFrames
            .map((frame) => _reshapeFrame(frame, landmarkCount, coordinateCount))
            .toList(growable: false),
      ];
    }

    throw Exception('Unsupported model input shape: $inputShape');
  }

  List<List<double>> _padOrTrimFrames(
    List<List<double>> frames,
    int requiredFrameCount,
    int expectedFrameSize,
  ) {
    final normalizedFrames = frames
        .map((frame) => _padOrTrimFrame(frame, expectedFrameSize))
        .toList();

    if (normalizedFrames.length >= requiredFrameCount) {
      return normalizedFrames.sublist(
        normalizedFrames.length - requiredFrameCount,
      );
    }

    final missingCount = requiredFrameCount - normalizedFrames.length;
    final nanFrame = List<double>.filled(expectedFrameSize, double.nan);

    return [
      ...List.generate(missingCount, (_) => List<double>.from(nanFrame)),
      ...normalizedFrames,
    ];
  }

  List<double> _padOrTrimFrame(List<double> frame, int expectedSize) {
    if (frame.length == expectedSize) {
      return List<double>.from(frame);
    }

    if (frame.length > expectedSize) {
      return frame.sublist(0, expectedSize);
    }

    return [
      ...frame,
      ...List<double>.filled(expectedSize - frame.length, double.nan),
    ];
  }

  List<List<double>> _reshapeFrame(
    List<double> frame,
    int landmarkCount,
    int coordinateCount,
  ) {
    return List.generate(
      landmarkCount,
      (index) {
        final start = index * coordinateCount;
        final end = math.min(start + coordinateCount, frame.length);
        final values = frame.sublist(start, end);
        if (values.length == coordinateCount) {
          return values;
        }

        return [
          ...values,
          ...List<double>.filled(coordinateCount - values.length, double.nan),
        ];
      },
    );
  }

  dynamic _buildZeroTensor(List<int> shape) {
    if (shape.isEmpty) {
      return 0.0;
    }

    return List.generate(
      shape.first,
      (_) => _buildZeroTensor(shape.sublist(1)),
    );
  }

  List<double> _flattenToDoubleList(dynamic value) {
    if (value is num) {
      return [value.toDouble()];
    }

    if (value is List) {
      return value
          .expand<double>((item) => _flattenToDoubleList(item))
          .toList();
    }

    throw Exception('Unsupported tensor value: ${value.runtimeType}');
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

class PredictionResult {
  const PredictionResult({
    required this.label,
    required this.confidence,
    required this.index,
    required this.scores,
    required this.topPredictions,
    this.margin,
  });

  final String label;
  final double confidence;
  final int index;
  final List<double> scores;
  final List<TopPrediction> topPredictions;
  final double? margin;
}

class TopPrediction {
  const TopPrediction({
    required this.index,
    required this.label,
    required this.confidence,
  });

  final int index;
  final String label;
  final double confidence;
}
