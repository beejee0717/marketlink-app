import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/appbar.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
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

class _RiderDeliveriesState extends State<RiderDeliveries> {
  late Stream<List<Map<String, dynamic>>> productsStream;
  bool productsStrInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    final riderId = userInfo?.uid ?? "";

    if (!productsStrInitialized) {
      productsStream = fetchAvailableOrders(riderId);
      productsStrInitialized = true;
    }
  }

  Stream<List<Map<String, dynamic>>> fetchAvailableOrders(String riderId) {
    return FirebaseFirestore.instance
        .collection('riders')
        .doc(riderId)
        .collection('deliveries')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: appbar(context, destination: RiderProfile()),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: CustomText(textLabel: 'Products to Deliver', fontSize: 18,fontWeight: FontWeight.bold,),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
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
                } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(
                    child: CustomText(
                      textLabel: "No Deliveries Available.",
                      fontSize: 16,
                      textColor: Colors.black,
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final product = snapshot.data![index];
                        return GestureDetector(
                          onTap: () {
                            navPush(
                              context,
                              DeliveryDetails(data: product, isDelivery: true,),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  color: Colors.black87),
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
                                              fontSize: 14, color: Colors.black87),
                                        ),
                                        Text(
                                          product['pickupLocation'] ?? 'N/A',
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
                    ),
                  );
                }
              },
            ),
          ],
        ));
  }
}
