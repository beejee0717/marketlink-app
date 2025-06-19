import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/appbar.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/rider/delivery_details.dart';
import 'package:marketlinkapp/rider/profile.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  late Stream<List<Map<String, dynamic>>> productsStream;
  bool productsStrInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!productsStrInitialized) {
      productsStream = fetchAvailableOrders();
      productsStrInitialized = true;
    }
  }

  Stream<bool> getRiderApprovalStatus(String? riderId) {
    return FirebaseFirestore.instance
        .collection('riders')
        .doc(riderId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['approved'] == true);
  }

  Stream<List<Map<String, dynamic>>> fetchAvailableOrders() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('hasRider', isEqualTo: false)
        .orderBy('dateOrdered', descending: true)
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<Map<String, dynamic>> orders = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final productId = data['productId'];
        final customerId = data['customerId'];

        if (productId == null || customerId == null) continue;

        // Fetch product data
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (!productDoc.exists) continue;
        final productData = productDoc.data();
        if (productData == null) continue;

        final sellerId = productData['sellerId'];
        String sellerName = 'Unknown Seller';
        String sellerContact = 'No Contact No.';

        if (sellerId != null) {
          final sellerDoc = await FirebaseFirestore.instance
              .collection('sellers')
              .doc(sellerId)
              .get();
          final sellerData = sellerDoc.data();
          if (sellerData != null) {
            sellerName =
                '${sellerData['firstName'] ?? ''} ${sellerData['lastName'] ?? ''}'
                    .trim();
            sellerContact = sellerData['contactNumber'] ?? 'No Contact No.';
          }
        }

        // Fetch customer data
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(customerId)
            .get();
        final customerData = customerDoc.data();

        final customerName = customerData != null
            ? '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'
                .trim()
            : 'Unknown Customer';

        final customerAddress = customerData != null &&
                (customerData['address']?.toString().isNotEmpty ?? false)
            ? customerData['address']
            : 'Unknown Location';

        final customerContact = customerData != null &&
                (customerData['contactNumber']?.toString().isNotEmpty ?? false)
            ? customerData['contactNumber']
            : 'No Contact No.';

        final unitPrice = data['price'] ?? 0;
        final quantity = data['quantity'] ?? 1;
        final totalPrice = unitPrice * quantity;
        orders.add({
          'orderId': data['orderId'],
          'productId': productId,
          'productName': productData['productName'],
          'price': totalPrice,
          'quantity': quantity,
          'imageUrl': productData['imageUrl'],
          'customerAddress': customerAddress,
          'customerId': customerId,
          'customerName': customerName,
          'dateOrdered': data['dateOrdered'],
          'customerContact': customerContact,
          'sellerName': sellerName,
          'sellerContact': sellerContact,
          'pickupLocation': productData['pickupLocation'],
          'isDelivered': false,
        });
      }

      return orders;
    });
  }

// this is the rider home, my idea as of now is show available products that can be delivered

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: appbar(context, destination: RiderProfile()),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: CustomText(
                textLabel: 'Products Available to Deliver',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              // This makes the list scrollable and avoids pixel overflow
              child: StreamBuilder<bool>(
                stream: getRiderApprovalStatus(userInfo?.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  bool isApproved = snapshot.data ?? false;

                  if (!isApproved) {
                    return Center(
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
                              "Rider not approved yet. Please wait for the Admin to approve before you can deliver products.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: productsStream,
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
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return const Center(
                          child: CustomText(
                            textLabel: "No Orders Available.",
                            fontSize: 16,
                            textColor: Colors.black,
                          ),
                        );
                      } else {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final product = snapshot.data![index];
                            return GestureDetector(
                              onTap: () {
                                navPush(
                                  context,
                                  DeliveryDetails(
                                      data: product, isDelivery: false),
                                );
                              },
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: product['imageUrl'] != null
                                            ? Image.network(
                                                product['imageUrl'],
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                Icons.image,
                                                size: 100,
                                                color: Colors.grey,
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['productName'] ??
                                                  'No Product Name',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Text(
                                                  "Price: ",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                Text(
                                                  '₱${product['price'] ?? '0'}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              "Pickup Address:",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              product['pickupLocation'] ??
                                                  'N/A',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              softWrap: true,
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              "Delivery Address:",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              product['customerAddress'] ??
                                                  'No Customer Address',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              softWrap: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.yellow.shade800,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ));
  }
}
