import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> searchWithVector(List<double> vector) async {
  final url = Uri.parse("https://your-api-url.com/search_by_vector");
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"vector": vector}),
  );

  if (response.statusCode == 200) {
    final results = jsonDecode(response.body);
    print("Results: $results");
  } else {
    print("Search failed: ${response.statusCode}");
  }
}
