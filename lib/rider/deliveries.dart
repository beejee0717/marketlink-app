import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/appbar.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/debugging.dart';
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
  bool isLoading = true;
  List<Map<String, dynamic>> _deliveries = [];
  List<Map<String, dynamic>> _delivered = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    final productDeliveries = await fetchDeliveries(userId, false);
    final productDelivered = await fetchDeliveries(userId, true);
    if (!mounted) return;
    setState(() {
      _deliveries = productDeliveries;
      _delivered = productDelivered;
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchDeliveries(
      String riderId, bool isDelivered) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('riders')
        .doc(riderId)
        .collection('deliveries')
        .where('isDelivered', isEqualTo: isDelivered)
        .get();

    return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
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
    debugging(_deliveries.toString());
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: appbar(context, destination: RiderProfile()),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.purple,
              labelColor: AppColors.purple,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Picked Up'),
                Tab(text: 'Delivered'),
              ],
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: SpinKitFadingCircle(
                        size: 80,
                        color: AppColors.purple,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        buildDeliveryList(_deliveries),
                        buildDeliveryList(_delivered)
                      ],
                    ),
            ),
          ],
        ));
  }
}
