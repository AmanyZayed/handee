import 'package:flutter/services.dart';

class NativeAI {
  static const platform = MethodChannel('ai_channel');

  static Future<String> getPrediction() async {
    final result = await platform.invokeMethod('getPrediction');
    return result;
  }
}