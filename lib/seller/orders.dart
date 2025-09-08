import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:provider/provider.dart';
import '../chat/messages.dart';
import '../components/auto_size_text.dart';
import '../components/navigator.dart';
import '../components/snackbar.dart';
import '../provider/user_provider.dart';

class SellerOrders extends StatefulWidget {
  const SellerOrders({super.key});

  @override
  State<SellerOrders> createState() => _SellerOrdersState();
}

class _SellerOrdersState extends State<SellerOrders>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _ongoingOrders = [];
  List<Map<String, dynamic>> _shippedOrders = [];
  List<Map<String, dynamic>> _finishedOrders = [];
  bool isLoading = true;
  late AppEvent currentEvent = getCurrentEvent();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

Future<void> _loadOrders() async {
  final sellerId = Provider.of<UserProvider>(context, listen: false).user?.uid;

  if (sellerId == null) {
    setState(() {
      isLoading = false;
    });
    return;
  }

  final querySnapshot = await FirebaseFirestore.instance
      .collection('orders')
      .where('sellerId', isEqualTo: sellerId)
      .get();

  if (querySnapshot.docs.isEmpty) {
    if (!mounted) return;
    setState(() {
      _ongoingOrders = [];
      _shippedOrders = [];
      _finishedOrders = [];
      isLoading = false;
    });
    return;
  }

  final productIds = querySnapshot.docs.map((d) => d['productId'] as String).toSet().toList();
  final customerIds = querySnapshot.docs.map((d) => d['customerId'] as String).toSet().toList();

  final productDocs = await FirebaseFirestore.instance
      .collection('products')
      .where(FieldPath.documentId, whereIn: productIds.length > 10 ? productIds.sublist(0, 10) : productIds)
      .get();

  final Map<String, Map<String, dynamic>> productsMap = {
    for (var doc in productDocs.docs) doc.id: doc.data()
  };

  if (productIds.length > 10) {
    for (var i = 10; i < productIds.length; i += 10) {
      final chunk = productIds.sublist(i, i + 10 > productIds.length ? productIds.length : i + 10);
      final chunkDocs = await FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in chunkDocs.docs) {
        productsMap[doc.id] = doc.data();
      }
    }
  }

  final customerDocs = await FirebaseFirestore.instance
      .collection('customers')
      .where(FieldPath.documentId, whereIn: customerIds.length > 10 ? customerIds.sublist(0, 10) : customerIds)
      .get();

  final Map<String, Map<String, dynamic>> customersMap = {
    for (var doc in customerDocs.docs) doc.id: doc.data()
  };

  if (customerIds.length > 10) {
    for (var i = 10; i < customerIds.length; i += 10) {
      final chunk = customerIds.sublist(i, i + 10 > customerIds.length ? customerIds.length : i + 10);
      final chunkDocs = await FirebaseFirestore.instance
          .collection('customers')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in chunkDocs.docs) {
        customersMap[doc.id] = doc.data();
      }
    }
  }

  final List<Map<String, dynamic>> ongoing = [];
  final List<Map<String, dynamic>> shipped = [];
  final List<Map<String, dynamic>> finished = [];

  for (var doc in querySnapshot.docs) {
    final order = doc.data();
    final productId = order['productId'];
    final customerId = order['customerId'];
    final quantity = order['quantity'] ?? 0;

    final productData = productsMap[productId] ?? {};
    final productName = productData['productName'] ?? 'Unknown';
    final price = (productData['price'] ?? 0) as num;
    final imageUrl = productData['imageUrl'] ?? '';

    final customerData = customersMap[customerId] ?? {};
    final customerName = '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'.trim();
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

    if (order['status'] == 'ordered' || order['status'] == 'packed') {
      ongoing.add(orderData);
    } else if (order['status'] == 'shipped') {
      shipped.add(orderData);
    } else {
      finished.add(orderData);
    }
  }

  if (!mounted) return;
  setState(() {
    _ongoingOrders = ongoing;
    _shippedOrders = shipped;
    _finishedOrders = finished;
    isLoading = false;
  });
}


 Future<void> markedAsPacked(String orderId) async {
  final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

  try {
    final orderSnapshot = await orderRef.get();

    if (!orderSnapshot.exists) {
       if (!mounted) return; 
      errorSnackbar(context, "Order not found.");
      return;
    }

    final orderData = orderSnapshot.data()!;
    final productId = orderData['productId'];
    final quantityOrdered = orderData['quantity'];

    final productRef =
        FirebaseFirestore.instance.collection('products').doc(productId);
    final productSnapshot = await productRef.get();

    if (productSnapshot.exists) {
      final productData = productSnapshot.data()!;
      final currentStock = productData['stock'] ?? 0;

      final newStock = (currentStock - quantityOrdered) > 0
          ? currentStock - quantityOrdered
          : 0;

      await productRef.update({'stock': newStock});
    }

    await orderRef.update({'status': 'packed'});

    if (!mounted) return;
    successSnackbar(context, "Order marked as packed and stock updated.");
    await _loadOrders();
  } catch (e) {
    if (!mounted) return;
    errorSnackbar(context, "Failed to mark as shipped: $e");
  }
}
 Future<void> unmarkAsPacked(String orderId) async {
  final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

  try {
    final orderSnapshot = await orderRef.get();

    if (!orderSnapshot.exists) {
       if (!mounted) return; 
      errorSnackbar(context, "Order not found.");
      return;
    }
    await orderRef.update({'status': 'ordered'});

    if (!mounted) return;
    successSnackbar(context, "Order unmarked as packed.");
    await _loadOrders();
  } catch (e) {
    if (!mounted) return;
    errorSnackbar(context, "Failed to mark as shipped: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        backgroundColor: currentEvent == AppEvent.none ? Colors.purple.shade900: backgroundColor(currentEvent),
        title:  CustomText(
          textLabel: 'Orders',
          fontSize: 25,
          textColor: currentEvent == AppEvent.none ? Colors.white: headerTitleColor(currentEvent),
          fontWeight: FontWeight.bold,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.yellow,
          tabs:  [
            Tab(
              child: CustomText(
                textLabel: "Ongoing",
                fontSize: 16,
                textColor: currentEvent == AppEvent.none ? Colors.white: headerTitleColor(currentEvent),
              ),
            ),
             Tab(
              child: CustomText(
                textLabel: "Shipped",
                fontSize: 16,
                textColor: currentEvent == AppEvent.none ? Colors.white: headerTitleColor(currentEvent),
              ),
            ),
            Tab(
              child: CustomText(
                textLabel: "Delivered",
                fontSize: 16,
                textColor: currentEvent == AppEvent.none ? Colors.white: headerTitleColor(currentEvent),
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Container(  decoration: BoxDecoration(
          image: DecorationImage(image: 
          AssetImage(currentEvent == AppEvent.none?wallpaper(currentEvent): backgroundImage(currentEvent)),
          fit: BoxFit.cover)
        ),

            child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
          )
          :  Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: 
          AssetImage(currentEvent == AppEvent.none?wallpaper(currentEvent): backgroundImage(currentEvent)),
          fit: BoxFit.cover)
        ),

            child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(_ongoingOrders, 'ordered'),
                  _buildOrderList(_shippedOrders, 'shipped'),
                  _buildOrderList(_finishedOrders, 'finished'),
                ],
              ),
          ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String tab) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            CustomText(
              textLabel: "No orders found.",
              fontSize: 18,
              textColor: Colors.grey,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        debugging(order.toString());
        final formattedDate = DateFormat('MM/dd/yyyy hh:mm a')
            .format(order['dateOrdered'].toDate());

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: AppColors.transparentWhite, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    order['imageUrl'] ?? '',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 60,
                      width: 60,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        textLabel: order['productName'] ?? 'Unnamed Product',
                        fontSize: 16,
                        maxLines: 2,
                        fontWeight: FontWeight.bold,
                        textColor: currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Quantity: ${order['quantity']}',
                        fontSize: 14,
                        textColor:  currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Customer: ${order['customerName']}',
                        fontSize: 14,
                        textColor:  currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel:
                            'Amount: ₱${order['amount'].toStringAsFixed(2)}',
                        fontSize: 14,
                        textColor:  currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel:
                            'Contact: ${order['customerContact'] ?? 'N/A'}',
                        fontSize: 14,
                        textColor:  currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Date Ordered: $formattedDate',
                        fontSize: 14,
                        textColor: currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (tab == 'ordered')
                            Align(
                              alignment: Alignment.centerRight,
                              child: order['status'] == 'ordered' ? TextButton(
                                onPressed: () => markedAsPacked(
                                  order['orderId'].toString(),
                                  
                                ),
                                child: const CustomText(
                                  textLabel: "Mark as Packed",
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  textColor: Colors.green,
                                ),
                              ) : TextButton(
                                onPressed: () => unmarkAsPacked(
                                  order['orderId'].toString(),
                                  
                                ),
                                child: const CustomText(
                                  textLabel: "Unmark as Packed",
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  textColor: Colors.yellow,
                                )),
                            ),
                            Row(
                              children: [
                              if(order['status'] == 'delivered')   IconButton(
            icon:  Icon(Icons.image, color: AppColors.yellow),
            onPressed: () async {
              final orderId = order['orderId'];

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
                                IconButton(
                                icon:
                                    const Icon(Icons.message, color: Colors.green),
                                onPressed: () {
                                  navigateToMessages(
                                    order['customerId'],
                                    order['customerName'],
                                    order['customerProfilePic'],
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
              ],
            ),
          ),
        );
      },
    );
  }

  void navigateToMessages(
      String customerId, String customerName, String customerProfilePic) {
    final sellerId =
        Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (sellerId == null) {
      errorSnackbar(context, "You must be logged in to message the customer.");
      return;
    }

    navPush(
      context,
      UserMessages(
        userId: sellerId,
        receiverUserId: customerId,
        receiverFirstName: customerName.split(' ').first,
        receiverProfilePic: customerProfilePic,
      ),
    );
  }
}
