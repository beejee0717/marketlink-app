import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:marketlinkapp/debugging.dart';

//event type: view, search, add_to_cart, wishlist, purchase

Future<void> sendEvent(
  String userId,
  String eventType, {
  String? productId,
  String? query,
}) async {
  final url = Uri.parse("http://13.217.97.212:8000/event");

  // Start with common fields
  final Map<String, dynamic> body = {
    "user_id": userId,
    "event_type": eventType,
  };

  // Add extra fields depending on event type
  if (eventType == "view" && productId != null) {
    body["product_id"] = productId;
  } else if (eventType == "search" && query != null) {
    body["query"] = query;
  }

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    debugging("✅ Event sent successfully [${response.statusCode}]: "
        "$eventType for user $userId, product: $productId, query: $query");
  } else {
    debugging("❌ Failed to send event [${response.statusCode}]: ${response.body}");
  }
}
