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

  static Stream<dynamic> get nativeStream {
    return _eventChannel.receiveBroadcastStream();
  }
}
