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
    _labels = labelData.trim().split('\n');
  }

  // Returns top prediction + confidence
  Map<String, dynamic> classify(img.Image image) {
    // Resize to 224x224
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Normalize to [-1, 1] (MobileNetV2 preprocessing)
    var input = List.generate(1, (_) =>
      List.generate(inputSize, (y) =>
        List.generate(inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r / 127.5) - 1.0,
            (pixel.g / 127.5) - 1.0,
            (pixel.b / 127.5) - 1.0,
          ];
        })
      )
    );

    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    _interpreter.run(input, output);

    final scores = output[0] as List<double>;
    final maxIdx = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));

    return {
      'category': _labels[maxIdx],
      'confidence': scores[maxIdx],
      'all_scores': Map.fromIterables(_labels, scores),
    };
  }
}
