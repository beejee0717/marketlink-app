import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/seller/add_product.dart';
import 'package:marketlinkapp/seller/add_service.dart';
import 'package:marketlinkapp/seller/all_products.dart';
import 'package:marketlinkapp/seller/all_services.dart';
import 'package:marketlinkapp/seller/bookings.dart';
import 'package:marketlinkapp/seller/orders.dart';
import 'package:marketlinkapp/seller/product_details.dart';
import 'package:marketlinkapp/seller/profile.dart';
import 'package:marketlinkapp/seller/service_details.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:provider/provider.dart';
import '../components/snackbar.dart';
import '../provider/user_provider.dart';

class SellerHome extends StatefulWidget {
  const SellerHome({super.key});

  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  late Stream<List<QueryDocumentSnapshot>> productsStream;
  late Stream<List<QueryDocumentSnapshot>> serviceStream;
  late Stream<List<Map<String, dynamic>>> ordersStream;
  late Stream<List<Map<String, dynamic>>> bookingStream;
  late AppEvent currentEvent = getCurrentEvent();
  bool productsStrInitialized = false;
  bool serviceStrInitialized = false;
  bool ordersStrInitialized = false;
  bool bookingStrInitialized = false;
  bool isFetchingProducts = true;
  bool isFetchingServices = true;
  bool isFetchingOngoingOrders = true;
  bool isFetchingBookings = true;

  @override
  void initState() {
    super.initState();

    isFetchingProducts = true;
    isFetchingServices = true;
    isFetchingOngoingOrders = true;
    isFetchingBookings = true;

    fetchTotalProducts().listen((_) {
      if (mounted) setState(() => isFetchingProducts = false);
    });

    fetchTotalServices().listen((_) {
      if (mounted) setState(() => isFetchingServices = false);
    });

    fetchOngoingOrders().listen((_) {
      if (mounted) setState(() => isFetchingOngoingOrders = false);
    });

    fetchBookings().listen((_) {
      if (mounted) setState(() => isFetchingBookings = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    final sellerId = userInfo?.uid ?? "";

    if (!productsStrInitialized) {
      productsStream = fetchRecentProducts(sellerId);
      productsStrInitialized = true;
    }

    if (!serviceStrInitialized) {
      serviceStream = fetchRecentServices(sellerId);
      serviceStrInitialized = true;
    }
    if (!ordersStrInitialized) {
      ordersStream = fetchRecentOrders(sellerId);
      ordersStrInitialized = true;
    }
    if (!bookingStrInitialized) {
      bookingStream = fetchRecentBookings(sellerId);
      bookingStrInitialized = true;
    }
  }

  Stream<int> fetchTotalProducts() {
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    final sellerId = userInfo?.uid ?? "";

    return FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }

  Stream<int> fetchTotalServices() {
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    final sellerId = userInfo?.uid ?? "";

    return FirebaseFirestore.instance
        .collection('services')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }

  Stream<int> fetchOngoingOrders() {
    final sellerId =
        Provider.of<UserProvider>(context, listen: false).user?.uid ?? "";

    return FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .where('status', isEqualTo: 'ordered')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> fetchBookings() {
    final sellerId =
        Provider.of<UserProvider>(context, listen: false).user?.uid ?? "";

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('dateOrdered', descending: true)
        .limit(4)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> recentOrders = [];

      for (var doc in snapshot.docs) {
        final order = doc.data();
        final productId = order['productId'];
        final customerId = order['customerId'];
        final quantity = order['quantity'] ?? 0;

        // Get product details
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        final productData = productDoc.exists ? productDoc.data()! : {};
        final productName = productData['productName'] ?? 'Unknown';
        final price = (productData['price'] ?? 0) as num;
        final imageUrl = productData['imageUrl'] ?? '';

        // Get customer details
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(customerId)
            .get();

        final customerData = customerDoc.exists ? customerDoc.data()! : {};
        final customerName =
            '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'
                .trim();
        final customerContact = customerData['contactNumber'] ?? 'N/A';
        final customerProfilePic = customerData['profilePicture'] ?? '';

        final amount = price * quantity;

        final orderData = {
          'orderId': doc.id,
          'productId': productId,
          'productName': productName,
          'quantity': quantity,
          'customerId': customerId,
          'customerName': customerName,
          'dateOrdered': order['dateOrdered'],
          'customerProfilePic': customerProfilePic,
          'imageUrl': imageUrl,
          'customerContact': customerContact,
          'amount': amount,
          'status': order['status'],
        };

        recentOrders.add(orderData);
      }

      return recentOrders;
    });
  }

  Stream<List<Map<String, dynamic>>> fetchRecentBookings(String sellerId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('dateBooked', descending: true)
        .limit(4)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> recentBookings = [];

      for (var doc in snapshot.docs) {
        final booking = doc.data();
        final serviceId = booking['serviceId'];
        final customerId = booking['customerId'];

        // Service details
        final serviceDoc = await FirebaseFirestore.instance
            .collection('services')
            .doc(serviceId)
            .get();

        final serviceData = serviceDoc.data() ?? {};
        final serviceName = serviceData['serviceName'] ?? 'Unknown';

        // Customer details
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(customerId)
            .get();

        final customerData = customerDoc.data() ?? {};
        final customerName =
            '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'
                .trim();

        final bookingData = {
          'bookingId': doc.id,
          'serviceId': serviceId,
          'serviceName': serviceName,
          'dateBooked': booking['dateBooked'],
          'dateOrdered': booking['dateOrdered'],
          'customerId': customerId,
          'customerName': customerName,
          'status': booking['status'] ?? 'unknown',
          'imageUrl': serviceData['imageUrl'] ?? '',
          'customerProfilePic': customerData['profilePicture'] ?? '',
          'customerContact': customerData['contactNumber'] ?? 'N/A',
          'amount': booking['price'] ?? serviceData['price'] ?? 0,
        };

        recentBookings.add(bookingData);
      }

      return recentBookings;
    });
  }

