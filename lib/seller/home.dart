import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/navigator.dart';
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
        isFetchingServices = false;
      });
    }
  }

Stream<int> fetchOngoingOrders() {
  final sellerId = Provider.of<UserProvider>(context, listen: false).user?.uid ?? "";

  return FirebaseFirestore.instance
      .collection('orders')
      .where('sellerId', isEqualTo: sellerId)
      .where('status', isEqualTo: 'ordered')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}
Stream<int> fetchBookings() {
  final sellerId = Provider.of<UserProvider>(context, listen: false).user?.uid ?? "";

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

///////////////////////////////////////

  Stream<List<Map<String, dynamic>>> fetchRecentBookings(String sellerId) {
    return FirebaseFirestore.instance
        .collection('services')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .asyncMap((productsSnapshot) async {
      List<Map<String, dynamic>> recentOrders = [];
      List<String> customerIds = [];
      Map<String, String> customerNames = {};

      final ordersFutures = productsSnapshot.docs.map((productDoc) {
        return FirebaseFirestore.instance
            .collection('services')
            .doc(productDoc.id)
            .collection('bookings')
            .orderBy('dateOrdered', descending: true)
            .limit(3)
            .get();
      });

      final ordersSnapshots = await Future.wait(ordersFutures);

      for (int i = 0; i < ordersSnapshots.length; i++) {
        final productDoc = productsSnapshot.docs[i];
        final serviceName = productDoc['serviceName'] ?? 'Unnamed Service';

        for (var orderDoc in ordersSnapshots[i].docs) {
          final customerId = orderDoc.id;
          if (!customerNames.containsKey(customerId)) {
            customerIds.add(customerId);
          }

          recentOrders.add({
            'productName': serviceName,
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

///////////////////

  Stream<bool> getSellerApprovalStatus(String? sellerId) {
    return FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['approved'] == true);
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
                color: currentEvent == AppEvent.none ? Colors.white :AppColors.primary,
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
              textColor: currentEvent == AppEvent.none ? Colors.white :AppColors.primary,
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: currentEvent == AppEvent.none ? AssetImage(wallpaper(currentEvent )): AssetImage(backgroundImage(currentEvent )),
          fit: BoxFit.cover)
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               CustomText(
                textLabel: "Products & Services Summary",
                fontSize: 18,
                fontWeight: FontWeight.bold,
                textColor: currentEvent == AppEvent.none ? Colors.white :AppColors.textColor,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(width: 2, color: AppColors.yellow)),
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
                                textColor:AppColors.yellow,
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
                                              color: AppColors.yellow  ,
                                            ),
                                          )
                                        : CustomText(
                                            textLabel: '$totalProducts',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            textColor: AppColors.yellow );
                                  })
                            ],
                          ),
                          Column(
                            children: [
                              CustomText(
                                textLabel: "Ongoing Orders",
                                fontSize: 16,
                                textColor: AppColors.yellow,
                                fontWeight: FontWeight.w500,
                              ),
                              const SizedBox(height: 5),
                              StreamBuilder(
                                  stream: fetchOngoingOrders(),
                                  builder: (context, snapshot) {
                                    int totalProducts = snapshot.data ?? 0;
                                    return isFetchingProducts ||
                                            isFetchingOngoingOrders
                                        ? SizedBox(
                                            height: 25,
                                            width: 25,
                                            child: CircularProgressIndicator(
                                              color: AppColors.yellow,
                                            ),
                                          )
                                        : CustomText(
                                            textLabel: '$totalProducts',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            textColor: AppColors.yellow);
                                  })
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
                                textColor: AppColors.yellow,
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
                                              color: AppColors.yellow,
                                            ),
                                          )
                                        : CustomText(
                                            textLabel: '$totalService',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            textColor: AppColors.yellow);
                                  })
                            ],
                          ),
                          Column(
                            children: [
                              CustomText(
                                textLabel: "Booked Services",
                                fontSize: 16,
                                textColor: AppColors.yellow,
                                fontWeight: FontWeight.w500,
                              ),
                              const SizedBox(height: 5),
                              StreamBuilder(
                                  stream: fetchBookings(),
                                  builder: (context, snapshot) {
                                    int totalProducts = snapshot.data ?? 0;
                                    return isFetchingProducts ||
                                            isFetchingOngoingOrders
                                        ? SizedBox(
                                            height: 25,
                                            width: 25,
                                            child: CircularProgressIndicator(
                                              color: AppColors.yellow,
                                            ),
                                          )
                                        : CustomText(
                                            textLabel: '$totalProducts',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            textColor: AppColors.yellow);
                                  })
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
                  StreamBuilder<bool>(
                    stream: getSellerApprovalStatus(userInfo?.uid),
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
                      );
                    },
                  ),
                  StreamBuilder<bool>(
                    stream: getSellerApprovalStatus(userInfo?.uid),
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
                          textColor:sellerAddButton(currentEvent),
                        ),
                      );
                    },
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
                    textColor: currentEvent == AppEvent.none ? Colors.white :AppColors.textColor,
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
                      textColor: currentEvent == AppEvent.none ? AppColors.yellow : AppColors.textColor,
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
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Center(
                      child:  CustomText(
                        textLabel: "No products found.",
                        fontSize: 16,
                        textColor: currentEvent == AppEvent.none ? Colors.white :AppColors.primary,
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
                          color: AppColors.transparentWhite,
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
                              color: AppColors.yellow,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   CustomText(
                    textLabel: "Recent Services",
                    fontSize: 18,
                    textColor: currentEvent == AppEvent.none ? Colors.white :AppColors.textColor,
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
                      textColor: currentEvent == AppEvent.none ? AppColors.yellow : AppColors.textColor,
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
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Center(
                      child:  CustomText(
                        textLabel: "No Services found.",
                        fontSize: 16,
                        textColor: currentEvent == AppEvent.none ? Colors.white :AppColors.primary,
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
                        return Card(
                          color: AppColors.transparentWhite,
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
                              color: AppColors.yellow,
                            ),
                            onTap: () {
                              navPush(context,
                                  SellerServiceDetails(serviceId: service.id));
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
                    textLabel: "Recent Orders",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    textColor: currentEvent == AppEvent.none ? Colors.white :AppColors.textColor,
                  ),
                  TextButton(
                    onPressed: () {
                      navPush(context, const SellerOrders());
                    },
                    child: CustomText(
                      textLabel: "View All",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      textColor: currentEvent == AppEvent.none ? AppColors.yellow : AppColors.textColor,
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
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return  Center(
                      child: CustomText(
                        textLabel: "No recent orders.",
                        fontSize: 16,
                        textColor: currentEvent == AppEvent.none ? Colors.white :AppColors.textColor,
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
                    textColor: currentEvent == AppEvent.none ? Colors.white :AppColors.textColor,
                  ),
                  TextButton(
                    onPressed: () {
                      navPush(context, const SellerBookings());
                    },
                    child: CustomText(
                      textLabel: "View All",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      textColor: currentEvent == AppEvent.none ? AppColors.yellow : AppColors.textColor,
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
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return  Center(
                      child: CustomText(
                        textLabel: "No recent orders.",
                        fontSize: 16,
                        textColor: currentEvent == AppEvent.none ? Colors.white :AppColors.textColor,
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
            ],
          ),
        ),
      ),
    );
  }
}
