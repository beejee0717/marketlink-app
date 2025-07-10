import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/customer/order_summary.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
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
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _deliveredOrders = [];
  List<Map<String, dynamic>> _bookedServices = [];
  late AppEvent currentEvent = getCurrentEvent();
  bool ordersLoading = true;
  bool bookingsLoading = true;
  double shippingFee = 25.00;

  late TabController _tabController;
  late TabController _categoryController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _categoryController = TabController(length: 2, vsync: this);
    _loadOrders();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;
    

    if (userId == null) {
      setState(() {
        bookingsLoading = false;
      });
      return;
    }

    final bookedServices = await fetchBooking(userId);

    if (!mounted) return;
    setState(() {
      _bookedServices = bookedServices;
      bookingsLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchBooking(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: userId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> bookings = [];

    for (var doc in querySnapshot.docs) {
      final bookingData = doc.data();
      final serviceId = bookingData['serviceId'];
      final sellerId = bookingData['sellerId'];

      final serviceDoc = await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .get();

      if (!serviceDoc.exists) continue;

      final serviceData = serviceDoc.data()!;

      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .get();

      final sellerName = sellerDoc.exists
          ? '${sellerDoc['firstName']} ${sellerDoc['lastName']}'
          : 'Unknown Seller';

      final sellerContact = sellerDoc.exists &&
              sellerDoc.data()!.containsKey('contactNumber') &&
              (sellerDoc['contactNumber']?.toString().isNotEmpty ?? false)
          ? sellerDoc['contactNumber']
          : 'No Contact No.';

      bookings.add({
        'serviceId': serviceId,
        'serviceName': serviceData['serviceName'],
        'price': serviceData['price'],
        'serviceLocation': serviceData['serviceLocation'],
        'dateBooked': bookingData['dateBooked'],
        'status': bookingData['status'],
        'imageUrl': serviceData['imageUrl'],
        'sellerName': sellerName,
        'sellerContact': sellerContact,
      });
    }

    return bookings;
  }

  Future<void> _loadOrders() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      setState(() {
        ordersLoading = false;
      });
      return;
    }

    final activeOrders = await fetchActiveOrders(userId);
    final deliveredOrders = await fetchDeliveredOrders(userId);

    if (!mounted) return;
    setState(() {
      _activeOrders = activeOrders;
      _deliveredOrders = deliveredOrders;
      ordersLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchDeliveredOrders(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .where('status', isEqualTo: 'delivered')
        .get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> orders = [];

    for (var doc in querySnapshot.docs) {
      final orderData = doc.data();
      final productId = orderData['productId'];
      final sellerId = orderData['sellerId'];

      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (!productDoc.exists) continue;

      final productData = productDoc.data()!;

      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .get();

      final sellerName = sellerDoc.exists
          ? '${sellerDoc['firstName']} ${sellerDoc['lastName']}'
          : 'Unknown Seller';

      final sellerContact = sellerDoc.exists &&
              sellerDoc.data()!.containsKey('contactNumber') &&
              (sellerDoc['contactNumber']?.toString().isNotEmpty ?? false)
          ? sellerDoc['contactNumber']
          : 'No Contact No.';

      orders.add({
        'productId': productId,
        'orderId': orderData['orderId'],
        'productName': productData['productName'],
        'price': productData['price'],
        'pickupLocation': productData['pickupLocation'],
        'quantity': orderData['quantity'],
        'imageUrl': productData['imageUrl'],
        'status': orderData['status'],
        'sellerName': sellerName,
        'sellerContact': sellerContact,
           'totalPayment':orderData['totalPayment'],
      });
    }

    return orders;
  }

  Future<List<Map<String, dynamic>>> fetchActiveOrders(String userId) async {
    final allUserOrders = await FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .get();

    final activeOrdersRaw = allUserOrders.docs.where((doc) {
      final status = doc['status']?.toString().toLowerCase() ?? '';
      return status != 'delivered';
    }).toList();

    List<Map<String, dynamic>> orders = [];

    for (var doc in activeOrdersRaw) {
      final orderData = doc.data();
      final productId = orderData['productId'];
      final sellerId = orderData['sellerId'];

      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (!productDoc.exists) continue;
      final productData = productDoc.data()!;

      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .get();

      final sellerName = sellerDoc.exists
          ? '${sellerDoc['firstName']} ${sellerDoc['lastName']}'
          : 'Unknown Seller';

      final sellerContact = sellerDoc.exists &&
              sellerDoc.data()!.containsKey('contactNumber') &&
              (sellerDoc['contactNumber']?.toString().isNotEmpty ?? false)
          ? sellerDoc['contactNumber']
          : 'No Contact No.';

      orders.add({
        'productId': productId,
        'orderId': orderData['orderId'],
        'productName': productData['productName'],
        'price': productData['price'],
        'pickupLocation': productData['pickupLocation'],
        'quantity': orderData['quantity'],
        'imageUrl': productData['imageUrl'],
        'sellerName': sellerName,
        'sellerContact': sellerContact,
        'totalPayment':orderData['totalPayment'],
        'status': orderData['status'],
      });
    }

    return orders;
  }

  Future<void> cancelOrder(
      String userId, String productId, String orderId) async {
    final productOrderRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('orders')
        .doc(orderId);

    final customerOrderRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('orders')
        .doc(orderId);

    await Future.wait([productOrderRef.delete(), customerOrderRef.delete()]);

    setState(() {
      _activeOrders.removeWhere((order) => order['productId'] == productId);
    });
    if (!mounted) return;
    successSnackbar(context, "Order canceled successfully.");
  }

  Future<void> cancelBooking(String userId, String serviceId) async {
    final productOrderRef = FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .collection('bookings')
        .doc(userId);

    final customerOrderRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('bookings')
        .doc(serviceId);

    await Future.wait([productOrderRef.delete(), customerOrderRef.delete()]);

    setState(() {
      _bookedServices.removeWhere((order) => order['serviceId'] == serviceId);
    });
    if (!mounted) return;
    successSnackbar(context, "Booking canceled successfully.");
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String type) {
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
                  order['totalPayment'] ?? 0 ;
              return Card(
                color: const Color.fromARGB(158, 255, 255, 255),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: GestureDetector(
                  onTap: (){
                   navPush(context, OrderSummary(orderId: order['orderId']));
                  },
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
                          textLabel: '₱${totalPrice.toStringAsFixed(2)}',
                          fontSize: 16,
                          textColor: AppColors.primary,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              textLabel: 'Status: ',
                              fontSize: 14,
                              textColor: Colors.grey,
                            ),
                            SizedBox(width: 5),
                            CustomText(
                              textLabel:
                                  '${order['status'][0].toUpperCase()}${order['status'].substring(1)}',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textColor: AppColors.appGreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  trailing: order['status'] == 'shipped'
    ? null
    : type == 'delivered'
        ? IconButton(
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
        : IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () {
              customDialog(
                  context,
                  order['productName'] ?? 'Unnamed Product',
                  'Cancel this order?', () {
                cancelOrder(
                  Provider.of<UserProvider>(context, listen: false).user!.uid,
                  order['productId'],
                  order['orderId'],
                );
                if (Navigator.canPop(context)) {
                  navPop(context);
                }
              });
            },
          ),
  ),
                ),
              );
            },
          );
  }

  Widget _buildBookedList(List<Map<String, dynamic>> bookings) {
    return bookings.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 10),
                CustomText(
                  textLabel: "No Bookings found.",
                  fontSize: 18,
                  textColor: Colors.grey,
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                color: const Color.fromARGB(164, 255, 255, 255),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          booking['imageUrl'] ?? '',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image, size: 40),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              textLabel:
                                  booking['serviceName'] ?? 'Unnamed Service',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              textLabel:
                                  '₱${booking['price'].toStringAsFixed(2)}',
                              fontSize: 16,
                              textColor: AppColors.primary,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomText(
                                  textLabel: 'Status: ',
                                  fontSize: 14,
                                  textColor: Colors.grey,
                                ),
                                Flexible(
                                  child: CustomText(
                                    textLabel: booking['status'] == 'pending'
                                        ? 'Pending'
                                        : 'Confirmed',
                                    fontSize: 14,
                                    textColor: booking['status'] == 'pending'
                                        ? const Color.fromARGB(255, 255, 167, 4)
                                        : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomText(
                                  textLabel: 'Service Location: ',
                                  fontSize: 14,
                                  textColor: Colors.grey,
                                ),
                                Flexible(
                                  child: CustomText(
                                    textLabel: booking['serviceLocation'] ??
                                        'Not specified',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomText(
                                  textLabel: 'Date: ',
                                  fontSize: 14,
                                  textColor: Colors.grey,
                                ),
                                Flexible(
                                  child: CustomText(
                                    textLabel: booking['dateBooked'] != null
                                        ? '${DateFormat('yyyy-MM-dd').format(booking['dateBooked'].toDate())} ${DateFormat('hh:mm a').format(booking['dateBooked'].toDate())}'
                                        : 'Not specified',
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomText(
                                  textLabel: 'Seller: ',
                                  fontSize: 14,
                                  textColor: Colors.grey,
                                ),
                                Flexible(
                                  child: CustomText(
                                    textLabel: booking['sellerName'],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              textLabel:
                                  booking['sellerContact'] ?? 'No Contact No.',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          customDialog(
                            context,
                            booking['serviceName'] ?? 'Unnamed Product',
                            'Cancel this Booking?',
                            () {
                              cancelBooking(
                                Provider.of<UserProvider>(context,
                                        listen: false)
                                    .user!
                                    .uid,
                                booking['serviceId'],
                              );
                              if (Navigator.canPop(context)) {
                                navPop(context);
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
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
      title: CustomText(
        textLabel: 'Orders & Bookings',
        fontSize: 25,
        textColor: headerTitleColor(currentEvent),
      ),
      backgroundColor: backgroundColor(currentEvent),
      iconTheme: const IconThemeData(color: Colors.black),
      bottom: TabBar(
        controller: _categoryController,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Orders'),
          Tab(text: 'Bookings'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _categoryController,
      children: [
        Column(
          children: [
            Container(
              color: backgroundColor(currentEvent), 
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Active Orders'),
                  Tab(text: 'Delivered'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(backgroundImage(currentEvent)), 
                    fit: BoxFit.cover,
                  ),
                ),
                child: ordersLoading
                    ? Center(
                        child: SpinKitFadingCircle(
                          size: 80,
                          color: AppColors.primary,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOrderList(_activeOrders, 'packed'),
                          _buildOrderList(_deliveredOrders, 'delivered'),
                        ],
                      ),
              ),
            ),
          ],
        ),
        bookingsLoading
            ? Center(
                child: SpinKitFadingCircle(
                  size: 80,
                  color: AppColors.primary,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(backgroundImage(currentEvent)), 
                    fit: BoxFit.cover,
                  ),
                ),
                child: _buildBookedList(_bookedServices),
              ),
      ],
    ),
  );
}
    }