import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassifierService {
  late Interpreter _interpreter;
  late List<String> _labels;
  static const int inputSize = 640;

  Future<void> init() async {
    _interpreter = await Interpreter.fromAsset('assets/ml/material_classifier.tflite');
    final labelData = await rootBundle.loadString('assets/ml/labels.txt');
    _labels = labelData.trim().split('\n').map((e) => e.trim()).toList();
  }

  // Returns top prediction + confidence
  Map<String, dynamic> classify(img.Image image) {
    // 1. Resize image to 640x640 (required by model)
    final resizedImage = img.copyResize(image, width: inputSize, height: inputSize);

    // 2. Convert image to a 4D tensor: [1, 3, 640, 640] of float32 (NCHW format)
    var input = List.generate(
      1,
      (batch) => List.generate(
        3, // channels (RGB)
        (channel) => List.generate(
          inputSize, // height (y)
          (y) => List.generate(
            inputSize, // width (x)
            (x) {
              final pixel = resizedImage.getPixelSafe(x, y);
              // Normalize pixel values to [0, 1]
              if (channel == 0) return pixel.r.toDouble() / 255.0; // Red
              if (channel == 1) return pixel.g.toDouble() / 255.0; // Green
              return pixel.b.toDouble() / 255.0; // Blue
            },
          ),
        ),
      ),
    );

    // 3. Prepare output tensor: [1, 4 + _labels.length, 8400]
    final int numAttributes = 4 + _labels.length;
    var output = List.generate(1, (i) => List.generate(numAttributes, (j) => List.filled(8400, 0.0)));

    // 4. Run inference safely
    try {
      _interpreter.run(input, output);
    } catch (e) {
      print("Error running TFLite inference: \$e");
      return {
        'category': 'Unknown',
        'confidence': 0.0,
        'all_scores': {},
      };
    }

    // 5. Parse output to find the highest confidence
    double maxConfidence = 0.0;
    int maxIdx = 0;
    Map<String, double> allScores = {};

    // Iterate over all 8400 anchor boxes
    for (int boxIdx = 0; boxIdx < 8400; boxIdx++) {
      // Find highest class confidence for this box (classes start at index 4)
      for (int c = 0; c < _labels.length; c++) {
        double confidence = output[0][4 + c][boxIdx];
        if (confidence > maxConfidence) {
          maxConfidence = confidence;
          maxIdx = c;
        }
      }
    }
    
    // Store scores for the highest confidence box (optional)
    if (maxConfidence > 0) {
      for (int c = 0; c < _labels.length; c++) {
        allScores[_labels[c]] = output[0][4 + c][maxIdx];
      }
    }

    return {
      'category': maxConfidence > 0.1 ? _labels[maxIdx] : 'Unknown', // Small threshold
      'confidence': maxConfidence,
      'all_scores': allScores,
    };
  }
}
