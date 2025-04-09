import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../chat/messages.dart';
import '../components/auto_size_text.dart';
import '../components/navigator.dart';
import '../components/snackbar.dart';
import '../provider/user_provider.dart';

class SellerBookings extends StatefulWidget {
  const SellerBookings({super.key});

  @override
  State<SellerBookings> createState() => _SellerBookingsState();
}

class _SellerBookingsState extends State<SellerBookings>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _approvedBookings = [];
  bool isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final sellerId =
        Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (sellerId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final services = await _fetchSellerServices(sellerId);

    final List<Map<String, dynamic>> pending = [];
    final List<Map<String, dynamic>> approved = [];

    for (var service in services) {
      final serviceId = service['serviceId'];
      final imageUrl = service['imageUrl'];
      final price = service['price'];
      final bookings = await _fetchServiceBookings(serviceId);

      for (var booking in bookings) {
        final customerId = booking['customerId'];
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(customerId)
            .get();

        final customerName = customerDoc.exists
            ? '${customerDoc['firstName']} ${customerDoc['lastName']}'
            : 'Unknown Customer';
        final customerProfilePic = customerDoc.exists &&
                customerDoc.data()!.containsKey('profilePicture')
            ? customerDoc['profilePicture'] ?? ''
            : '';

        final customerContact = customerDoc.exists &&
                customerDoc.data()!.containsKey('contactNumber')
            ? customerDoc['contactNumber']
            : 'N/A';

      

        final orderData = {
          'serviceId': serviceId,
          'serviceName': service['serviceName'],
          'dateBooked': booking['dateBooked'],
          'customerId': customerId,
          'customerName': customerName,
          'dateOrdered': booking['dateOrdered'],
          'status': booking['status'],
          'customerProfilePic': customerProfilePic,
          'imageUrl': imageUrl,
          'customerContact': customerContact,
          'amount': price,
        };

        if (booking['status'] == 'pending') {
          pending.add(orderData);
        } else {
          approved.add(orderData);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _pendingBookings = pending;
      _approvedBookings = approved;
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchSellerServices(
      String sellerId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('services')
        .where('sellerId', isEqualTo: sellerId)
        .get();

    return querySnapshot.docs
        .map((doc) => {'serviceId': doc.id, ...doc.data()})
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchServiceBookings(
      String serviceId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .collection('bookings')
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'customerId': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  Future<void> markAsApproved(
      String serviceId, String userId) async {
    final serviceBookingRef = FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .collection('bookings')
        .doc(userId);

    final customerBookingRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('bookings')
        .doc(serviceId);


    try {
   

      await Future.wait([
        serviceBookingRef.update({'status': 'approved'}),
        customerBookingRef.update({'status': 'approved'}),
      ]);

      if (!mounted) return;
      successSnackbar(context, "Booking marked as approved.");
      await _loadBookings();
    } catch (e) {
      if (!mounted) return;

      errorSnackbar(context, "Failed to mark as approved: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      appBar: AppBar(
        backgroundColor: Colors.purple.shade900,
        title: const CustomText(
          textLabel: 'Bookings',
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
                textLabel: "Pending",
                fontSize: 16,
                textColor: Colors.white,
              ),
            ),
             Tab(
              child: CustomText(
                textLabel: "Approved",
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
                _buildBookingList(_pendingBookings, 'ordered'),
                _buildBookingList(_approvedBookings, 'approved'),
              ],
            ),
    );
  }

  Widget _buildBookingList(List<Map<String, dynamic>> bookings, String tab) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.timer_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            CustomText(
              textLabel: "No bookings found.",
              fontSize: 18,
              textColor: Colors.grey,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final formattedDate = DateFormat('MM/dd/yyyy hh:mm a')
            .format(booking['dateOrdered'].toDate());
           final bookedDate = DateFormat('MM/dd/yyyy hh:mm a')
            .format(booking['dateBooked'].toDate());
          
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
                    booking['imageUrl'] ?? '',
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
                        textLabel: booking['serviceName'] ?? 'Unnamed Service',
                        fontSize: 16,
                        maxLines: 2,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Chosen Date: $bookedDate',
                        fontSize: 14,
                        textColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Customer: ${booking['customerName']}',
                        fontSize: 14,
                        textColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel:
                            'Amount: ₱${booking['amount'].toStringAsFixed(2)}',
                        fontSize: 14,
                        textColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel:
                            'Contact: ${booking['customerContact'] ?? 'N/A'}',
                        fontSize: 14,
                        textColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Date Booked: $formattedDate',
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
                                onPressed: () => markAsApproved(
                                  booking['serviceId'],
                                  booking['customerId'],
                                                               ),
                                child: const CustomText(
                                  textLabel: "Mark as Approved",
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
                                booking['customerId'],
                                booking['customerName'],
                                booking['customerProfilePic'],
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