  String calculateDiscountedPrice(double price, num value, String type) {
    double discounted;
    if (type == 'percentage') {
      discounted = price - (price * (value / 100));
    } else if (type == 'fixed') {
      discounted = price - value;
    } else {
      discounted = price;
    }

    return discounted < 0 ? '0' : discounted.toStringAsFixed(0);
  }

  Stream<Map<String, bool>> getSellerStatus(String? riderId) {
    return FirebaseFirestore.instance
        .collection('sellers')
        .doc(riderId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      return {
        'approved': data?['approved'] == true,
        'disabled': data?['disabled'] == true,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: sellerHeaderColor(currentEvent),
        actions: [
          IconButton(
              onPressed: () {
                navPush(context, const SellerProfile());
              },
              icon: Icon(
                Icons.person,
                color: currentEvent == AppEvent.none
                    ? Colors.white
                    : AppColors.primary,
              )),
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
            CustomText(
              textLabel: 'Market Link',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              textColor: currentEvent == AppEvent.none
                  ? Colors.white
                  : AppColors.primary,
            ),
          ],
        ),
      ),
      body: StreamBuilder<Map<String, bool>>(
        stream: getSellerStatus(userInfo?.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final status = snapshot.data!;

          bool isApproved = status['approved'] ?? false;
          bool isDisabled = status['disabled'] ?? false;

          if (!isApproved) {
            return Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: currentEvent == AppEvent.none
                          ? AssetImage(wallpaper(currentEvent))
                          : AssetImage(backgroundImage(currentEvent)),
                      fit: BoxFit.cover)),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo_no_text.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Seller not approved yet. Please wait for the Admin to approve before you can post products and services.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 243, 243, 243),
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (isDisabled) {
            return Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: currentEvent == AppEvent.none
                          ? AssetImage(wallpaper(currentEvent))
                          : AssetImage(backgroundImage(currentEvent)),
                      fit: BoxFit.cover)),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 150,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your account is currently disabled. This may be the result of a policy violation. Please contact the administrator for clarification and next steps.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: currentEvent == AppEvent.none
                        ? AssetImage(wallpaper(currentEvent))
                        : AssetImage(backgroundImage(currentEvent)),
                    fit: BoxFit.cover)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    textLabel: "Products & Services Summary",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    textColor: currentEvent == AppEvent.none
                        ? Colors.white
                        : AppColors.textColor,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(width: 2, color: AppColors.yellow),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // --- First row ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Total Products
                              Column(
                                children: [
                                  CustomText(
                                    textLabel: "Total Products",
                                    fontSize: 16,
                                    textColor: AppColors.yellow,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  const SizedBox(height: 5),
                                  StreamBuilder<int>(
                                    stream: fetchTotalProducts(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return SizedBox(
                                          height: 25,
                                          width: 25,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.yellow),
                                        );
                                      }
                                      final totalProducts = snapshot.data ?? 0;
                                      return CustomText(
                                        textLabel: '$totalProducts',
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        textColor: AppColors.yellow,
                                      );
                                    },
                                  ),
                                ],
                              ),

                              // Ongoing Orders
                              Column(
                                children: [
                                  CustomText(
                                    textLabel: "Ongoing Orders",
                                    fontSize: 16,
                                    textColor: AppColors.yellow,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  const SizedBox(height: 5),
                                  StreamBuilder<int>(
                                    stream: fetchOngoingOrders(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return SizedBox(
                                          height: 25,
                                          width: 25,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.yellow),
                                        );
                                      }
                                      final ongoingOrders = snapshot.data ?? 0;
                                      return CustomText(
                                        textLabel: '$ongoingOrders',
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        textColor: AppColors.yellow,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // --- Second row ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Total Services
                              Column(
                                children: [
                                  CustomText(
                                    textLabel: "Total Services",
                                    fontSize: 16,
                                    textColor: AppColors.yellow,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  const SizedBox(height: 5),
                                  StreamBuilder<int>(
                                    stream: fetchTotalServices(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return SizedBox(
                                          height: 25,
                                          width: 25,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.yellow),
                                        );
                                      }
                                      final totalServices = snapshot.data ?? 0;
                                      return CustomText(
                                        textLabel: '$totalServices',
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        textColor: AppColors.yellow,
                                      );
                                    },
                                  ),
                                ],
                              ),

                              // Booked Services
                              Column(
                                children: [
                                  CustomText(
                                    textLabel: "Booked Services",
                                    fontSize: 16,
                                    textColor: AppColors.yellow,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  const SizedBox(height: 5),
                                  StreamBuilder<int>(
                                    stream: fetchBookings(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return SizedBox(
                                          height: 25,
                                          width: 25,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.yellow),
                                        );
                                      }
                                      final bookedServices = snapshot.data ?? 0;
                                      return CustomText(
                                        textLabel: '$bookedServices',
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        textColor: AppColors.yellow,
                                      );
                                    },
                                  ),
                                ],
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
                      ElevatedButton(
                        onPressed: () {
                          navPush(context, SellerAddProduct());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
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
                          textColor: sellerAddButton(currentEvent),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          navPush(context, SellerAddService());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
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
                          textColor: sellerAddButton(currentEvent),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        textLabel: "Recent Products",
                        fontSize: 18,
                        textColor: currentEvent == AppEvent.none
                            ? Colors.white
                            : AppColors.textColor,
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
                          textColor: currentEvent == AppEvent.none
                              ? AppColors.yellow
                              : AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: productsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: SpinKitDoubleBounce(
                              size: 50,
                              color: AppColors.yellow,
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
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return Center(
                          child: CustomText(
                            textLabel: "No products found.",
                            fontSize: 16,
                            textColor: currentEvent == AppEvent.none
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        );
                      } else {
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final product = snapshot.data![index];
                            final data =
                                product.data() as Map<String, dynamic>?;

                            final productName =
                                data?['productName'] ?? "Unnamed Product";
                            final category =
                                data?['category'] ?? "Uncategorized";
                            final price = data?['price']?.toDouble() ?? 0.0;

                            final promo =
                                (data?['promo'] is Map<String, dynamic>)
                                    ? data!['promo'] as Map<String, dynamic>
                                    : null;

                            final isPromo = promo?['enabled'] == true;
                            final promoType = promo?['type'];
                            final promoValue = promo?['value'];

                            return Card(
                              color: AppColors.transparentWhite,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: CustomText(
                                        textLabel: productName,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isPromo)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade600,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: CustomText(
                                          textLabel: promoType == 'percentage'
                                              ? "$promoValue% OFF"
                                              : "₱${promoValue.toStringAsFixed(2)} OFF",
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          textColor: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (isPromo &&
                                        promoType != null &&
                                        promoValue != null) ...[
                                      Row(
                                        children: [
                                          CustomText(
                                            textLabel: "Price: ",
                                            fontSize: 14,
                                            textColor: Colors.black87,
                                          ),
                                          if (isPromo) ...[
                                            CustomText(
                                              textLabel:
                                                  "₱${price.toStringAsFixed(0)}",
                                              fontSize: 14,
                                              textColor: Colors.grey,
                                              fontWeight: FontWeight.normal,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                            const SizedBox(width: 5),
                                            CustomText(
                                              textLabel: promoType ==
                                                      'percentage'
                                                  ? '₱${(price * (1 - (promoValue ?? 0) / 100)).toStringAsFixed(0)}'
                                                  : '₱${(price - (promoValue ?? 0)).toStringAsFixed(0)}',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              textColor: Colors.orange,
                                            ),
                                          ] else ...[
                                            CustomText(
                                              textLabel:
                                                  '₱${price.toStringAsFixed(0)}',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              textColor: Colors.orange,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ] else ...[
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
                                    ],
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
                                  color: AppColors.yellow,
                                ),
                                onTap: () {
                                  navPush(
                                      context,
                                      SellerProductDetails(
                                          productId: product.id));
                                },
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        textLabel: "Recent Services",
                        fontSize: 18,
                        textColor: currentEvent == AppEvent.none
                            ? Colors.white
                            : AppColors.textColor,
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
                          textColor: currentEvent == AppEvent.none
                              ? AppColors.yellow
                              : AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: serviceStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: SpinKitDoubleBounce(
                              size: 50,
                              color: AppColors.yellow,
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
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return Center(
                          child: CustomText(
                            textLabel: "No Services found.",
                            fontSize: 16,
                            textColor: currentEvent == AppEvent.none
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        );
                      } else {
                        return ListView.builder(
                            itemCount: snapshot.data!.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final service = snapshot.data![index];
                              final data =
                                  service.data() as Map<String, dynamic>?;

                              final promo =
                                  (data?['promo'] is Map<String, dynamic>)
                                      ? data!['promo'] as Map<String, dynamic>
                                      : null;

                              final isPromo = promo?['enabled'] == true;
                              final promoType = promo?['type'];
                              final promoValue = promo?['value'];

                              final productName =
                                  data?['serviceName'] ?? "Unnamed Service";
                              final category =
                                  data?['category'] ?? "Uncategorized";
                              final price = data?['price']?.toDouble() ?? 0.0;

                              double discountedPrice = price;
                              if (isPromo) {
                                if (promoType == 'percentage') {
                                  discountedPrice =
                                      price - (price * (promoValue ?? 0) / 100);
                                } else if (promoType == 'fixed') {
                                  discountedPrice = price - (promoValue ?? 0);
                                }
                                if (discountedPrice < 0) discountedPrice = 0;
                              }

                              return Card(
                                color: AppColors.transparentWhite,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: CustomText(
                                          textLabel: productName,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isPromo)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: CustomText(
                                            textLabel: promoType == 'percentage'
                                                ? "${promoValue.toStringAsFixed(2)}% OFF"
                                                : "₱${promoValue.toStringAsFixed(2)} OFF",
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            textColor: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          CustomText(
                                            textLabel: "Price: ",
                                            fontSize: 14,
                                            textColor: Colors.black87,
                                          ),
                                          if (isPromo) ...[
                                            CustomText(
                                              textLabel:
                                                  "₱${price.toStringAsFixed(0)}",
                                              fontSize: 14,
                                              textColor: Colors.grey,
                                              fontWeight: FontWeight.normal,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                            const SizedBox(width: 5),
                                            CustomText(
                                              textLabel:
                                                  "₱${discountedPrice.toStringAsFixed(0)}",
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              textColor: Colors.orange,
                                            ),
                                          ] else ...[
                                            CustomText(
                                              textLabel:
                                                  '₱${price.toStringAsFixed(0)}',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              textColor: Colors.orange,
                                            ),
                                          ],
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
                                    color: AppColors.yellow,
                                  ),
                                  onTap: () {
                                    navPush(
                                        context,
                                        SellerServiceDetails(
                                            serviceId: service.id));
                                  },
                                ),
                              );
                            });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        textLabel: "Recent Orders",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        textColor: currentEvent == AppEvent.none
                            ? Colors.white
                            : AppColors.textColor,
                      ),
                      TextButton(
                        onPressed: () {
                          navPush(context, const SellerOrders());
                        },
                        child: CustomText(
                          textLabel: "View All",
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          textColor: currentEvent == AppEvent.none
                              ? AppColors.yellow
                              : AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: ordersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: SpinKitDoubleBounce(
                              size: 50,
                              color: AppColors.yellow,
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return CustomText(
                          textLabel: "Error: ${snapshot.error}",
                          fontSize: 16,
                          textColor: Colors.red,
                        );
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return Center(
                          child: CustomText(
                            textLabel: "No recent orders.",
                            fontSize: 16,
                            textColor: currentEvent == AppEvent.none
                                ? Colors.white
                                : AppColors.textColor,
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
                            final formattedDate =
                                DateFormat('MM/dd/yyyy hh:mm a')
                                    .format(order['dateOrdered'].toDate());

                            return Card(
                              color: AppColors.transparentWhite,
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
                                          textColor: status == 'shipped'
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        textLabel: "Recent Bookings",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        textColor: currentEvent == AppEvent.none
                            ? Colors.white
                            : AppColors.textColor,
                      ),
                      TextButton(
                        onPressed: () {
                          navPush(context, const SellerBookings());
                        },
                        child: CustomText(
                          textLabel: "View All",
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          textColor: currentEvent == AppEvent.none
                              ? AppColors.yellow
                              : AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: bookingStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: SpinKitDoubleBounce(
                              size: 50,
                              color: AppColors.yellow,
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return CustomText(
                          textLabel: "Error: ${snapshot.error}",
                          fontSize: 16,
                          textColor: Colors.red,
                        );
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return Center(
                          child: CustomText(
                            textLabel: "No recent bookings.",
                            fontSize: 16,
                            textColor: currentEvent == AppEvent.none
                                ? Colors.white
                                : AppColors.textColor,
                          ),
                        );
                      } else {
                        final recentBookings = snapshot.data!;

                        return ListView.builder(
                          itemCount: recentBookings.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final booking = recentBookings[index];
                            debugging(booking.toString());
                            final status = booking['status'];
                            final formattedDate =
                                DateFormat('MM/dd/yyyy hh:mm a')
                                    .format(booking['dateBooked'].toDate());

                            return Card(
                              color: AppColors.transparentWhite,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: CustomText(
                                  textLabel: booking['serviceName'] ??
                                      'Unnamed Service',
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
                                          textLabel: booking['customerName'],
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        CustomText(
                                          textLabel: 'Date Booked: ',
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
                                          textColor: status == 'pending'
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
               SizedBox(height: 50,)
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
