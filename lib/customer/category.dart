import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';

import '../components/navigator.dart';
import 'product.dart';

class CustomerCategory extends StatefulWidget {
  final String category;
  const CustomerCategory({super.key, required this.category});

  @override
  State<CustomerCategory> createState() => _CustomerCategoryState();
}

class _CustomerCategoryState extends State<CustomerCategory> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    searchController.addListener(onSearchChanged);
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged() {
    if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();

    debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: CustomText(
          textLabel: widget.category,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search what you want...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where(
                      'category',
                      isEqualTo: widget.category == 'Market Link'
                          ? null
                          : widget.category,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: SpinKitFadingCircle(
                        size: 60,
                        color: Colors.green,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: CustomText(
                        textLabel: 'Error fetching products.',
                        fontSize: 16,
                        textColor: Colors.red,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: CustomText(
                        textLabel: 'No products found.',
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                    );
                  }

                  final products = snapshot.data!.docs.where((doc) {
                    final productName =
                        doc['productName']?.toString().toLowerCase() ?? '';
                    return productName.contains(searchQuery);
                  }).toList();

                  if (products.isEmpty) {
                    return const Center(
                      child: CustomText(
                        textLabel: 'No matching products found.',
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2 / 3,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final productSnapshot = products[index];
                      final product =
                          productSnapshot.data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () => navPush(
                          context,
                          CustomerProduct(productId: productSnapshot.id),
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10)),
                                  child: Image.network(
                                    product['imageUrl'] ?? '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      textLabel: product['productName'] ??
                                          'Unnamed Product',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    CustomText(
                                      textLabel:
                                          '₱${product['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                      fontSize: 14,
                                      textColor: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
