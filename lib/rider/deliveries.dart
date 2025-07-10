import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/appbar.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:marketlinkapp/rider/delivery_details.dart';
import 'package:marketlinkapp/rider/profile.dart';
import 'package:provider/provider.dart';

class RiderDeliveries extends StatefulWidget {
  const RiderDeliveries({super.key});

  @override
  State<RiderDeliveries> createState() => _RiderDeliveriesState();
}

class _RiderDeliveriesState extends State<RiderDeliveries>
    with TickerProviderStateMixin {
  late Stream<List<Map<String, dynamic>>> productsStream;
  late TabController _tabController;
 @override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
}



Stream<List<Map<String, dynamic>>> streamDeliveries(bool isDelivered) {
  final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

  if (userId == null) {
    return const Stream.empty();
  }

  final statusToMatch = isDelivered ? 'delivered' : 'shipped';

  return FirebaseFirestore.instance
      .collection('orders')
      .where('riderId', isEqualTo: userId)
      .where('status', isEqualTo: statusToMatch)
      .snapshots()
      .asyncMap((snapshot) async {
    List<Map<String, dynamic>> deliveries = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final productId = data['productId'];
      final customerId = data['customerId'];
      final orderId = data['orderId'];

      if (productId == null || customerId == null) continue;

      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
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
          : 'Unknown Address';

      final customerContact = customerData != null &&
              (customerData['contactNumber']?.toString().isNotEmpty ?? false)
          ? customerData['contactNumber']
          : 'No Contact No.';

      final unitPrice = data['price'] ?? 0;
      final quantity = data['quantity'] ?? 1;
      final totalPrice = unitPrice * quantity;

      deliveries.add({
        'orderId': orderId,
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
        'isDelivered': isDelivered,
      });
    }

    return deliveries;
  });
}


  Widget buildDeliveryList(List<Map<String, dynamic>> deliveries) {
    return deliveries.isEmpty
        ? Center(
            child: CustomText(
              textLabel: "No Deliveries Available.",
              fontSize: 16,
              textColor: Colors.black,
            ),
          )
        : ListView.builder(
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return GestureDetector(
                onTap: () {
                  navPush(
                    context,
                    DeliveryDetails(
                      data: delivery,
                      isDelivery: true,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: delivery['imageUrl'] != null
                                ? Image.network(
                                    delivery['imageUrl'],
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  delivery['productName'] ?? 'No Product Name',
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
                                          fontSize: 14, color: Colors.black87),
                                    ),
                                    Text(
                                      '₱${delivery['price'] ?? '0'}',
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
                                      fontSize: 14, color: Colors.black87),
                                ),
                                Text(
                                  delivery['pickupLocation'] ?? 'N/A',
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
                                      fontSize: 14, color: Colors.black87),
                                ),
                                Text(
                                  delivery['customerAddress'] ??
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
                ),
              );
            });
  }

  @override
  Widget build(BuildContext context) {
    // debugging(_deliveries.toString());
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: appbar(context, destination: RiderProfile()),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Picked Up'),
                Tab(text: 'Delivered'),
              ],
            ),
            Expanded(
              child: TabBarView(
  controller: _tabController,
  children: [
    StreamBuilder<List<Map<String, dynamic>>>(
      stream: streamDeliveries(false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitFadingCircle(
              size: 80,
              color: AppColors.primary,
            ),
          );
        } else if (snapshot.hasError) {
          return const Center(
            child: Text("Error loading deliveries."),
          );
        } else {
          final deliveries = snapshot.data ?? [];
          return buildDeliveryList(deliveries);
        }
      },
    ),
    StreamBuilder<List<Map<String, dynamic>>>(
      stream: streamDeliveries(true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitFadingCircle(
              size: 80,
              color: AppColors.primary,
            ),
          );
        } else if (snapshot.hasError) {
          return const Center(
            child: Text("Error loading deliveries."),
          );
        } else {
          final deliveries = snapshot.data ?? [];
          return buildDeliveryList(deliveries);
        }
      },
    ),
  ],
),

            ),
          ],
        ));
  }
}
