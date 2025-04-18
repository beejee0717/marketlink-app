import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/customer/home.dart';
import 'package:marketlinkapp/customer/product.dart';

class SearchResultsPage extends StatelessWidget {
  final String query;
  final String userId;

  const SearchResultsPage(
      {super.key, required this.query, required this.userId});

  Future<List<QueryDocumentSnapshot>> searchProducts(
      String query, String userId) async {
    query = query.trim().toLowerCase();

    if (query.isNotEmpty) {
      final historyRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(userId)
          .collection('searchHistory');

      final recentSearches = await historyRef
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (recentSearches.docs.isEmpty ||
          recentSearches.docs.first['query'] != query) {
        await historyRef.add({
          'query': query,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('searchKeywords', arrayContainsAny: _generateSubstrings(query))
        .get();

    return querySnapshot.docs;
  }

  List<String> _generateSubstrings(String query) {
    List<String> substrings = [];
    for (int i = 1; i <= query.length; i++) {
      substrings.add(query.substring(0, i));
    }
    return substrings;
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
          child: FutureBuilder<List<QueryDocumentSnapshot>>(
            future: searchProducts(query, userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: SpinKitFadingCircle(
                      size: 80,
                      color: Colors.green,
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
                  final product = products[index];
                  final productName = product['productName'] ?? "Unnamed";
                  final price = "₱${product['price']?.toStringAsFixed(2) ?? 'N/A'}";
                  final imageUrl = product['imageUrl'];
          
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
                          storeProductClick(userId, product.id);
                          navPush(context, CustomerProduct(productId: product.id));
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
                            storeProductClick(userId, product.id);
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
