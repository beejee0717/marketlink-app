import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/customer/home.dart';
import 'package:marketlinkapp/customer/product.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marketlinkapp/debugging.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  final String userId;

  const SearchResultsPage({
    super.key, 
    required this.query, 
    required this.userId,
  });

  @override
  SearchResultsPageState createState() => SearchResultsPageState();
}

class SearchResultsPageState extends State<SearchResultsPage> {

  @override
  void initState() {
    super.initState();
    }

Future<List<DocumentSnapshot>> searchWithAI(String query) async {
  try {
    final aiResults = await searchQuery(widget.query);

    // Extract document references
    final docRefs = aiResults.map((result) {
      final metadata = result['metadata'];
      final docId = metadata['id'];
      final type = metadata['type'];
      return FirebaseFirestore.instance
          .collection(type == 'product' ? 'products' : 'services')
          .doc(docId);
    }).toList();

    // Fetch all documents in parallel
    final docSnaps = await Future.wait(docRefs.map((docRef) => docRef.get()));

    // Filter only existing documents
    return docSnaps.where((docSnap) => docSnap.exists).toList();
  } catch (e) {
    debugPrint("Error in AI search: $e");
    return [];
  }
}

Future<List<dynamic>> searchQuery(String query) async {
  final url = Uri.parse("https://marketlink-app-production.up.railway.app/search");
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'query': query}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load search results");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: FutureBuilder<List<DocumentSnapshot>>(
            future: searchWithAI(widget.query),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: SpinKitFadingCircle(
                      size: 80,
                      color: AppColors.purple,
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

// ✅ Filter out products with no productName (hide them completely)
final filteredProducts = products.where((product) {
  final data = product.data() as Map<String, dynamic>;
  final name = data['productName'];
  return name != null && name.toString().trim().isNotEmpty;
}).toList();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
               final data = product.data() as Map<String, dynamic>;

final productName = data['productName'] ?? "Unnamed";
final price = "₱${(data['price'] as num?)?.toStringAsFixed(2) ?? 'N/A'}";
final imageUrl = data['imageUrl'];

          
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[300],
                              ),
                      ),
                      GestureDetector(
                        onTap: () {
                          storeProductClick(widget.userId, product.id);
                          navPush(context, CustomerProduct(productId: product.id));
                          debugging(product.id);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            storeProductClick(widget.userId, product.id);
                            navPush(
                                context, CustomerProduct(productId: product.id));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                textLabel: productName,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                textColor: Colors.white,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              CustomText(
                                textLabel: price,
                                fontSize: 14,
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
