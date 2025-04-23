import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/rider/delivery_details.dart';
import 'package:marketlinkapp/rider/profile.dart';
import 'package:provider/provider.dart';
import '../components/snackbar.dart';
import '../provider/user_provider.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  late Stream<List<Map<String, dynamic>>> productsStream;

  bool productsStrInitialized = false;
  bool isFetchingProducts = true;
  bool isFetchingServices = true;
  bool isFetchingOngoingOrders = true;
  bool isFetchingBookings = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userInfo = Provider.of<UserProvider>(context, listen: false).user;

    if (!productsStrInitialized) {
      productsStream = fetchAvailableOrders();
      productsStrInitialized = true;
    }
  }

  Stream<List<Map<String, dynamic>>> fetchAvailableOrders() {
    return FirebaseFirestore.instance
        .collectionGroup('orders')
        .where('hasRider', isEqualTo: false)
        .orderBy('dateOrdered', descending: true)
        .limit(3)
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<Map<String, dynamic>> orders = [];

    

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final productId = data['productId'];

//product data
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (!productDoc.exists) continue;

        final productData = productDoc.data()!;
        final sellerId = productData['sellerId'];
//seller data
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(sellerId)
            .get();

        final sellerName = sellerDoc.exists
            ? '${sellerDoc['firstName']} ${sellerDoc['lastName']}'
            : 'Unknown Seller';

        final sellerContact = sellerDoc.exists &&
                sellerDoc.data()!.containsKey('contactNumber') &&
                (sellerDoc['contactNumber']?.isNotEmpty ?? false)
            ? sellerDoc['contactNumber']
            : 'No Contact No.';
//customer data
        final customerId = doc.reference.parent.parent?.id ?? '';
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(customerId)
            .get();

        final customerName = customerDoc.exists
            ? '${customerDoc['firstName']} ${customerDoc['lastName']}'
            : 'Unknown Customer';
        final customerAddress =
            customerDoc.exists ? customerDoc['address'] : 'Unknown Location';
        final customerContact =
            customerDoc.exists ? customerDoc['contactNumber'] : 'No Number';

        orders.add({
          'orderId': data['orderId'],
          'productId': productId,
          'productName': productData['productName'],
          'price': productData['price'],
          'quantity': data['quantity'],
          'imageUrl': productData['imageUrl'],
          'customerAddress': customerAddress,
          'customerId': customerId,
          'customerName': customerName,
          'dateOrdered': data['dateOrdered'],
          'customerContact': customerContact,
          'sellerName': sellerName,
          'sellerContact': sellerContact,
          'pickupLocation': productData['pickupLocation'],
        });
      }

      return orders;
    });
  }

  Stream<bool> getRiderApprovalStatus(String riderId) {
    return FirebaseFirestore.instance
        .collection('riders')
        .doc(riderId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['approved'] == true);
  }
// this is the rider home, my idea as of now is show available products that can be delivered

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
              onPressed: () {
                navPush(context, const RiderProfile());
              },
              icon: Icon(
                Icons.person,
                color: Colors.black,
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
            const CustomText(
              textLabel: 'Market Link',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              textColor: Colors.black,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                
                return Center(
                  child: const CustomText(
                    textLabel: "No Orders Available.",
                    fontSize: 16,
                    textColor: Colors.black,
                  ),
                );
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final product = snapshot.data![index];
debugging(snapshot.data!.length.toString());
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: product['imageUrl'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product['imageUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.grey,
                              ),
                        title: CustomText(
                          textLabel: product['productName'],
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
                                  textLabel: '₱${product['price']}',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  textColor: Colors.orange,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                CustomText(
                                  textLabel: "Pickup Address: ",
                                  fontSize: 14,
                                  textColor: Colors.black87,
                                ),
                                CustomText(
                                  textLabel: product['pickupLocation'],
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                CustomText(
                                  textLabel: "Delivery Address: ",
                                  fontSize: 14,
                                  textColor: Colors.black87,
                                ),
                                CustomText(
                                  textLabel: product['customerAddress'],
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
                          navPush(
                              context,
                              DeliveryDetails(
                                data: product,
                              ));
                        },
                      ),
                    );
                  },
                );
              }
            },
          ),
        ]),
      ),
    );
  }
}
