import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/chat/chat.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/customer/category.dart';
import 'package:marketlinkapp/customer/components.dart';
import 'package:marketlinkapp/customer/profile.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:provider/provider.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final AppEvent currentEvent = getCurrentEvent();

  String? selectedCategory;
  Timer? debounceTimer;
  late TabController _tabController;
  final List<Map<String, dynamic>> serviceCategories = [
    {'title': 'Personal Care', 'icon': Icons.spa},
    {'title': 'Home Services', 'icon': Icons.build},
    {'title': 'Automotive', 'icon': Icons.directions_car},
    {'title': 'Health', 'icon': Icons.local_hospital},
    {'title': 'Event', 'icon': Icons.celebration},
    {'title': 'Coaching', 'icon': Icons.school},
    {'title': 'Tech', 'icon': Icons.computer},
    {'title': 'Pets', 'icon': Icons.pets},
    {'title': 'Others', 'icon': Icons.more_horiz},
  ];
  final List<Map<String, dynamic>> productCategories = [
    {'title': 'Home', 'icon': Icons.home},
    {'title': 'Clothing', 'icon': Icons.checkroom},
    {'title': 'Electronics', 'icon': Icons.devices},
    {'title': 'Beauty', 'icon': Icons.brush},
    {'title': 'Toys', 'icon': Icons.toys},
    {'title': 'Sports', 'icon': Icons.sports},
    {'title': 'Food', 'icon': Icons.fastfood},
    {'title': 'Books', 'icon': Icons.menu_book},
    {'title': 'Groceries', 'icon': Icons.local_grocery_store},
    {'title': 'Others', 'icon': Icons.more_horiz},
  ];

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

  Future<List<QueryDocumentSnapshot>> fetchServices() async {
    Query query = FirebaseFirestore.instance
        .collection('services')
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
    _tabController = TabController(length: 2, vsync: this);

    
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
        backgroundColor: backgroundColor(currentEvent),
        elevation: 0,
        title: FadeInLeft(child: CustomText(textLabel: 'Explore What You Need...', fontSize: 18,textColor: headerTitleColor(currentEvent),)),
        actions: [
          IconButton(
            icon: Icon(Icons.message, color: headerTitleColor(currentEvent)),
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
            icon: Icon(Icons.person, color: headerTitleColor(currentEvent)),
            onPressed: () {
              navPush(context, const CustomerProfile());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Services'),
          ],
        ),
      ),
      body: Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage(backgroundImage(currentEvent)),
      fit: BoxFit.cover,
    ),
  ),
  child: TabBarView(
    controller: _tabController,
    children: [
      homeTab(context, searchController, userId, productCategories, true),
      homeTab(context, searchController, userId, serviceCategories, false),
    ],
  ),
),

    );
  }

 
  Widget homeTab(BuildContext context, TextEditingController searchController,
      String userId, List<Map<String, dynamic>> categories, bool isProduct) {
        
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            searchContainer(context, searchController, userId),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  return buildCategoryItem(
                      context, category['title'], category['icon']);
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            CustomText(textLabel:isProduct? 'Products You May Like' : 'Services You May Need', fontSize: 18),
            const SizedBox(height: 20),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future:isProduct?  fetchProducts() : fetchServices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: SpinKitFadingCircle(
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: CustomText(
                        textLabel:isProduct? 'Error displaying products.' : 'Error displaying services',
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
                        textLabel: isProduct?'No products available.':'No services available',
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                    ),
                  );
                }

                final content = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: content.length,
                  itemBuilder: (context, index) {
                    final item = content[index];
                    final itemId = item.id;
                    final itemName = isProduct? item['productName'] ?? 'Unnamed' : item ['serviceName'] ?? 'Unnamed';
                   final data = item.data() as Map<String, dynamic>;

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
   : "₱${(promoValue as num).toStringAsFixed(2)} OFF";

                    final imageUrl = item['imageUrl'];
                return itemDisplay(
  context,
  imageUrl,
  userId,
  itemId,
  itemName,
  priceText,
  isProduct,
  hasPromo,
  discountedText,
  promoLabel,
);

                  },
                );
              },
            ),
          ],
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
              backgroundColor: AppColors.accent,
              child: Icon(icon, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 8),
            CustomText(textLabel: title, fontSize: 14, maxLines: 2,)
          ],
        ),
      ),
    );
  }

}

Future<void> storeProductClick(String userId, String productId) async {
  final docRef = FirebaseFirestore.instance
      .collection('productClicks')
      .doc('${userId}_$productId'); 

  final docSnapshot = await docRef.get();

  if (docSnapshot.exists) {
    await docRef.update({
      'timestamp': FieldValue.serverTimestamp(),
      'count': FieldValue.increment(1),
    });
  } else {
    await docRef.set({
      'userId': userId,
      'productId': productId,
      'timestamp': FieldValue.serverTimestamp(),
      'count': 1,
    });
  }
}


Future<void> fetchSearchHistory(String userId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('customers')
      .doc(userId)
      .collection('searchHistory')
      .orderBy('timestamp', descending: true)
      .get();

  if (querySnapshot.docs.isEmpty) {
    debugPrint('No search history found for user: $userId');
    return;
  }

  for (var doc in querySnapshot.docs) {
    final data = doc.data();
    debugging(
        'Search Query: ${data['query']}, Timestamp: ${data['timestamp']}');
  }
}
