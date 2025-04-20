import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/seller/profile.dart';
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

      // 1. Get product
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (!productDoc.exists) continue;

      final productData = productDoc.data()!;
      final sellerId = productData['sellerId'];

      // 2. Get seller
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

      // 3. Get customer (via parent of the order doc)
      final customerId = doc.reference.parent.parent?.id ?? '';
      final customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .get();

      final customerName = customerDoc.exists
          ? '${customerDoc['firstName']} ${customerDoc['lastName']}'
          : 'Unknown Customer';

      orders.add({
        'orderId': data['orderId'],
        'productId': productId,
        'productName': productData['productName'],
        'price': productData['price'],
        'pickupLocation': productData['pickupLocation'],
        'quantity': data['quantity'],
        'imageUrl': productData['imageUrl'],
        'sellerName': sellerName,
        'sellerContact': sellerContact,
        'customerName': customerName,
        'dateOrdered': data['dateOrdered'],
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
      backgroundColor: const Color.fromARGB(255, 0, 237, 118),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
              onPressed: () {
                navPush(context, const SellerProfile());
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  debugging(snapshot.error.toString());
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
                    debugging(product.toString());
                     
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
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
                                    textLabel: '₱',
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
                                    textLabel: 'category',
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
                            // navPush(context,
                            //     SellerProductDetails(productId: product.id));
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),

          ]   ),
      ),
    );
  }
}
