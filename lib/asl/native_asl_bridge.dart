import 'package:flutter/services.dart';

class NativeAslBridge {
  static const MethodChannel _methodChannel =
      MethodChannel('handee/asl_native');
  static const EventChannel _eventChannel = EventChannel('handee/asl_stream');

  static Future<String> initializeAslEngine() async {
    return await _methodChannel.invokeMethod('initializeAslEngine');
  }

  static Future<String> startRecognition() async {
    return await _methodChannel.invokeMethod('startRecognition');
  }

  static Future<String> stopRecognition() async {
    return await _methodChannel.invokeMethod('stopRecognition');
  }

  static Future<String> setRecognitionSettings({
    required String pipeline,
    required String classFilter,
    double? confThreshold,
  }) async {
    return await _methodChannel.invokeMethod('setRecognitionSettings', {
      'pipeline': pipeline,
      'classFilter': classFilter,
      if (confThreshold != null) 'confThreshold': confThreshold,
    });
  }

  static Stream<dynamic> get nativeStream {
    return _eventChannel.receiveBroadcastStream();
  }
}
