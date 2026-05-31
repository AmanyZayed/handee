/// How the camera screen runs inference.
enum AslRecognitionPipeline {
  /// Holistic landmarks + sequence TFLite (`model.tflite`) — ASL words.
  words,

  /// `app.py` style: full_combined best.pt, margin crop, stable smoothing.
  yoloApp,

  /// `mediapipe_yolo_mode.py` style: letters_digits best.pt, tight crop.
  yoloFast,
}

/// Filter YOLO classes (digits / letters / both).
enum AslYoloClassFilter {
  digits,
  letters,
  both,
}

extension AslRecognitionPipelineNative on AslRecognitionPipeline {
  String get nativePipelineName {
    switch (this) {
      case AslRecognitionPipeline.words:
        return 'words';
      case AslRecognitionPipeline.yoloApp:
        return 'yolo_app';
      case AslRecognitionPipeline.yoloFast:
        return 'yolo_fast';
    }
  }

  String get displayName {
    switch (this) {
      case AslRecognitionPipeline.words:
        return 'Words';
      case AslRecognitionPipeline.yoloApp:
        return 'Letters/Digits (stable)';
      case AslRecognitionPipeline.yoloFast:
        return 'Letters/Digits (fast)';
    }
  }
}

extension AslYoloClassFilterNative on AslYoloClassFilter {
  String get nativeName {
    switch (this) {
      case AslYoloClassFilter.digits:
        return 'digits';
      case AslYoloClassFilter.letters:
        return 'letters';
      case AslYoloClassFilter.both:
        return 'both';
    }
  }

  double get defaultConfidenceThreshold {
    switch (this) {
      case AslYoloClassFilter.digits:
        return 0.35;
      case AslYoloClassFilter.letters:
      case AslYoloClassFilter.both:
        return 0.6;
    }
  }
}
