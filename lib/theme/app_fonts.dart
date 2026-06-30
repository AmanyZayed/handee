import 'package:flutter/material.dart';

/// Typography via fonts bundled in pubspec.yaml (works offline on device).
class AppFonts {
  static const plusFamily = 'Plus Jakarta Sans';
  static const spaceFamily = 'Space Grotesk';

  static TextStyle plusJakarta({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: plusFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  static TextStyle spaceGrotesk({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: spaceFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  static TextTheme plusJakartaTextTheme([TextTheme? base]) {
    final b = base ?? const TextTheme();
    return b.apply(fontFamily: plusFamily);
  }
}
