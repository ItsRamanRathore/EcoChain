import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassifierService {
  late Interpreter _interpreter;
  late List<String> _labels;
  static const int inputSize = 224;

  Future<void> init() async {
    _interpreter = await Interpreter.fromAsset('assets/ml/material_classifier.tflite');
    final labelData = await rootBundle.loadString('assets/ml/labels.txt');
    _labels = labelData.trim().split('\n').map((e) => e.trim()).toList();
  }

  // Returns top prediction + confidence
  Map<String, dynamic> classify(img.Image image) {
    // 1. Resize image to 224x224 (required by model)
    final resizedImage = img.copyResize(image, width: inputSize, height: inputSize);

    // 2. Convert image to a 4D tensor: [1, 224, 224, 3] of float32
    var input = List.generate(
      1,
      (i) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resizedImage.getPixelSafe(x, y);
            // Normalize pixel values to [0, 1] as expected by MobileNet float32 models
            return [
              pixel.r.toDouble() / 255.0,
              pixel.g.toDouble() / 255.0,
              pixel.b.toDouble() / 255.0,
            ];
          },
        ),
      ),
    );

    // 3. Prepare output tensor: [1, 8]
    var output = List.generate(1, (i) => List.filled(_labels.length, 0.0));

    // 4. Run inference safely
    try {
      _interpreter.run(input, output);
    } catch (e) {
      print("Error running TFLite inference: $e");
      return {
        'category': 'Unknown',
        'confidence': 0.0,
        'all_scores': {},
      };
    }

    // 5. Parse output to find the highest confidence
    final probabilities = output[0];
    int maxIdx = 0;
    double maxConfidence = 0.0;
    Map<String, double> allScores = {};

    for (int i = 0; i < probabilities.length; i++) {
      allScores[_labels[i]] = probabilities[i];
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        maxIdx = i;
      }
    }

    return {
      'category': _labels[maxIdx],
      'confidence': maxConfidence,
      'all_scores': allScores,
    };
  }
}
