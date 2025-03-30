import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/seller/add_product.dart';
import 'package:marketlinkapp/seller/add_service.dart';
import 'package:marketlinkapp/seller/all_products.dart';
import 'package:marketlinkapp/seller/all_services.dart';
import 'package:marketlinkapp/seller/product_details.dart';
import 'package:marketlinkapp/seller/profile.dart';
import 'package:marketlinkapp/seller/service_details.dart';
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
  int? totalService;
  bool isFetchingProducts = true;
  int ongoingOrders = 0;
  bool isFetchingOngoingOrders = true;

  @override
  void initState() {
    super.initState();
    fetchTotalProducts();
    fetchTotalServices();
    fetchOngoingOrders(context);
  }

  Stream<int> fetchTotalProducts() {
    try {
      final userInfo = Provider.of<UserProvider>(context, listen: false).user;
      final sellerId = userInfo?.uid ?? "";

      return FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots()
          .map((querySnapshot) => querySnapshot.docs.length);
    } catch (e) {
      return const Stream.empty();
    } finally {
      setState(() {
        isFetchingProducts = false;
      });
    }
  }

  Stream<int> fetchTotalServices() {
    try {
      final userInfo = Provider.of<UserProvider>(context, listen: false).user;
      final sellerId = userInfo?.uid ?? "";

      return FirebaseFirestore.instance
          .collection('services')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots()
          .map((querySnapshot) => querySnapshot.docs.length);
    } catch (e) {
      return const Stream.empty();
    } finally {
      setState(() {
        isFetchingProducts = false;
      });
    }
  }

