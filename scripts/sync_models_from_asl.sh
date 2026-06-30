#!/usr/bin/env bash
# Copy ONNX + config from ASL YOLO mobile_bundle into this app.
set -euo pipefail

ASL_ROOT="${ASL_ROOT:-/c/Users/Asus/Desktop/ASL YOLO}"
BUNDLE="$ASL_ROOT/mobile_bundle"
HANDEE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -d "$BUNDLE/models" ]]; then
  echo "Missing $BUNDLE/models — set ASL_ROOT to your ASL YOLO folder."
  exit 1
fi

mkdir -p "$HANDEE_ROOT/android/app/src/main/assets/yolo"
mkdir -p "$HANDEE_ROOT/android/app/src/main/assets/mediapipe"

cp "$BUNDLE/exports/full_combined_best.onnx" "$HANDEE_ROOT/android/app/src/main/assets/yolo/"
cp "$BUNDLE/exports/letters_digits_best.onnx" "$HANDEE_ROOT/android/app/src/main/assets/yolo/"
cp "$BUNDLE/config.json" "$HANDEE_ROOT/android/app/src/main/assets/asl_yolo_config.json"
cp "$BUNDLE/config.json" "$HANDEE_ROOT/assets/models/asl_yolo_config.json"

HOLISTIC_SRC="$HANDEE_ROOT/android/app/src/main/assets/mediapipe/holistic_landmarker.task"
if [[ ! -f "$HOLISTIC_SRC" ]]; then
  echo "WARN: Add holistic_landmarker.task to android/app/src/main/assets/mediapipe/"
fi

echo "Synced YOLO ONNX models to $HANDEE_ROOT"
