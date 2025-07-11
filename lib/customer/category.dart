import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/customer/components.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:provider/provider.dart';


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
      final String userId =
        Provider.of<UserProvider>(context, listen: false).user!.uid;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: CustomText(
          textLabel: widget.category,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
          searchContainer(context, searchController, userId),
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
                        color: AppColors.primary,
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
                      final product = products[index];
                      final productId = product.id;
                      final productName = product['productName'] ?? "Unnamed";
                         final data = product.data() as Map<String, dynamic>;

                  final priceDouble = data['price']?.toDouble() ?? 0.0;
final promo = data['promo'] is Map<String, dynamic> ? data['promo'] : null;

final hasPromo = promo != null && promo['enabled'] == true;
final promoType = promo?['type'];
final promoValue = promo?['value'] ?? 0;

double discountedPrice = priceDouble;

if (hasPromo) {
  if (promoType == 'percentage') {
    discountedPrice = priceDouble * (1 - (promoValue / 100));
  } else if (promoType == 'fixed') {
    discountedPrice = (priceDouble - promoValue).clamp(0, priceDouble);
  }
}

final priceText = '₱${priceDouble.toStringAsFixed(2)}';
final discountedText = '₱${discountedPrice.toStringAsFixed(2)}';

final promoLabel = promoType == 'percentage'
    ? '$promoValue% OFF'
    : '₱$promoValue OFF';
                      final imageUrl = product['imageUrl'];

                   return itemDisplay(
  context,
  imageUrl,
  userId,
  productId,
  productName,
  priceText,
  true,
  hasPromo,
  discountedText,
  promoLabel,
);   });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
