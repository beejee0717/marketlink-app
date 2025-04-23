// import 'package:marketlinkapp/debugging.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';

// class EmbeddingModel {
//   late Interpreter interpreter;

  

//   Future<void> loadModel() async {
//     interpreter = await Interpreter.fromAsset('all-MiniLM-L6-v2.tflite');
//     debugging('✅ Model loaded successfully');
//   }

//   List<double> getEmbedding(List<List<double>> inputTokens) {
//     var input = [inputTokens]; // Shape: [1, seq_len, embedding_size]
//     var output = List.filled(384, 0.0).reshape([1, 384]);
//     interpreter.run(input, output);
//     return output[0];
//   }
// }
