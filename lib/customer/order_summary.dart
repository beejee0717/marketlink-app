import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/chat/messages.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import '../components/auto_size_text.dart';
import '../components/navigator.dart';

class OrderSummary extends StatefulWidget {
  final String orderId;

  const OrderSummary({super.key, required this.orderId});

  @override
  State<OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends State<OrderSummary> {
  bool _isLoading = true;

  Map<String, dynamic>? orderData;
  Map<String, dynamic>? sellerData;
  Map<String, dynamic>? productData;
  Map<String, dynamic>? riderData;
  Map<String, dynamic>? customerData;

  int quantity = 1;
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    fetchAllDetails();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool isEditingAddress = false;
  bool isAddressValid = true;
  String? userId;

  Future<void> fetchAllDetails() async {
    try {
      userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!orderSnapshot.exists) {
        debugging("Order not found");
        setState(() => _isLoading = false);
        return;
      }

      orderData = orderSnapshot.data();
      debugging("Order Data: $orderData");

      final sellerId = orderData?['sellerId'];
      final productId = orderData?['productId'];
      final riderId = orderData?['riderId'];

      totalPrice = (orderData?['price'] ?? 0).toDouble() *
          (orderData?['quantity'] ?? 0).toDouble();

//getting seller data
      if (sellerId != null) {
        final sellerSnapshot = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(sellerId)
            .get();
        sellerData = sellerSnapshot.data();
      }
      //product data
      if (productId != null) {
        final productSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        productData = productSnapshot.data();
      }
      //rider data
      if (riderId != null) {
        final riderSnapshot = await FirebaseFirestore.instance
            .collection('riders')
            .doc(riderId)
            .get();
        riderData = riderSnapshot.data();
      }
//user data
      if (userId != null) {
        final customerSnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .doc(userId)
            .get();

        customerData = customerSnapshot.data();

        String? address = customerData?['address'];

        isAddressValid = (address != null && address.trim().isNotEmpty);
      }
    } catch (e) {
      debugging("Error fetching data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void updateTotalPrice() {
    double unitPrice = (orderData?['price'] ?? 0).toDouble();
    setState(() {
      totalPrice = unitPrice * quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => navPop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0,
        title: const CustomText(
          textLabel: 'Order Summary',
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (productData?['imageUrl'] != null)
                      Center(
                        child: Image.network(
                          productData!['imageUrl'],
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    CustomText(
                      textLabel:
                          '${productData?['productName'] ?? 'No Product Name'}',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 16),
                     Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Row(
                          children: [
                            const CustomText(
                                textLabel: 'Order Status: ', fontSize: 18),
                            CustomText(
                              textLabel: '${orderData?['status'][0].toUpperCase()}${orderData?['status'].substring(1)}',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              textColor: AppColors.appGreen,
                            ),
                          ],
                                             ),  if(orderData?['status'] == 'delivered')   IconButton(
            icon: const Icon(Icons.image, color: AppColors.goldenYellow),
            onPressed: () async {
              final orderId = orderData?['orderId'];

              DocumentSnapshot<Map<String, dynamic>> snapshot =
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .get();

              final deliveryData = snapshot.data();

              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delivery Proof'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (deliveryData?['deliveryProof'] != null)
                          Image.network(
                            deliveryData!['deliveryProof'],
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                    ? child
                                    : const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(),
                                      ),
                            errorBuilder: (context, error, stackTrace) =>
                                const Text('Failed to load image'),
                          )
                        else
                          const Text('No delivery proof available'),
                        const SizedBox(height: 16),
                        if (deliveryData?['deliveryTimestamp'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Date & Time:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DateFormat('MMMM d, y – h:mm:ss a').format(
                                  (deliveryData!['deliveryTimestamp']
                                          as Timestamp)
                                      .toDate(),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            },
          )
      ,
                       ],
                     ), 
                    Row(
                      children: [
                        const CustomText(
                            textLabel: 'Unit Price: ', fontSize: 18),
                        CustomText(
                          textLabel: '₱${orderData?['price'] ?? 'No Price'}',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const CustomText(textLabel: 'Quantity: ', fontSize: 18),
                        CustomText(
                          textLabel:
                              '${orderData?['quantity'] ?? 'No Quantity'}',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const CustomText(textLabel: 'Total: ', fontSize: 18),
                        CustomText(
                          textLabel: '₱${(totalPrice).toStringAsFixed(2)}',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        const CustomText(
                          textLabel: "Payment Method",
                          fontSize: 16,
                        ),
                        SizedBox(height: 10),
                        const CustomText(
                          textLabel: "Cash on Delivery",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        const CustomText(
                          textLabel: "Delivery Address",
                          fontSize: 16,
                        ),
                        const SizedBox(height: 10),
                        CustomText(
                          textLabel: '${orderData?['deliveryAddress']}',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(height: 10),
                    Divider(
                      color: AppColors.grey,
                      thickness: 2,
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CustomText(
                                textLabel: 'Seller Name: ', fontSize: 16),
                            CustomText(
                              textLabel:
                                  '${sellerData?['firstName']} ${sellerData?['lastName']}',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            navigateToMessageSeller(
                              orderData?['sellerId'],
                              sellerData?['firstName'],
                              sellerData?['profilePicture'] ?? '',
                            );
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.message,
                                color: AppColors.purple,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        CustomText(
                            textLabel: 'Seller Contact Number: ', fontSize: 16),
                        CustomText(
                          textLabel:
                              '${sellerData?['contactNumber'] ?? 'No Contact Number'} ',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (orderData?['hasRider'] == true) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const CustomText(
                                      textLabel: 'Rider Name: ', fontSize: 16),
                                  CustomText(
                                    textLabel:
                                        '${riderData?['firstName']} ${riderData?['lastName']}',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  navigateToMessageSeller(
                                    orderData?['riderId'],
                                    riderData?['firstName'],
                                    riderData?['profilePicture'] ?? '',
                                  );
                                },
                                child: Row(
                                  children: const [
                                    Icon(Icons.message,
                                        color: AppColors.purple),
                                    SizedBox(width: 5),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const CustomText(
                                  textLabel: 'Rider Contact Number: ',
                                  fontSize: 16),
                              CustomText(
                                textLabel:
                                    '${riderData?['contactNumber'] ?? 'No Contact Number'} ',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void navigateToMessageSeller(
      String sellerId, String sellerFirstName, String sellerProfilePic) {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      errorSnackbar(context, "You must be logged in to message the seller.");
      return;
    }

    navPush(
      context,
      UserMessages(
        userId: userId,
        receiverUserId: sellerId,
        receiverFirstName: sellerFirstName,
        receiverProfilePic: sellerProfilePic,
      ),
    );
  }
}