Stream<int> fetchOngoingOrders(BuildContext context) {
  final userInfo = Provider.of<UserProvider>(context, listen: false).user;
  final sellerId = userInfo?.uid ?? "";

  return FirebaseFirestore.instance
      .collection('products')
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .asyncMap((productsSnapshot) async {
    int count = 0;

    for (var productDoc in productsSnapshot.docs) {
      final productId = productDoc.id;

      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('orders')
          .where('status', isEqualTo: 'ordered')
          .snapshots()
          .first; 

      count += ordersSnapshot.docs.length;
    }

    return count;
  });
}

  Stream<List<QueryDocumentSnapshot>> fetchRecentProducts(String sellerId) {
    return FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('dateCreated', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<QueryDocumentSnapshot>> fetchRecentServices(String sellerId) {
    return FirebaseFirestore.instance
        .collection('services')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('dateCreated', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

 Stream<List<Map<String, dynamic>>> fetchRecentOrders(String sellerId) {
  return FirebaseFirestore.instance
      .collection('products')
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .asyncMap((productsSnapshot) async {
    List<Map<String, dynamic>> recentOrders = [];
    List<String> customerIds = [];
    Map<String, String> customerNames = {};

    final ordersFutures = productsSnapshot.docs.map((productDoc) {
      return FirebaseFirestore.instance
          .collection('products')
          .doc(productDoc.id)
          .collection('orders')
          .orderBy('dateOrdered', descending: true)
          .limit(3)
          .get();
    });

    final ordersSnapshots = await Future.wait(ordersFutures);

    for (int i = 0; i < ordersSnapshots.length; i++) {
      final productDoc = productsSnapshot.docs[i];
      final productName = productDoc['productName'] ?? 'Unnamed Product';

      for (var orderDoc in ordersSnapshots[i].docs) {
        final customerId = orderDoc.id;
        if (!customerNames.containsKey(customerId)) {
          customerIds.add(customerId);
        }

        recentOrders.add({
          'productName': productName,
          'customerId': customerId,
          'status': orderDoc['status'],
          'dateOrdered': orderDoc['dateOrdered'],
        });
      }
    }

    if (customerIds.isNotEmpty) {
      final customerSnapshots = await FirebaseFirestore.instance
          .collection('customers')
          .where(FieldPath.documentId, whereIn: customerIds)
          .get();

      for (var customerDoc in customerSnapshots.docs) {
        customerNames[customerDoc.id] =
            '${customerDoc['firstName']} ${customerDoc['lastName']}';
      }
    }

    for (var order in recentOrders) {
      order['customerName'] =
          customerNames[order['customerId']] ?? 'Unknown Customer';
    }

    return recentOrders;
  });
}

  Stream<bool> getSellerApprovalStatus(String sellerId) {
    return FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['approved'] == true);
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
          FadeInLeft(
            child: IconButton(
                onPressed: () {
                  navPush(context, const SellerProfile());
                },
                icon: Icon(
                  Icons.person,
                  color: Colors.white,
                )),
          )
        ],
        title: FadeInLeft(
          child: Row(
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInUp(
              child: const CustomText(
                textLabel: "Products & Services Summary",
                fontSize: 18,
                fontWeight: FontWeight.bold,
                textColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            FadeInUp(
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(width: 2, color: Colors.yellow)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
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
                              StreamBuilder(
                                  stream: fetchTotalProducts(),
                                  builder: (context, snapshot) {
                                    int totalProducts = snapshot.data ?? 0;

                                    return isFetchingProducts ||
                                            isFetchingOngoingOrders
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
                                            textColor: Colors.yellow);
                                  })
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              CustomText(
                                textLabel: "Total Services",
                                fontSize: 16,
                                textColor: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              const SizedBox(height: 5),
                              StreamBuilder(
                                  stream: fetchTotalServices(),
                                  builder: (context, snapshot) {
                                    int totalService = snapshot.data ?? 0;
                                    return isFetchingOngoingOrders ||
                                            isFetchingOngoingOrders
                                        ? SizedBox(
                                            height: 25,
                                            width: 25,
                                            child: CircularProgressIndicator(
                                              color: Colors.yellow,
                                            ),
                                          )
                                        : CustomText(
                                            textLabel: '$totalService',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            textColor: Colors.yellow);
                                  })
                            ],
                          ),
                          Column(
                            children: [
                              const CustomText(
                                textLabel: "Booked Services",
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
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<bool>(
                    stream: getSellerApprovalStatus(userInfo!.uid),
                    builder: (context, snapshot) {
                      bool isApproved = snapshot.data ?? false;

                      return ElevatedButton(
                        onPressed: () {
                          if (isApproved) {
                            navPush(context, SellerAddProduct());
                          } else {
                            errorSnackbar(
                              context,
                              'This account is not approved yet. Please wait for admin approval before being able to sell items.',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
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
                      );
                    },
                  ),
                  StreamBuilder<bool>(
                    stream: getSellerApprovalStatus(userInfo.uid),
                    builder: (context, snapshot) {
                      bool isApproved = snapshot.data ?? false;

                      return ElevatedButton(
                        onPressed: () {
                          if (isApproved) {
                            navPush(context, SellerAddService());
                          } else {
                            errorSnackbar(
                              context,
                              'This account is not approved yet. Please wait for admin approval before being able to add services.',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: CustomText(
                          textLabel: "Add Service",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          textColor: Colors.purple.shade800,
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              child: Row(
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
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: fetchRecentProducts(sellerId),
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
                      return FadeInUp(
                        child: Card(
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
                        ),
                      );
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            FadeInUp(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText(
                    textLabel: "Recent Services",
                    fontSize: 18,
                    textColor: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  TextButton(
                    onPressed: () {
                      navPush(context, const SellerAllServices());
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
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: fetchRecentServices(sellerId),
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
                      textLabel: "No Services found.",
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
                      final service = snapshot.data![index];

                      final productName =
                          service['serviceName'] ?? "Unnamed Service";
                      final category = service['category'] ?? "Uncategorized";
                      final price =
                          service['price']?.toStringAsFixed(0) ?? "No Price";
                      return FadeInUp(
                        child: Card(
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
                                  SellerServiceDetails(serviceId: service.id));
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            const CustomText(
              textLabel: "Recent Orders",
              fontSize: 18,
              fontWeight: FontWeight.bold,
              textColor: Colors.white,
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fetchRecentOrders(sellerId),
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
                  debugging(snapshot.error.toString());
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
                      final status = order['status'];
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
