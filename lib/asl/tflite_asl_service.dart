import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteAslService {
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

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
