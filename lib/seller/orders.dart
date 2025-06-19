import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  final List<Map<String, dynamic>> ongoing = [];
  final List<Map<String, dynamic>> shipped = [];
  final List<Map<String, dynamic>> finished = [];

  for (var doc in querySnapshot.docs) {
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
    final customerName = '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'.trim();
    final customerContact = customerData['contactNumber'] ?? 'N/A';
    final customerProfilePic = customerData['profilePicture'] ?? '';

    final amount = price * quantity;

    final orderData = {
      'orderId':doc.id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'customerId': customerId,
      'customerName': customerName,
      'dateOrdered': order['dateOrdered'],
      'status': order['status'],
      'customerProfilePic': customerProfilePic,
      'imageUrl': imageUrl,
      'customerContact': customerContact,
      'amount': amount,
    };

    if (order['status'] == 'ordered') {
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


 Future<void> markedAsShipped(String orderId) async {
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

    await orderRef.update({'status': 'shipped'});

    if (!mounted) return;
    successSnackbar(context, "Order marked as shipped and stock updated.");
    await _loadOrders();
  } catch (e) {
    if (!mounted) return;
    errorSnackbar(context, "Failed to mark as shipped: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      appBar: AppBar(
        backgroundColor: Colors.purple.shade900,
        title: const CustomText(
          textLabel: 'Orders',
          fontSize: 25,
          textColor: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(
              child: CustomText(
                textLabel: "Ongoing",
                fontSize: 16,
                textColor: Colors.white,
              ),
            ),
             Tab(
              child: CustomText(
                textLabel: "Shipped",
                fontSize: 16,
                textColor: Colors.white,
              ),
            ),
            Tab(
              child: CustomText(
                textLabel: "Delivered",
                fontSize: 16,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_ongoingOrders, 'ordered'),
                _buildOrderList(_shippedOrders, 'shipped'),
                _buildOrderList(_finishedOrders, 'finished'),
              ],
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
        final formattedDate = DateFormat('MM/dd/yyyy hh:mm a')
            .format(order['dateOrdered'].toDate());

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.white.withOpacity(0.1), 
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
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Quantity: ${order['quantity']}',
                        fontSize: 14,
                        textColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Customer: ${order['customerName']}',
                        fontSize: 14,
                        textColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel:
                            'Amount: ₱${order['amount'].toStringAsFixed(2)}',
                        fontSize: 14,
                        textColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel:
                            'Contact: ${order['customerContact'] ?? 'N/A'}',
                        fontSize: 14,
                        textColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Date Ordered: $formattedDate',
                        fontSize: 14,
                        textColor: Colors.grey.shade300,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (tab == 'ordered')
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => markedAsShipped(
                                  order['orderId'].toString(),
                                  
                                ),
                                child: const CustomText(
                                  textLabel: "Mark as Shipped",
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  textColor: Colors.green,
                                ),
                              ),
                            ),
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
