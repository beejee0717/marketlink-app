import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/customer/home.dart';
import 'package:marketlinkapp/customer/product.dart';
import 'package:marketlinkapp/customer/search.dart';
import 'package:marketlinkapp/customer/service.dart';

Widget itemDisplay(BuildContext context, String? imageUrl, String userId,
    String itemId, String itemName, String price, bool isProduct) {
  return FadeInLeft(
    child: Stack(
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
            storeProductClick(userId, itemId);
            navPush(context, isProduct? CustomerProduct(productId: itemId):  CustomerService(serviceId: itemId));
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
              storeProductClick(userId, itemId);
              navPush(context, CustomerProduct(productId: itemId));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  textLabel: itemName,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  textColor: AppColors.white,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                CustomText(
                  textLabel: price,
                  fontSize: 14,
                  textColor: AppColors.white,
                ),
                FutureBuilder<Map<String, dynamic>>(
                  future: getRating(itemId, isProduct),
                  builder: (context, ratingSnapshot) {
                    if (ratingSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(
                        height: 20,
                        width: 50,
                        child: LinearProgressIndicator(),
                      );
                    }
                    if (ratingSnapshot.hasError) {
                      return const Text('Error');
                    }
    
                    double averageRating =
                        (ratingSnapshot.data?['averageRating'] ?? 0.0).toDouble();
                    int totalReviews = ratingSnapshot.data?['totalReviews'] ?? 0;
    
                    return Row(
                      children: [
                        ...List.generate(5, (index) {
                          if (index + 1 <= averageRating) {
                            return const Icon(Icons.star,
                                color: AppColors.goldenYellow, size: 20);
                          } else if (index + 0.5 <= averageRating) {
                            return const Icon(Icons.star_half,
                                color: AppColors.goldenYellow, size: 20);
                          } else {
                            return const Icon(Icons.star_border,
                                color: AppColors.goldenYellow, size: 20);
                          }
                        }),
                        const SizedBox(width: 5),
                        Text(
                          '($totalReviews)',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget searchContainer(BuildContext context,
    TextEditingController searchController, String userId) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(30),
      color: Colors.grey[200],
    ),
    padding: EdgeInsets.symmetric(horizontal: 3),
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Search',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}

Future<Map<String, dynamic>> getRating(String productId, bool isProduct) async {
  try {
    CollectionReference reviewsRef = FirebaseFirestore.instance
        .collection(isProduct? 'products':'services')
        .doc(productId)
        .collection('reviews');

    QuerySnapshot querySnapshot = await reviewsRef.get();

    if (querySnapshot.docs.isEmpty) {
      return {'averageRating': 0.0, 'totalReviews': 0};
    }

    double totalStars = 0;
    int totalReviews = querySnapshot.docs.length;

    for (var doc in querySnapshot.docs) {
      totalStars += (doc['stars'] as num).toDouble();
    }

    double averageRating = totalStars / totalReviews;

    return {'averageRating': averageRating, 'totalReviews': totalReviews};
  } catch (e) {
    return {'averageRating': 0.0, 'totalReviews': 0};
  }
}
