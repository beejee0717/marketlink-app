import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/seller/add_product.dart';
import 'package:marketlinkapp/seller/all_products.dart';
import 'package:marketlinkapp/seller/product_details.dart';
import 'package:marketlinkapp/seller/profile.dart';
import 'package:provider/provider.dart';
import '../components/snackbar.dart';
import '../provider/user_provider.dart';

class SellerHome extends StatefulWidget {
  const SellerHome({super.key});

  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  int? totalProducts;
  bool isFetchingProducts = true;
  int ongoingOrders = 0;
  bool isFetchingOngoingOrders = true;

  @override
  void initState() {
    super.initState();
    fetchTotalProducts();
    fetchOngoingOrders();
  }

  Future<void> fetchTotalProducts() async {
    try {
      final userInfo = Provider.of<UserProvider>(context, listen: false).user;
      final sellerId = userInfo?.uid ?? "";

      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      setState(() {
        totalProducts = querySnapshot.docs.length;
      });
    } catch (e) {
      if (!mounted) return;
      errorSnackbar(context, "Failed to fetch total products.");
    } finally {
      setState(() {
        isFetchingProducts = false;
      });
    }
  }

  Future<void> fetchOngoingOrders() async {
    try {
      final userInfo = Provider.of<UserProvider>(context, listen: false).user;
      final sellerId = userInfo?.uid ?? "";

      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      int count = 0;

      for (var productDoc in productsSnapshot.docs) {
        final productId = productDoc.id;

        final ordersSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .collection('orders')
            .where('delivered', isEqualTo: false)
            .get();

        count += ordersSnapshot.docs.length;
      }

      setState(() {
        ongoingOrders = count;
      });
    } catch (e) {
      if (!mounted) return;
      errorSnackbar(context, "Failed to fetch ongoing orders.");
    } finally {
      setState(() {
        isFetchingOngoingOrders = false;
      });
    }
  }

  Future<List<QueryDocumentSnapshot>> fetchRecentProducts(
      String sellerId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('dateCreated', descending: true)
        .limit(5)
        .get();
    return querySnapshot.docs;
  }

