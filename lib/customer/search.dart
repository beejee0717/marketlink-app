import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/api/ai_recommendation/send_event.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/customer/components.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/theme/event_theme.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  final String userId;
  final bool type;

  const SearchResultsPage(
      {super.key,
      required this.query,
      required this.userId,
      required this.type});

  @override
  SearchResultsPageState createState() => SearchResultsPageState();
}

class SearchResultsPageState extends State<SearchResultsPage> {
  @override
  void initState() {
    super.initState();

    storeSearchHistory(widget.userId, widget.query);
  }

  Future<List<String>> searchAI(String query) async {
    String searchType = widget.type ? 'products' : 'services';
    debugging('Searching for $query in $searchType');
    try {
      final url = Uri.parse(
          "http://13.218.245.133:8000/search?query=$query&type=$searchType");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final results = decoded["results"] as List;

        // Return just the list of IDs
        return results.map((item) => item["id"].toString()).toList();
      } else {
        throw Exception("Failed to fetch: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error in AI search: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchFromFirestore(
      List<String> ids) async {
    if (ids.isEmpty) return [];

    final firestore = FirebaseFirestore.instance;
    final collection = widget.type ? 'products' : 'services';

    const batchSize = 10;

    final List<List<String>> batches = [];
    for (var i = 0; i < ids.length; i += batchSize) {
      batches.add(ids.sublist(
          i, i + batchSize > ids.length ? ids.length : i + batchSize));
    }

    final futures = batches.map((batchIds) async {
      final querySnapshot = await firestore
          .collection(collection)
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()..['id'] = doc.id)
          .toList();
    });

    final results = await Future.wait(futures);

    final items = results.expand((batch) => batch).toList();

    final Map<String, Map<String, dynamic>> itemMap = {
      for (var item in items) item['id']: item
    };

    return ids
        .where((id) => itemMap.containsKey(id))
        .map((id) => itemMap[id]!)
        .toList();
  }

  Future<List<Map<String, dynamic>>> searchAndFetch(String query) async {
    final ids = await searchAI(query);
    final items = await fetchFromFirestore(ids);
    return items;
  }

  String _generateRandomId(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<void> storeSearchHistory(String customerId, String query) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final docId = "${customerId}_${_generateRandomId(12)}";

      await firestore.collection('searchHistory').doc(docId).set({
        'customerId': customerId,
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint("Search saved with docId: $docId");
    } catch (e) {
      debugPrint("Failed to save search: $e");
    }

    await sendEvent(customerId, 'search', query: query);
  }

  @override
  Widget build(BuildContext context) {
    late AppEvent currentEvent = getCurrentEvent();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage(currentEvent)),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: FutureBuilder<List<dynamic>>(
              future: searchAndFetch(widget.query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
                          SpinKitFadingCircle(
                            size: 80,
                            color: AppColors.primary,
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          CustomText(
                            textLabel: 'Please Wait',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            textColor: AppColors.primary,
                          )
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: CustomText(
                        textLabel: "Error displaying products.",
                        fontSize: 16,
                        textColor: Colors.red,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: CustomText(
                        textLabel: "No products available.",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                    ),
                  );
                }

                final products = snapshot.data!;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];

                    final itemId = item['id'];
                    final itemName =
                        item['productName'] ?? item['serviceName'] ?? 'Unnamed';
                    final imageUrl = item['imageUrl'];

                    final priceDouble =
                        (item['price'] as num?)?.toDouble() ?? 0.0;
                    final promo = item['promo'] is Map<String, dynamic>
                        ? item['promo']
                        : null;

                    final hasPromo = promo != null && promo['enabled'] == true;
                    final promoType = promo?['type'];
                    final promoValue = promo?['value'] ?? 0;

                    double discountedPrice = priceDouble;

                    if (hasPromo) {
                      if (promoType == 'percentage') {
                        discountedPrice =
                            priceDouble * (1 - (promoValue / 100));
                      } else if (promoType == 'fixed') {
                        discountedPrice =
                            (priceDouble - promoValue).clamp(0, priceDouble);
                      }
                    }

                    final priceText = '₱${priceDouble.toStringAsFixed(2)}';
                    final discountedText =
                        '₱${discountedPrice.toStringAsFixed(2)}';
                    final promoLabel = promoType == 'percentage'
                        ? '$promoValue% OFF'
                        : "₱${(promoValue as num).toStringAsFixed(2)} OFF";

                    return itemDisplay(
                      context,
                      imageUrl,
                      widget.userId,
                      itemId,
                      itemName,
                      priceText,
                      widget.type,
                      hasPromo,
                      discountedText,
                      promoLabel,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
