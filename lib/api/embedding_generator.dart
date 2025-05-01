import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmbeddingGenerator {
  static final EmbeddingGenerator _instance = EmbeddingGenerator._internal();

  late Interpreter _interpreter;
  late List<int> _inputBuffer;
  late List<List<double>> _outputBuffer;

  factory EmbeddingGenerator() {
    return _instance;
  }

  EmbeddingGenerator._internal();

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/all-MiniLM-L6-v2.tflite');
    debugPrint("✅ Model loaded!");
  }

  List<int> _simpleTokenizer(String text) { 
  List<int> charCodes = text.codeUnits;

  int desiredLength = 128;
  if (charCodes.length < desiredLength) {
    charCodes += List.filled(desiredLength - charCodes.length, 0);
  } else if (charCodes.length > desiredLength) {
    charCodes = charCodes.sublist(0, desiredLength);
  }

  return charCodes;
}
  Future<List<double>> generateEmbedding(String text) async {
  _inputBuffer = _simpleTokenizer(text);
  _outputBuffer = List.generate(1, (_) => List.filled(384, 0.0));

  _interpreter.run([_inputBuffer], _outputBuffer);

  return _outputBuffer[0];
}
}
