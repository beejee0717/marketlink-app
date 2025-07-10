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

class SellerBookings extends StatefulWidget {
  const SellerBookings({super.key});

  @override
  State<SellerBookings> createState() => _SellerBookingsState();
}

class _SellerBookingsState extends State<SellerBookings>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _approvedBookings = [];
  late AppEvent currentEvent = getCurrentEvent();
  bool isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

 Future<void> _loadBookings() async {
  final sellerId = Provider.of<UserProvider>(context, listen: false).user?.uid;

  if (sellerId == null) {
    setState(() {
      isLoading = false;
    });
    return;
  }

  final querySnapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('sellerId', isEqualTo: sellerId)
      .get();

  final List<Map<String, dynamic>> pending = [];
  final List<Map<String, dynamic>> approved = [];

  for (var doc in querySnapshot.docs) {
    final booking = doc.data();
    final serviceId = booking['serviceId'];
    final customerId = booking['customerId'];

    // Get service details
    final serviceDoc = await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .get();

    final serviceData = serviceDoc.exists ? serviceDoc.data()! : {};
    final serviceName = serviceData['serviceName'] ?? 'Unknown';
    final imageUrl = serviceData['imageUrl'] ?? '';
    final price = (serviceData['price'] ?? 0) as num;

    // Get customer details
    final customerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .get();

    final customerData = customerDoc.exists ? customerDoc.data()! : {};
    final customerName =
        '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'.trim();
    final customerProfilePic = customerData['profilePicture'] ?? '';
    final customerContact = customerData['contactNumber'] ?? 'N/A';

    final bookingData = {
        'bookingId': doc.id, 
      'serviceId': serviceId,
      'serviceName': serviceName,
      'dateBooked': booking['dateBooked'],
      'dateOrdered': booking['dateOrdered'],
      'customerId': customerId,
      'customerName': customerName,
      'status': booking['status'],
      'customerProfilePic': customerProfilePic,
      'imageUrl': imageUrl,
      'customerContact': customerContact,
      'amount': price,
    };

    if (booking['status'] == 'pending') {
      pending.add(bookingData);
    } else {
      approved.add(bookingData);
    }
  }

  if (!mounted) return;
  setState(() {
    _pendingBookings = pending;
    _approvedBookings = approved;
    isLoading = false;
  });
}


Future<void> markAsApproved(String bookingId) async {
  final bookingRef =
      FirebaseFirestore.instance.collection('bookings').doc(bookingId);

  try {
    await bookingRef.update({'status': 'approved'});

    if (!mounted) return;
    successSnackbar(context, "Booking marked as approved.");
    await _loadBookings(); // Refresh the list
  } catch (e) {
    if (!mounted) return;
    debugging(e.toString());
    errorSnackbar(context, "Failed to mark as approved: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: currentEvent == AppEvent.none ? Colors.purple.shade900: backgroundColor(currentEvent),
        title:  CustomText(
          textLabel: 'Bookings',
          fontSize: 25,
          textColor: currentEvent == AppEvent.none ? Colors.white: headerTitleColor(currentEvent),
          fontWeight: FontWeight.bold,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor:AppColors.yellow,
          tabs:  [
            Tab(
              child: CustomText(
                textLabel: "Pending",
                fontSize: 16,
                textColor:currentEvent == AppEvent.none ? Colors.white: headerTitleColor(currentEvent),
              ),
            ),
             Tab(
              child: CustomText(
                textLabel: "Approved",
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
          AssetImage(backgroundImage(currentEvent)),
          fit: BoxFit.cover)
        ),

            child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
          )
          : Container(
            decoration: BoxDecoration(
          image: DecorationImage(image: 
          AssetImage(backgroundImage(currentEvent)),
          fit: BoxFit.cover)
        ),

            child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingList(_pendingBookings, 'ordered'),
                  _buildBookingList(_approvedBookings, 'approved'),
                ],
              ),
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
                        textColor:  currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Chosen Date: $bookedDate',
                        fontSize: 14,
                        textColor:  currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Customer: ${booking['customerName']}',
                        fontSize: 14,
                        textColor:  currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel:
                            'Amount: ₱${booking['amount'].toStringAsFixed(2)}',
                        fontSize: 14,
                        textColor:  currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel:
                            'Contact: ${booking['customerContact'] ?? 'N/A'}',
                        fontSize: 14,
                        textColor:  currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        textLabel: 'Date Booked: $formattedDate',
                        fontSize: 14,
                        textColor:  currentEvent == AppEvent.christmas ? Colors.black : AppColors.primary,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (tab == 'ordered')
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => markAsApproved(
                                 booking['bookingId'].toString()
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
