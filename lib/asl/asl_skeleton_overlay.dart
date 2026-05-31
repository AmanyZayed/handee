import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'tflite_asl_service.dart';

/// Draws Holistic-style landmarks on top of the camera preview.
/// Flat buffer order must match native: face -> left hand -> pose -> right hand.
class HolisticSkeletonOverlay extends StatelessWidget {
  const HolisticSkeletonOverlay({
    super.key,
    required this.landmarks,
    this.mirrorX = true,
  });

  final List<double> landmarks;
  final bool mirrorX;

  static const int _faceCount = 468;
  static const int _leftHandCount = 21;
  static const int _poseCount = 33;

  static const int _faceBase = 0;
  static const int _leftBase = _faceCount * 3;
  static const int _poseBase = (_faceCount + _leftHandCount) * 3;
  static const int _rightBase = (_faceCount + _leftHandCount + _poseCount) * 3;

  static const List<List<int>> _handConnections = [
    [0, 1], [1, 2], [2, 3], [3, 4],
    [0, 5], [5, 6], [6, 7], [7, 8],
    [0, 9], [9, 10], [10, 11], [11, 12],
    [0, 13], [13, 14], [14, 15], [15, 16],
    [0, 17], [17, 18], [18, 19], [19, 20],
    [5, 9], [9, 13], [13, 17],
  ];

  static const List<List<int>> _poseConnections = [
    [11, 13], [13, 15], [15, 17], [15, 19], [15, 21],
    [12, 14], [14, 16], [16, 18], [16, 20], [16, 22],
    [11, 12], [11, 23], [12, 24], [23, 24],
    [23, 25], [25, 27], [27, 29], [27, 31],
    [24, 26], [26, 28], [28, 30], [28, 32],
    [0, 1], [1, 2], [2, 3], [3, 7],
    [0, 4], [4, 5], [5, 6], [6, 8],
    [9, 10],
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HolisticSkeletonPainter(
        landmarks: landmarks,
        mirrorX: mirrorX,
      ),
    );
  }
}

class _HolisticSkeletonPainter extends CustomPainter {
  _HolisticSkeletonPainter({
    required this.landmarks,
    required this.mirrorX,
  });

  final List<double> landmarks;
  final bool mirrorX;

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.length <
        TfliteAslService.landmarkCount * TfliteAslService.coordinateCount) {
      return;
    }

    final facePaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    final leftPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rightPaint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final posePaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotLeft = Paint()..color = const Color(0xFF90CAF9);
    final dotRight = Paint()..color = const Color(0xFFA5D6A7);

    for (var i = 0; i < 468; i += 9) {
      final p = _point(HolisticSkeletonOverlay._faceBase, i, size);
      if (p != null) {
        canvas.drawCircle(p, 1.2, facePaint);
      }
    }

    _drawConnections(
      canvas,
      size,
      HolisticSkeletonOverlay._leftBase,
      HolisticSkeletonOverlay._handConnections,
      leftPaint,
    );
    _drawConnections(
      canvas,
      size,
      HolisticSkeletonOverlay._rightBase,
      HolisticSkeletonOverlay._handConnections,
      rightPaint,
    );
    _drawConnections(
      canvas,
      size,
      HolisticSkeletonOverlay._poseBase,
      HolisticSkeletonOverlay._poseConnections,
      posePaint,
    );

    for (var i = 0; i < 21; i++) {
      final pl = _point(HolisticSkeletonOverlay._leftBase, i, size);
      if (pl != null) canvas.drawCircle(pl, 3, dotLeft);
      final pr = _point(HolisticSkeletonOverlay._rightBase, i, size);
      if (pr != null) canvas.drawCircle(pr, 3, dotRight);
    }
    for (var i = 0; i < 33; i++) {
      final pp = _point(HolisticSkeletonOverlay._poseBase, i, size);
      if (pp != null) {
        canvas.drawCircle(pp, 3, Paint()..color = const Color(0xFFFFCC80));
      }
    }
  }

  void _drawConnections(
    Canvas canvas,
    Size size,
    int base,
    List<List<int>> connections,
    Paint paint,
  ) {
    for (final edge in connections) {
      final a = _point(base, edge[0], size);
      final b = _point(base, edge[1], size);
      if (a != null && b != null) {
        canvas.drawLine(a, b, paint);
      }
    }
  }

  Offset? _point(int baseBytes, int landmarkIndex, Size size) {
    final o = baseBytes + landmarkIndex * 3;
    if (o + 2 >= landmarks.length) return null;
    var x = landmarks[o];
    var y = landmarks[o + 1];
    if (x.isNaN || y.isNaN) return null;
    x = x.clamp(0.0, 1.0);
    y = y.clamp(0.0, 1.0);
    if (mirrorX) {
      x = 1.0 - x;
    }
    return Offset(x * size.width, y * size.height);
  }

  @override
  bool shouldRepaint(covariant _HolisticSkeletonPainter oldDelegate) {
    if (oldDelegate.mirrorX != mirrorX) return true;
    if (oldDelegate.landmarks.length != landmarks.length) return true;
    const sample = 32;
    final n = math.min(landmarks.length, oldDelegate.landmarks.length);
    for (var i = 0; i < n; i += sample) {
      if (landmarks[i] != oldDelegate.landmarks[i]) return true;
    }
    return false;
  }
}
