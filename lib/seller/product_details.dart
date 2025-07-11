import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:marketlinkapp/seller/edit_product.dart';
import 'package:marketlinkapp/seller/seller.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:provider/provider.dart';

import '../components/auto_size_text.dart';
import '../components/navigator.dart';
import '../components/snackbar.dart';

class SellerProductDetails extends StatelessWidget {
  final String productId;

  const SellerProductDetails({super.key, required this.productId});

  Future<Map<String, dynamic>> fetchProductDetails(String productId) async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();

    if (doc.exists) {
      return doc.data()!;
    } else {
      throw Exception('Product not found');
    }
  }

  Future<void> deleteProduct(BuildContext context, String productId) async {
    final userId = Provider.of<UserProvider>(context, listen: false).user!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();
      if (!context.mounted) return;
      successSnackbar(context, 'Product deleted successfully.');
      navPushRemove(context, Seller(userId: userId));
    } catch (e) {
      errorSnackbar(context, 'Failed to delete product.');
    }
  }

  @override
  Widget build(BuildContext context) {
  late AppEvent currentEvent = getCurrentEvent();

    return Scaffold(
       appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            navPop(context);
          },
          icon:  Icon(
            Icons.arrow_back,
            color: currentEvent == AppEvent.none ? Colors.white :headerTitleColor(currentEvent),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => customDialog(context, 'Delete Product',
                'Are you sure you want to delete this product?', () {
              deleteProduct(context, productId);
            }),
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:  CustomText(
          textLabel: "Product Details",
          fontSize: 22,
          fontWeight: FontWeight.bold,
          textColor:currentEvent == AppEvent.none ? Colors.white :headerTitleColor(currentEvent),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: currentEvent == AppEvent.none ? AssetImage(wallpaper(currentEvent)): AssetImage(backgroundImage(currentEvent)),fit: BoxFit.cover)
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: fetchProductDetails(productId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return const Center(
                child: CustomText(
                  textLabel: "Error fetching product details.",
                  fontSize: 16,
                  textColor: Colors.red,
                ),
              );
            } else if (!snapshot.hasData) {
              return  Center(
                child: CustomText(
                  textLabel: "Product not found.",
                  fontSize: 16,
                  textColor: currentEvent == AppEvent.none ?Colors.grey:Colors.black,
                ),
              );
            }
        
            final product = snapshot.data!;
        
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: product['imageUrl'] != null
                            ? Image.network(
                                product['imageUrl'],
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                              )
                            :  Icon(
                                Icons.image,
                                size: 200,
                                color: currentEvent == AppEvent.none ?Colors.grey:Colors.black,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
        
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          navPush(
                              context, SellerEditProduct(productId: productId));
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:  CustomText(
                          textLabel: "Edit Product",
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          textColor: AppColors.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
        
                    CustomText(
                      textLabel: product['productName'] ?? "Unnamed Product",
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      textColor: AppColors.textColor,
                    ),
                     CustomText(
                      textLabel: productId,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      textColor: AppColors.textColor,
                    ),
                     Divider(height: 30, thickness: 1.5, color: currentEvent == AppEvent.none ?Colors.grey:Colors.black),
        
                    Row(
                      children: [
                         CustomText(
                          textLabel: "Category: ",
                          fontSize: 16,
                          textColor: currentEvent == AppEvent.none ?Colors.grey:Colors.black,
                        ),
                        CustomText(
                          textLabel: product['category'] ?? "Uncategorized",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          textColor: AppColors.textColor,
                        ),
                      ],
                    ),
                     SizedBox(height: 10),
                    Row(
                      children: [
                         CustomText(
                          textLabel: "Price: ",
                          fontSize: 16,
                          textColor: currentEvent == AppEvent.none ?Colors.grey:Colors.black,
                        ),
                        CustomText(
                          textLabel:
                              "₱${product['price']?.toStringAsFixed(2) ?? 'N/A'}",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          textColor: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (product['promo'] != null && product['promo']['enabled'] == true) ...[
  const SizedBox(height: 10),
  Row(
    children: [
      CustomText(
        textLabel: "Promo: ",
        fontSize: 16,
        textColor: currentEvent == AppEvent.none ? Colors.grey : Colors.black,
      ),
      CustomText(
        textLabel: product['promo']['type'] == 'percentage'
            ? "${product['promo']['value']}% OFF per item"
            : "₱${product['promo']['value']} OFF per item",
        fontSize: 16,
        fontWeight: FontWeight.bold,
        textColor: Colors.green.shade700,
      ),
    ],
  ),
],
const SizedBox(height: 10,),
                    Row(
                      children: [
                         CustomText(
                          textLabel: "Stock: ",
                          fontSize: 16,
                          textColor: currentEvent == AppEvent.none ?Colors.grey:Colors.black,
                        ),
                        CustomText(
                          textLabel: "${product['stock'] ?? 'N/A'}",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          textColor: AppColors.textColor,
                        ),
                      ],
                    ),
                     Divider(height: 30, thickness: 1.5, color: currentEvent == AppEvent.none ?Colors.grey:Colors.black),
        
                     CustomText(
                      textLabel: "Description",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      textColor: AppColors.textColor,
                    ),
                    const SizedBox(height: 5),
                    Card(
                      color: Colors.white.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomText(
                          textLabel: product['description'] ??
                              "No description available.",
                          fontSize: 16,
                          textColor: AppColors.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
        
                    Row(
                      children: [
                        CustomText(
                          textLabel:
                              "Materials Used: ",
                          fontSize: 16,
                          textColor: currentEvent == AppEvent.none ?Colors.grey:Colors.black,
                        ),   CustomText(
                      textLabel:
                          "${product['materials'] ?? 'Not specified'}",
                      fontSize: 16,
                      textColor:AppColors.textColor,
                    ),
                      ],
                    ),
                     Divider(height: 30, thickness: 1.5, color: currentEvent == AppEvent.none ?Colors.grey:Colors.black),
        
                    Row(
                      children: [
                        CustomText(
                          textLabel:
                              "Pickup Location: ",
                          fontSize: 16,
                          textColor: currentEvent == AppEvent.none ?Colors.grey:Colors.black,
                        ),
                          CustomText(
                      textLabel:
                          "${product['pickupLocation'] ?? 'Not specified'}",
                      fontSize: 16,
                      textColor: AppColors.textColor,
                    ),
                      ],
                    ),
                    Divider(height: 30, thickness: 1.5, color: currentEvent == AppEvent.none ?Colors.grey:Colors.black),
        
                     CustomText(
                      textLabel: "Customer Reviews",
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      textColor: AppColors.textColor,
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .doc(productId)
                          .collection('reviews')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
        
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return CustomText(
                            textLabel: "No reviews yet.",
                            fontSize: 16,
                            textColor: currentEvent == AppEvent.none ?Colors.grey:Colors.black,
                          );
                        }
        
                        final reviews = snapshot.data!.docs;
        
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            final userId = review.id;
                            final comment =
                                review['comment'] ?? "No comment provided.";
                            final stars = review['stars'] ?? 0;
        
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('customers')
                                  .doc(userId)
                                  .get(),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox();
                                }
        
                                if (!userSnapshot.hasData ||
                                    !userSnapshot.data!.exists) {
                                  return CustomText(
                                    textLabel: "Unknown user left a review.",
                                    fontSize: 16,
                                    textColor: currentEvent == AppEvent.none ?Colors.grey:Colors.black,
                                  );
                                }
        
                                final user = userSnapshot.data!;
                                final firstName = user['firstName'];
                                final lastName = user['lastName'];
                                final userData = user.data() as Map<String,
                                    dynamic>?; // Cast to Map<String, dynamic> or null
                                final profilePicture = (userData != null &&
                                        userData.containsKey('profilePicture') &&
                                        userData['profilePicture'] != null)
                                    ? userData['profilePicture'] as String
                                    : '';
        
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: profilePicture.isNotEmpty
                                        ? NetworkImage(profilePicture)
                                        : AssetImage('assets/images/profile.png')
                                            as ImageProvider,
                                    child: profilePicture.isEmpty ? null : null,
                                  ),
                                  title: Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: CustomText(
                                          textLabel: '$firstName $lastName',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          textColor: AppColors.textColor,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (index) => Icon(
                                            index < stars
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: CustomText(
                                    textLabel: comment,
                                    fontSize: 14,
                                    textColor: currentEvent == AppEvent.none ?Colors.grey:Colors.black,
                                    maxLines: 5,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      customDialog(context, 'Delete Review',
                                          'Are you sure you want to remove this user\'s comment?',
                                          () {
                                        deleteReview(context, productId, userId);
                                        navPop(context);
                                      });
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> deleteReview(
      BuildContext context, String productId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(userId)
          .delete();
      if (!context.mounted) return;
      successSnackbar(context, "Review deleted successfully.");
    } catch (e) {
      errorSnackbar(context, "Failed to delete review: $e");
    }
  }
}