  Future<List<Map<String, dynamic>>> fetchRecentOrders(String sellerId) async {
    List<Map<String, dynamic>> recentOrders = [];

    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .get();

    for (var productDoc in productsSnapshot.docs) {
      final productId = productDoc.id;

      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('orders')
          .orderBy('dateOrdered', descending: true)
          .limit(5)
          .get();

      for (var orderDoc in ordersSnapshot.docs) {
        final customerId = orderDoc.id;
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(customerId)
            .get();

        final customerName = customerDoc.exists
            ? '${customerDoc['firstName']} ${customerDoc['lastName']}'
            : 'Unknown Customer';

        recentOrders.add({
          'productName': productDoc['productName'] ?? 'Unnamed Product',
          'customerName': customerName,
          'delivered': orderDoc['delivered'] ?? false,
          'dateOrdered': orderDoc['dateOrdered'],
        });
      }
    }

    return recentOrders;
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    final sellerId = userInfo?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
              onPressed: () {
                navPush(context, const SellerProfile());
              },
              icon: Icon(
                Icons.person,
                color: Colors.white,
              ))
        ],
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_no_text.png',
              width: 35,
              height: 35,
            ),
            const SizedBox(
              width: 10,
            ),
            const CustomText(
              textLabel: 'Market Link',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(
              textLabel: "Products Summary",
              fontSize: 18,
              fontWeight: FontWeight.bold,
              textColor: Colors.white,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(width: 2, color: Colors.yellow)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        CustomText(
                          textLabel: "Total Products",
                          fontSize: 16,
                          textColor: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 5),
                        isFetchingProducts || isFetchingOngoingOrders
                            ? SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                  color: Colors.yellow,
                                ),
                              )
                            : CustomText(
                                textLabel: '$totalProducts',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                textColor: Colors.yellow),
                      ],
                    ),
                    Column(
                      children: [
                        const CustomText(
                          textLabel: "Ongoing Orders",
                          fontSize: 16,
                          textColor: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 5),
                        isFetchingProducts || isFetchingOngoingOrders
                            ? SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                  color: Colors.yellow,
                                ),
                              )
                            : CustomText(
                                textLabel: "$ongoingOrders",
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                textColor: Colors.yellow,
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CustomText(
                  textLabel: "Recent Products",
                  fontSize: 18,
                  textColor: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                TextButton(
                  onPressed: () {
                    navPush(context, const SellerAllProducts());
                  },
                  child: CustomText(
                    textLabel: "View All",
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    textColor: Colors.yellow.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: fetchRecentProducts(sellerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SpinKitDoubleBounce(
                        size: 50,
                        color: Colors.yellow,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      textLabel: "Error: ${snapshot.error}",
                      fontSize: 16,
                      textColor: Colors.red,
                    ),
                  );
                } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return Center(
                    child: const CustomText(
                      textLabel: "No products found.",
                      fontSize: 16,
                      textColor: Colors.white,
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final product = snapshot.data![index];

                      final productName =
                          product['productName'] ?? "Unnamed Product";
                      final category = product['category'] ?? "Uncategorized";
                      final price =
                          product['price']?.toStringAsFixed(0) ?? "No Price";
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: CustomText(
                            textLabel: productName,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomText(
                                    textLabel: "Price: ",
                                    fontSize: 14,
                                    textColor: Colors.black87,
                                  ),
                                  CustomText(
                                    textLabel: '₱$price',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    textColor: Colors.orange,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CustomText(
                                    textLabel: "Category: ",
                                    fontSize: 14,
                                    textColor: Colors.black87,
                                  ),
                                  CustomText(
                                    textLabel: category,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.yellow.shade800,
                          ),
                          onTap: () {
                            navPush(context,
                                SellerProductDetails(productId: product.id));
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (userInfo!.approved) {
                    navPush(context, SellerAddProduct());
                  } else {
                    errorSnackbar(context,
                        'This account is not approved yet. Please wait for admin approval before being able to sell items.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: CustomText(
                  textLabel: "Add Product",
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  textColor: Colors.purple.shade800,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const CustomText(
              textLabel: "Recent Orders",
              fontSize: 18,
              fontWeight: FontWeight.bold,
              textColor: Colors.white,
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchRecentOrders(sellerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SpinKitDoubleBounce(
                        size: 50,
                        color: Colors.yellow,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return CustomText(
                    textLabel: "Error: ${snapshot.error}",
                    fontSize: 16,
                    textColor: Colors.red,
                  );
                } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(
                    child: CustomText(
                      textLabel: "No recent orders.",
                      fontSize: 16,
                      textColor: Colors.white,
                    ),
                  );
                } else {
                  final recentOrders = snapshot.data!;
                  return ListView.builder(
                    itemCount: recentOrders.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final order = recentOrders[index];
                      final status =
                          order['delivered'] ? 'Finished' : 'Ongoing';
                      final formattedDate = DateFormat('MM/dd/yyyy hh:mm a')
                          .format(order['dateOrdered'].toDate());

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: CustomText(
                            textLabel:
                                order['productName'] ?? 'Unnamed Product',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomText(
                                    textLabel: 'Customer: ',
                                    fontSize: 14,
                                    textColor: Colors.black87,
                                  ),
                                  CustomText(
                                    textLabel: order['customerName'],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CustomText(
                                    textLabel: 'Date Ordered: ',
                                    fontSize: 14,
                                    textColor: Colors.black87,
                                  ),
                                  CustomText(
                                    textLabel: formattedDate,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CustomText(
                                    textLabel: 'Status: ',
                                    fontSize: 14,
                                    textColor: Colors.black87,
                                  ),
                                  CustomText(
                                    textLabel: status,
                                    fontSize: 14,
                                    textColor: status == 'Ongoing'
                                        ? Colors.orange
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
