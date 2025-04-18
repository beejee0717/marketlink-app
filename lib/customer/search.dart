import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> aiSearch(String query) async {
  final response = await http.post(
    Uri.parse('http://YOUR_LOCAL_IP:5000/search'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'query': query}),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => e as Map<String, dynamic>).toList();
  } else {
    throw Exception('Failed to search');
  }
}
