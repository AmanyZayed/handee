import 'dart:collection';

/// Temporal smoothing from `app.py` (STABLE_WINDOW / STABLE_MIN_COUNT).
class YoloPredictionSmoother {
  YoloPredictionSmoother({
    this.windowSize = 8,
    this.minStableCount = 4,
  });

  final int windowSize;
  final int minStableCount;
  final Queue<String?> _history = Queue<String?>();

  void reset() {
    _history.clear();
  }

  void addRaw(String? label) {
    _history.add(label);
    while (_history.length > windowSize) {
      _history.removeFirst();
    }
  }

  String? stableLabel() {
    final labels = _history.whereType<String>().toList();
    if (labels.isEmpty) {
      return null;
    }

    final counts = <String, int>{};
    for (final label in labels) {
      counts[label] = (counts[label] ?? 0) + 1;
    }

    var bestLabel = labels.first;
    var bestCount = 0;
    counts.forEach((label, count) {
      if (count > bestCount) {
        bestLabel = label;
        bestCount = count;
      }
    });

    return bestCount >= minStableCount ? bestLabel : null;
  }
}
