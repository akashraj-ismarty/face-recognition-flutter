import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';

import 'package:Face_Recognition/HomeScreen.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'Recognition.dart';
import '../main.dart';

class Recognizer {
  late Interpreter interpreter;
  late InterpreterOptions _interpreterOptions;

  late List<int> _inputShape;
  late List<int> _outputShape;

  late img.Image _inputImage;

  Recognizer({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/mobile_face_net.tflite', options: _interpreterOptions);
      print('Interpreter Created Successfully');

      _inputShape = interpreter.getInputTensor(0).shape;
      _outputShape = interpreter.getOutputTensor(0).shape;
      print('Input Shape: $_inputShape');
      print('Output Shape: $_outputShape');
    } catch (e) {
      print('Unable to create interpreter, Caught Exception: ${e.toString()}');
    }
  }

  img.Image _preProcess(img.Image image) {
    int cropSize = min(image.height, image.width);
    var resized = img.copyResizeCropSquare(image,  cropSize);
    resized = img.copyResize(resized, width: _inputShape[1], height: _inputShape[2]);
    return resized;
  }

  Recognition recognize(img.Image image, Rect location) {
    final pres = DateTime.now().millisecondsSinceEpoch;
    _inputImage = _preProcess(image);
    final pre = DateTime.now().millisecondsSinceEpoch - pres;
    print('Time to load image: $pre ms');

    // Normalize the image data to the range [0, 1]
    // final normalizedImage = _inputImage.data.map((pixel) => pixel / 255.0).toList();
    // // Convert normalized image data to Float32List
    // final input = Float32List.fromList(normalizedImage);
    //
    final runs = DateTime.now().millisecondsSinceEpoch;
    // var output = List.filled(_outputShape.reduce((a, b) => a * b), 0.0).reshape(_outputShape);

    final imageMatrix = List.generate(
      _inputImage.height,
          (y) => List.generate(
            _inputImage.width,
            (x) {
          final pixel = _inputImage.getPixel(x, y);
          var r = img.getRed(pixel)/255.0;
          var b = img.getBlue(pixel)/255.0;
          var g = img.getGreen(pixel)/255.0;
          return [r, g, b];
        },
      ),
    );

    // Set tensor input [1, 224, 224, 3]
    final input = [imageMatrix];
    // Set tensor output [1, 1001]
    final output = List.filled(_outputShape.reduce((a, b) => a * b), 0.0).reshape(_outputShape);
    print("Inputs: $input");
    print("Outputs: $output");
    interpreter.run(input, output);
    final run = DateTime.now().millisecondsSinceEpoch - runs;
    print('Time to run inference: $run ms');

    List<List<double>> outList = output.cast<List<double>>();
    // Post-processing the output
    Pair pair = findNearest(outList);
    return Recognition(pair.name, location, outList, pair.distance);
  }

  // Pair findNearest(List<double> emb) {
  //   Pair pair = Pair("Unknown", -5);
  //   for (var item in HomeScreen.registered.entries) {
  //     final String name = item.key;
  //     print("Find Nearresest ${item.runtimeType}");
  //     print("Find Nearresest ${item.value.runtimeType}");
  //     print("Find Nearresest ${item.value.embeddings.runtimeType}");
  //
  //     List<double> knownEmb = item.value.embeddings;
  //     print("Find Nearresest ${knownEmb.runtimeType}");
  //     print("Find Nearresest ${knownEmb}");
  //     double distance = 0;
  //     for (int i = 0; i < emb.length; i++) {
  //       print("Find tt Step $i");
  //       print("Find tt ${emb[i]}");
  //       print("Find tt ${knownEmb[i]}");
  //       double diff = emb[i] - knownEmb[i];
  //       distance += diff * diff;
  //     }
  //     distance = sqrt(distance);
  //     if (pair.distance == -5 || distance < pair.distance) {
  //       pair.distance = distance;
  //       pair.name = name;
  //     }
  //   }
  //   return pair;
  // }
  Pair findNearest(List<List<double>> data) {
    List<double> emb = data[0];
    Pair pair = Pair("Unknown", -5);
    for (var item in HomeScreen.registered.entries) {
      final String name = item.key;
      item.value.embeddings.forEach((e)=>print("Nearest ${e.runtimeType}"));

      List<List<double>> knownEmbs = item.value.embeddings as List<List<double>>;
      for (var knownEmb in knownEmbs) {
        double distance = 0;
        for (int i = 0; i < emb.length; i++) {
          double diff = emb[i] - (knownEmb[i] as double); // Cast to double here
          distance += diff * diff;
        }
        distance = sqrt(distance);
        if (pair.distance == -5 || distance < pair.distance) {
          pair.distance = distance;
          pair.name = name;
        }
      }}
    return pair;
  }

  void close() {
    interpreter.close();
  }
}

class Pair {
  String name;
  double distance;
  Pair(this.name, this.distance);
}
