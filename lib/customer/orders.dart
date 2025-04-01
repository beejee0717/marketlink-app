import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:provider/provider.dart';
import '../components/auto_size_text.dart';
import '../components/snackbar.dart';
import '../provider/user_provider.dart';

class CustomerOrders extends StatefulWidget {
  const CustomerOrders({super.key});

  @override
  State<CustomerOrders> createState() => _CustomerOrdersState();
}

class _CustomerOrdersState extends State<CustomerOrders>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _packedOrders = [];
  List<Map<String, dynamic>> _shippedOrders = [];
  List<Map<String, dynamic>> _deliveredOrders = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final packedOrders = await fetchOrders(userId, status: 'ordered');
    final shippedOrders = await fetchOrders(userId, status: 'shipped');
    final deliveredOrders = await fetchOrders(userId, status: 'delivered');
    if (!mounted) return;
    setState(() {
      _packedOrders = packedOrders;
      _shippedOrders = shippedOrders;
      _deliveredOrders = deliveredOrders;
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchOrders(String userId,
      {required String status}) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('orders')
        .where('status', isEqualTo: status)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> orders = [];
    for (var doc in querySnapshot.docs) {
      final productId = doc.id;
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (productDoc.exists) {
        final productData = productDoc.data()!;
        final sellerId = productData['sellerId'];

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

        orders.add({
          'productId': productId,
          'productName': productData['productName'],
          'price': productData['price'],
          'pickupLocation': productData['pickupLocation'],
          'quantity': doc['quantity'],
          'imageUrl': productData['imageUrl'],
          'sellerName': sellerName,
          'sellerContact': sellerContact
        });
      }
    }
    return orders;
  }

  Future<void> cancelOrder(String userId, String productId) async {
    final productOrderRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('orders')
        .doc(userId);

    final customerOrderRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('orders')
        .doc(productId);

    await Future.wait([productOrderRef.delete(), customerOrderRef.delete()]);

    setState(() {
      _packedOrders.removeWhere((order) => order['productId'] == productId);
    });
    if (!mounted) return;
    successSnackbar(context, "Order canceled successfully.");
  }

  Widget _buildOrderList(
      List<Map<String, dynamic>> orders, String type) {
    return orders.isEmpty
        ? Center(
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
          )
        : ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final totalPrice =
                  (order['price'] ?? 0) * (order['quantity'] ?? 1);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order['imageUrl'] ?? '',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, size: 40),
                    ),
                  ),
                  title: CustomText(
                    textLabel: order['productName'] ?? 'Unnamed Product',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        textLabel:
                            '₱${totalPrice.toStringAsFixed(2)} (x${order['quantity']})',
                        fontSize: 16,
                        textColor: Colors.green,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          CustomText(
                            textLabel: 'Pickup: ',
                            fontSize: 14,
                            textColor: Colors.grey,
                          ),
                          SizedBox(width: 5),
                          CustomText(
                            textLabel:
                                order['pickupLocation'] ?? 'Not specified',
                            fontSize: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          CustomText(
                            textLabel: 'Seller: ',
                            fontSize: 14,
                            textColor: Colors.grey,
                          ),
                          SizedBox(width: 5),
                          CustomText(
                            textLabel: order['sellerName'],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      CustomText(
                        textLabel: order['sellerContact'] ?? 'No Contact No.',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                  trailing: type != 'delivered'
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            customDialog(
                                context,
                                order['productName'] ?? 'Unnamed Product',
                                'Cancel this order?', () {
                              cancelOrder(
                                  Provider.of<UserProvider>(context,
                                          listen: false)
                                      .user!
                                      .uid,
                                  order['productId']);
                              if (Navigator.canPop(context)) {
                                navPop(context);
                              }
                            });
                          },
                        )
                      : null,
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const CustomText(textLabel: 'Orders', fontSize: 25),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: CustomText(
            textLabel: 'You must be logged in to view your orders.',
            fontSize: 16,
            textColor: Colors.red,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(textLabel: 'Orders', fontSize: 25),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Packed'),
             Tab(text: 'Shipped'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: SpinKitFadingCircle(
                size: 80,
                color: Colors.green,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_packedOrders, 'packed'),
                _buildOrderList(_shippedOrders, 'shipped'),
                _buildOrderList(_deliveredOrders, 'delivered'),
              ],
            ),
    );
  }
}
