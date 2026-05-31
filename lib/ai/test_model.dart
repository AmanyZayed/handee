import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';

class TestModel {
  late Interpreter interpreter;

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
    print("Model loaded");
  }

  void testRun() {
    // input shape [1, 543, 3]
    var input =
        List.generate(1, (_) => List.generate(543, (_) => List.filled(3, 0.0)));

    var output =
        List.filled(1 * 250, 0.0).reshape([1, 250]); // عدلي الرقم لو مختلف

    interpreter.run(input, output);

    print("Output: $output");
  }
}
