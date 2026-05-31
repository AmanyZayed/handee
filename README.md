# Handee ASL Mobile Integration

This Flutter app integrates a TensorFlow Lite ASL recognition model with a native Android MediaPipe pipeline. The reference preprocessing contract comes from [`run_local_repo_style.py`](https://github.com/moohamed-ashraf/LSTM-Words-model/blob/main/run_local_repo_style.py), and the app should stay compatible with that script.

## Repo-style inference contract

Every frame must match the Python repo exactly:

- detector: MediaPipe Holistic
- landmark order: `face -> left hand -> pose -> right hand`
- landmark counts: `468 + 21 + 33 + 21 = 543`
- coordinates per landmark: `x, y, z`
- frame tensor shape: `(543, 3)`
- missing landmarks: `NaN`, not zero
- dtype: `float32`
- sequence length: `30`
- sequence tensor shape: `(30, 543, 3)`
- confidence threshold: `0.70`

The repo-style runner predicts with:

```python
prediction_fn = interpreter.get_signature_runner("serving_default")
prediction = prediction_fn(inputs=sequence)
probabilities = prediction["outputs"][0]
predicted_sign = np.argmax(probabilities)
confidence = probabilities[predicted_sign]
```

The Python runner predicts on 30-frame windows. The mobile app uses a rolling window of the most recent frames to stay responsive in real time while keeping tensor structure compatible.

## Flutter + Android architecture

The app is split so Flutter handles UI and native Android handles the real-time vision work:

```text
Flutter UI
-> MethodChannel / EventChannel
-> Native Android (Kotlin)
-> CameraX ImageAnalysis
-> MediaPipe Holistic landmarks
-> 30-frame buffer
-> TensorFlow Lite inference
-> prediction stream back to Flutter
```

### Flutter side

- [lib/asl/asl_camera_screen.dart](/C:/Users/Asus/Desktop/Handee/handee/lib/asl/asl_camera_screen.dart)
  - clean camera screen UI (single prediction label)
  - start/stop controls
  - rolling 30-frame buffering
  - smoothed prediction display for motion signs
- [lib/asl/native_asl_bridge.dart](/C:/Users/Asus/Desktop/Handee/handee/lib/asl/native_asl_bridge.dart)
  - `MethodChannel` commands
  - `EventChannel` landmark stream
- [lib/asl/tflite_asl_service.dart](/C:/Users/Asus/Desktop/Handee/handee/lib/asl/tflite_asl_service.dart)
  - loads `model.tflite`
  - builds `(30, 543, 3)` inputs
  - preserves `NaN` padding
  - returns top predictions

### Native Android side

- [NativeCameraPreview.kt](/C:/Users/Asus/Desktop/Handee/handee/android/app/src/main/kotlin/com/example/handee/NativeCameraPreview.kt)
  - CameraX preview + `ImageAnalysis`
  - converts frames for MediaPipe
- [NativeAslState.kt](/C:/Users/Asus/Desktop/Handee/handee/android/app/src/main/kotlin/com/example/handee/NativeAslState.kt)
  - flattens landmarks in repo order
  - fills missing landmarks with `Double.NaN`
  - streams frame updates to Flutter
- [AslNativeEngine.kt](/C:/Users/Asus/Desktop/Handee/handee/android/app/src/main/kotlin/com/example/handee/AslNativeEngine.kt)
  - owns the Holistic landmarker
- [MainActivity.kt](/C:/Users/Asus/Desktop/Handee/handee/android/app/src/main/kotlin/com/example/handee/MainActivity.kt)
  - registers channels and the preview factory

## Export labels for Android

Android should not rebuild labels from CSV. Export the exact trained label order once and ship it as JSON.

Generate `assets/models/labels.json` from the existing sign-to-index map:

```powershell
cd C:\Users\Asus\Desktop\Handee\handee
py scripts\export_labels_json.py
```

That file can then be loaded from native Android assets to map output indices back to signs without relying on Pandas or `train.csv`.

## Run the app

```powershell
cd C:\Users\Asus\Desktop\Handee\handee
flutter pub get
flutter run
```

Open the ASL camera screen, grant camera permission, then tap `Start`. The app predicts continuously from a rolling sequence and keeps the latest stable prediction visible through short tracking dropouts.

## Runtime behavior (release target)

- UI stays minimal by design: camera preview + one prediction label + Start/Stop button.
- Prediction pipeline:
  - rolling sequence of landmark frames
  - NaN-preserving padding/trimming
  - confidence + temporal smoothing before accepting a stable label
  - short hold window so words do not flicker away during brief missed detections
- Native Android logging is reduced in frame-critical paths for better runtime behavior.

### Tuning prediction responsiveness

`lib/asl/asl_camera_screen.dart` defines three profiles:

- `fast`: quickest updates, lowest stability gate
- `balanced`: recommended default
- `stable`: strictest smoothing, least flicker

Switch by changing `_predictionProfile` in the screen file.

## Guardrails

Do not change these unless the training pipeline changes too:

- landmark order
- sequence length
- NaN handling
- label order
- input tensor shape
- `float32` dtype
- no visible skeleton overlay on product UI
