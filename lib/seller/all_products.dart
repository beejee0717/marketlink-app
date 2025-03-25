import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/seller/product_details.dart';
import 'package:provider/provider.dart';

import '../components/auto_size_text.dart';
import '../components/navigator.dart';
import '../components/snackbar.dart';
import '../provider/user_provider.dart';
import 'add_product.dart';

class SellerAllProducts extends StatefulWidget {
  const SellerAllProducts({super.key});

  @override
  State<SellerAllProducts> createState() => _SellerAllProductsState();
}

class _SellerAllProductsState extends State<SellerAllProducts> {
  final TextEditingController searchController = TextEditingController();
  late Stream<QuerySnapshot> productsStream;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }
  Stream<bool> getSellerApprovalStatus(String sellerId) {
    return FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['approved'] == true);
  }
  void fetchProducts() {
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    final sellerId = userInfo?.uid ?? "";

    String searchQuery = searchController.text.trim().toLowerCase();

    var query = FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId);

    if (searchQuery.isNotEmpty) {
      query = query.where('lowercaseName', isGreaterThanOrEqualTo: searchQuery);
      query = query.where('lowercaseName',
          isLessThanOrEqualTo: "$searchQuery\uf8ff");
    }

    productsStream = query.orderBy('dateCreated', descending: true).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            navPop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        title: const CustomText(
          textLabel: "All Products",
          fontSize: 22,
          fontWeight: FontWeight.bold,
          textColor: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  fetchProducts();
                });
              },
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Search products...",
                hintStyle: TextStyle(color: Colors.white),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 1)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellow, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: productsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 50),
                        child: SpinKitDoubleBounce(
                          size: 100,
                          color: Colors.yellow,
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: CustomText(
                        textLabel: "Error fetching products.",
                        fontSize: 16,
                        textColor: Colors.red,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: CustomText(
                        textLabel: "No products found.",
                        fontSize: 16,
                        textColor: Colors.white,
                      ),
                    );
                  }

                  final products = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final productDoc = products[index];
                      final product = productDoc.data() as Map<String, dynamic>;
                      final productId = productDoc.id;

                      return FadeInLeft(
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: product['imageUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product['imageUrl'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                            title: CustomText(
                              textLabel:
                                  product['productName'] ?? "Unnamed Product",
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CustomText(
                                      textLabel: "Category: ",
                                      fontSize: 14,
                                      textColor: Colors.black87,
                                    ),
                                    CustomText(
                                      textLabel:
                                          product['category'] ?? 'Uncategorized',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    CustomText(
                                      textLabel: "Price: ",
                                      fontSize: 14,
                                      textColor: Colors.black87,
                                    ),
                                    CustomText(
                                      textLabel:
                                          "₱${product['price']?.toStringAsFixed(0) ?? 'N/A'}",
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      textColor: Colors.orange,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    CustomText(
                                      textLabel: "Stock: ",
                                      fontSize: 14,
                                      textColor: Colors.black87,
                                    ),
                                    CustomText(
                                      textLabel: "${product['stock'] ?? 0}",
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.yellow.shade800,
                            ),
                            onTap: () {
                              navPush(context,
                                  SellerProductDetails(productId: productId));
                            },
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
  floatingActionButton: StreamBuilder<bool>(
  stream: getSellerApprovalStatus(
    Provider.of<UserProvider>(context, listen: false).user!.uid,
  ),
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox.shrink(); 
    }

    bool isApproved = snapshot.data!;

    return FloatingActionButton(
      onPressed: () {
        if (isApproved) {
          navPush(context, SellerAddProduct());
        } else {
          errorSnackbar(context,
              'This account is not approved yet. Please wait for admin approval before being able to sell items.');
        }
      },
      backgroundColor: Colors.purple.shade600,
      child: const Icon(Icons.add, color: Colors.white),
    );
  },
),


    );
  }
}
