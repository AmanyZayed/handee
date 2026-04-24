import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// 🔥 جديد
import 'dart:convert';
import 'package:flutter/services.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  Interpreter? interpreter;

  String prediction = "Waiting...";
  bool isProcessing = false;

  // 🔥 mapping
  Map<int, String> indexToWord = {};

  @override
  void initState() {
    super.initState();
    initAll();
  }

  Future<void> initAll() async {
    await loadLabels();   // 🔥 مهم
    await loadModel();
    await initCamera();
  }

  // =========================
  // 🔥 Load JSON
  // =========================
  Future<void> loadLabels() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/model/sign_to_prediction_index_map.json');

      final Map<String, dynamic> data = json.decode(jsonString);

      indexToWord = {
        for (var entry in data.entries) entry.value: entry.key
      };

      print("LABELS LOADED ✅");
    } catch (e) {
      print("LABEL ERROR ❌ $e");
    }
  }

  // =========================
  // Camera (front)
  // =========================
  Future<void> initCamera() async {
    final cameras = await availableCameras();

    final camera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();

    if (!mounted) return;

    setState(() {});

    controller!.startImageStream((image) {
      runModel();
    });
  }

  // =========================
  // Load Model
  // =========================
  Future<void> loadModel() async {
    interpreter =
        await Interpreter.fromAsset('assets/model/model.tflite');

    print("MODEL LOADED ✅");
    print("INPUT: ${interpreter!.getInputTensor(0).shape}");
    print("OUTPUT: ${interpreter!.getOutputTensor(0).shape}");
  }

  // =========================
  // Run Model
  // =========================
  Future<void> runModel() async {
    if (interpreter == null) return;
    if (isProcessing) return;

    isProcessing = true;

    try {
      // 🔥 input ثابت (لسه مش real data)
      var input = List.generate(
        1,
        (_) => List.generate(
          543,
          (_) => List.filled(3, 0.0),
        ),
      );

      var output = List.generate(
        1,
        (_) => List.filled(250, 0.0),
      );

      interpreter!.run(input, output);

      // 🔥 أعلى probability
      int maxIndex = 0;
      double maxValue = output[0][0];

      for (int i = 1; i < 250; i++) {
        if (output[0][i] > maxValue) {
          maxValue = output[0][i];
          maxIndex = i;
        }
      }

      // 🔥 تحويل index → كلمة
      String word = indexToWord[maxIndex] ?? "Unknown";

      setState(() {
        prediction = "$word (${maxValue.toStringAsFixed(2)})";
      });

    } catch (e) {
      print("MODEL ERROR ❌ $e");
      setState(() {
        prediction = "Model Error ❌";
      });
    }

    await Future.delayed(const Duration(milliseconds: 300));
    isProcessing = false;
  }

  @override
  void dispose() {
    controller?.stopImageStream();
    controller?.dispose();
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(controller!),
          Positioned(
            top: 60,
            left: 20,
            child: Text(
              prediction,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}