import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/chat/chat.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/customer/category.dart';
import 'package:marketlinkapp/customer/product.dart';
import 'package:marketlinkapp/customer/profile.dart';
import 'package:marketlinkapp/customer/search.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final TextEditingController searchController = TextEditingController();
  String? selectedCategory;
  Timer? debounceTimer;

  Future<List<QueryDocumentSnapshot>> fetchProducts() async {
    Query query = FirebaseFirestore.instance
        .collection('products')
        .orderBy('dateCreated', descending: true);

    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String userId =
        Provider.of<UserProvider>(context, listen: false).user!.uid;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: CustomText(textLabel: 'Explore What You Need...', fontSize: 18),
        actions: [
          IconButton(
            icon: Icon(Icons.message, color: Colors.black),
            onPressed: () {
              navPush(
                  context,
                  Chat(
                    userId: userId,
                    backButton: true,
                  ));
            },
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.black),
            onPressed: () {
              navPush(context, const CustomerProfile());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.grey[200],
                ),
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search what you want...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        String query = searchController.text.trim();
                        if (query.isNotEmpty) {
                          navPush(
                            context,
                            SearchResultsPage(query: query, userId: userId),
                          );
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Search',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildCategoryItem(context, 'All', Icons.category),
                    buildCategoryItem(context, 'Home', Icons.home),
                    buildCategoryItem(context, 'Clothing', Icons.checkroom),
                    buildCategoryItem(context, 'Electronics', Icons.devices),
                    buildCategoryItem(context, 'Beauty', Icons.brush),
                    buildCategoryItem(context, 'Toys', Icons.toys),
                    buildCategoryItem(context, 'Sports', Icons.sports),
                    buildCategoryItem(context, 'Food', Icons.fastfood),
                    buildCategoryItem(context, 'Books', Icons.menu_book),
                    buildCategoryItem(
                        context, 'Groceries', Icons.local_grocery_store),
                    buildCategoryItem(context, 'Others', Icons.more_horiz),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<QueryDocumentSnapshot>>(
                future: fetchProducts(),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final productName = product['productName'] ?? "Unnamed";
                      final price =
                          "₱${product['price']?.toStringAsFixed(2) ?? 'N/A'}";
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
                              navPush(context,
                                  CustomerProduct(productId: product.id));
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
                                navPush(context,
                                    CustomerProduct(productId: product.id));
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
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCategoryItem(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        navPush(context, CustomerCategory(category: title));
      },
      child: Container(
        margin: EdgeInsets.only(right: 10),
        child: Column(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.green[100],
              child: Icon(icon, color: Colors.green, size: 30),
            ),
            const SizedBox(height: 8),
            CustomText(textLabel: title, fontSize: 14)
          ],
        ),
      ),
    );
  }
}

Future<void> storeProductClick(String userId, String productId) async {
  final productRef =
      FirebaseFirestore.instance.collection('products').doc(productId);
  final productSnapshot = await productRef.get();

  if (!productSnapshot.exists) {
    return;
  }

  final productData = productSnapshot.data()!;
  final String productName = productData['productName'];
  final String category = productData['category'] ?? "Uncategorized";
  final String description = productData['description'] ?? "";

  final docRef = FirebaseFirestore.instance
      .collection('customers')
      .doc(userId)
      .collection('productClicks')
      .doc(productId);

  await docRef.set({
    'timestamp': FieldValue.serverTimestamp(),
    'count': FieldValue.increment(1),
    'productName': productName,
    'category': category,
    'description': description,
  }, SetOptions(merge: true));
}

Future<void> fetchSearchHistory(String userId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('customers')
      .doc(userId)
      .collection('searchHistory')
      .orderBy('timestamp', descending: true)
      .get();

  if (querySnapshot.docs.isEmpty) {
    debugPrint("No search history found for user: $userId");
    return;
  }

  for (var doc in querySnapshot.docs) {
    final data = doc.data();
    debugging(
        "Search Query: ${data['query']}, Timestamp: ${data['timestamp']}");
  }
}
