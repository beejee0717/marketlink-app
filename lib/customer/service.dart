import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/customer/components.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/seller/service_details.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:provider/provider.dart';

import '../chat/messages.dart';
import '../components/navigator.dart';
import '../provider/user_provider.dart';

class CustomerService extends StatefulWidget {
  final String serviceId;
  const CustomerService({super.key, required this.serviceId});

  @override
  State<CustomerService> createState() => _CustomerServiceState();
}

class _CustomerServiceState extends State<CustomerService> {
  bool isInWishlist = false;
  late AppEvent currentEvent = getCurrentEvent();

  @override
  void initState() {
    super.initState();
    checkIfInWishlist();
  }

  Future<void> checkIfInWishlist() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;
    if (userId == null) return;

    final wishlistRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('wishlist')
        .doc(widget.serviceId);

    final wishlistDoc = await wishlistRef.get();
    setState(() {
      isInWishlist = wishlistDoc.exists;
    });
  }

  Future<Map<String, dynamic>> fetchServiceDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceId)
        .get();

    if (doc.exists) {
      return doc.data()!;
    } else {
      throw Exception("Service not found.");
    }
  }

  Future<Map<String, dynamic>> fetchSellerDetails(String sellerId) async {
    final doc = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .get();

    if (doc.exists) {
      return doc.data()!;
    } else {
      throw Exception("Seller not found.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText(textLabel: 'Details', fontSize: 20),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container( decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage(backgroundImage(currentEvent)),
      fit: BoxFit.cover,
    ),
  ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: fetchServiceDetails(),
          builder: (context, serviceSnapshot) {
            if (serviceSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SpinKitFadingCircle(
                  size: 80,
                  color: AppColors.primary,
                ),
              );
            } else if (serviceSnapshot.hasError) {
              debugging(serviceSnapshot.error.toString());
              return Center(
                child: CustomText(
                  textLabel: "Error loading service details.",
                  fontSize: 16,
                  textColor: Colors.red,
                ),
              );
            } else if (!serviceSnapshot.hasData ||
                serviceSnapshot.data!.isEmpty) {
              return const Center(
                child: CustomText(
                  textLabel: "Service not found.",
                  fontSize: 16,
                  textColor: Colors.grey,
                ),
              );
            }
        
            final service = serviceSnapshot.data!;
            final imageUrl = service['imageUrl'] ?? '';
            final title = service['serviceName'] ?? 'Unnamed Service';
            final category = service['category'] ?? 'Uncategorized';
            final price = service['price']?.toStringAsFixed(2) ?? 'N/A';
            final description =
                service['description'] ?? 'No description available.';
            final availableDays =
                service['availableDays'] ?? 'No Avaible Days Set';
            final serviceLocation =
                service['serviceLocation'] ?? 'Service location not specified.';
            final sellerId = service['sellerId'];
            final serviceHours = service['serviceHours'];
            final currentUser =
                Provider.of<UserProvider>(context, listen: false).user?.uid;
        final promo = (service['promo'] is Map<String, dynamic>)
    ? service['promo'] as Map<String, dynamic>
    : null;

final bool hasPromo = promo?['enabled'] == true;
final String promoType = promo?['type'] ?? '';
final num promoValue = promo?['value'] ?? 0;

String discountedPrice = price;

if (hasPromo) {
  final originalPrice = service['price'] ?? 0.0;
  if (promoType == 'percentage') {
    discountedPrice = (originalPrice * (1 - promoValue / 100))
        .toStringAsFixed(2);
  } else if (promoType == 'fixed') {
    final discount = promoValue;
    final discounted = (originalPrice - discount).clamp(0, double.infinity);
    discountedPrice = discounted.toStringAsFixed(2);
  }
}
            return FutureBuilder<Map<String, dynamic>>(
              future: fetchSellerDetails(sellerId),
              builder: (context, sellerSnapshot) {
                if (sellerSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SpinKitFadingCircle(
                      size: 80,
                      color: AppColors.primary,
                    ),
                  );
                } else if (sellerSnapshot.hasError) {
                  return Center(
                    child: CustomText(
                      textLabel: "Error loading seller details.",
                      fontSize: 16,
                      textColor: Colors.red,
                    ),
                  );
                } else if (!sellerSnapshot.hasData ||
                    sellerSnapshot.data!.isEmpty) {
                  return const Center(
                    child: CustomText(
                      textLabel: "Seller details not found.",
                      fontSize: 16,
                      textColor: Colors.grey,
                    ),
                  );
                }
        
                final seller = sellerSnapshot.data!;
                final sellerName =
                    '${seller['firstName'] ?? 'Unknown'} ${seller['lastName'] ?? 'Seller'}';
        
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            height: 300,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 300,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomText(
                          textLabel: title,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        CustomText(
                          textLabel: category,
                          fontSize: 20,
                        ),
                        const SizedBox(height: 8),
                             if (hasPromo) ...[
  Row(
    children: [
      CustomText(
        textLabel: '₱$price',
        fontSize: 18,
        textColor: Colors.grey,
        fontWeight: FontWeight.normal,
        decoration: TextDecoration.lineThrough,
      ),
      const SizedBox(width: 8),
      CustomText(
        textLabel: '₱$discountedPrice',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        textColor: Colors.orange,
      ),
    ],
  ),
  const SizedBox(height: 6),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.red.shade600,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      promoType == 'percentage'
          ? '$promoValue% OFF'
          : '₱${promoValue.toStringAsFixed(2)} OFF',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  ),
] else ...[
  CustomText(
    textLabel: '₱$price',
    fontSize: 20,
    textColor: productDetails(currentEvent),
  ),
],

                        const SizedBox(height: 8),
                        FutureBuilder<Map<String, dynamic>>(
                          future: getRating(widget.serviceId, false),
                          builder: (context, ratingSnapshot) {
                            if (ratingSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 20,
                                width: 50,
                                child: LinearProgressIndicator(),
                              );
                            }
                            if (ratingSnapshot.hasError) {
                              return const Text('Error');
                            }
        
                            double averageRating =
                                (ratingSnapshot.data?['averageRating'] ?? 0.0)
                                    .toDouble();
                            int totalReviews =
                                ratingSnapshot.data?['totalReviews'] ?? 0;
        
                            return Row(
                              children: [
                                ...List.generate(5, (index) {
                                  if (index + 1 <= averageRating) {
                                    return const Icon(Icons.star,
                                        color: Colors.amber, size: 20);
                                  } else if (index + 0.5 <= averageRating) {
                                    return const Icon(Icons.star_half,
                                        color: Colors.amber, size: 20);
                                  } else {
                                    return const Icon(Icons.star_border,
                                        color: Colors.amber, size: 20);
                                  }
                                }),
                                const SizedBox(width: 5),
                                Text(
                                  '($totalReviews)',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            navigateToMessageSeller(
                              sellerId,
                              seller['firstName'],
                              seller['profilePicture'] ?? '',
                            );
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.message,
                                color: AppColors.primary,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              CustomText(
                                textLabel: 'Message $sellerName',
                                fontSize: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (seller['contactNumber'] != null &&
                            seller['contactNumber']
                                .toString()
                                .trim()
                                .isNotEmpty) ...[
                          Row(
                            children: [
                              CustomText(
                                textLabel: 'Seller Contact Number: ',
                                fontSize: 16,
                              ),
                              CustomText(
                                textLabel: seller['contactNumber'],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
            ElevatedButton(
          onPressed: () async {
            DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
            );
        
            if (!context.mounted) return;
        
            if (selectedDate == null) return;
        
            TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
            );
        
            if (!context.mounted) return;
        
            if (selectedTime == null) return;
        
            final DateTime selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
            );
        
         showBookDialog(
  widget.serviceId,
  title,
  sellerId,
  double.parse(discountedPrice),
  selectedDateTime,
);

          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: CustomText(
        textLabel: 'Book Now',
        fontSize: 18,
        textColor: Colors.white,
            ),
          ),
        ),
        
                        
                          ],
                        ),
                        const SizedBox(height: 20),
                        DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                labelColor: AppColors.primary,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: AppColors.primary,
                                tabs: const [
                                  Tab(text: 'Details'),
                                  Tab(text: 'Reviews'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                  height: 400,
                                  child: TabBarView(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                 SizedBox(height: 10),
                                                RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black),
                                                    children: [
                                                      TextSpan(
                                                        text: "Address: ",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold),
                                                      ),
                                                      TextSpan(
                                                        text: serviceLocation,
                                                        style: TextStyle(
                                                            fontWeight: FontWeight
                                                                .normal),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black),
                                                    children: [
                                                      TextSpan(
                                                        text: "Available Days: ",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold),
                                                      ),
                                                      TextSpan(
                                                        text: availableDays
                                                            .join(', '),
                                                        style: TextStyle(
                                                            fontWeight: FontWeight
                                                                .normal),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black),
                                                    children: [
                                                      TextSpan(
                                                        text: "Service Hours: ",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold),
                                                      ),
                                                      TextSpan(
                                                        text: formatServiceHours(
                                                            serviceHours),
                                                        style: TextStyle(
                                                            fontWeight: FontWeight
                                                                .normal),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black),
                                                    children: [
                                                      TextSpan(
                                                        text: "Category : ",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold),
                                                      ),
                                                      TextSpan(
                                                        text: category,
                                                        style: TextStyle(
                                                            fontWeight: FontWeight
                                                                .normal),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black),
                                                    children: [
                                                      TextSpan(
                                                        text: "Description: ",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold),
                                                      ),
                                                      TextSpan(
                                                        text: description,
                                                        style: TextStyle(
                                                            fontWeight: FontWeight
                                                                .normal),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                      Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Column(
                                          children: [
                                       FutureBuilder<QuerySnapshot>(
  future: FirebaseFirestore.instance
      .collection('bookings')
      .where('customerId', isEqualTo: currentUser)
      .where('serviceId', isEqualTo: widget.serviceId)
      .where('status', isEqualTo: 'done') 
      .get(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox();
    }

    final hasBookedService =
        snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        debugging(hasBookedService.toString());

    if (!hasBookedService) {
      return const SizedBox(); 
    }

    return Center(
      child: ElevatedButton(
        onPressed: () => showLeaveReviewDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 5.0),
          child: CustomText(
            textLabel: 'Leave a Review',
            fontSize: 15,
            textColor: Colors.white,
          ),
        ),
      ),
    );
  },
)
,
                                            const SizedBox(height: 10),
                                            StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('services')
                                                  .doc(widget.serviceId)
                                                  .collection('reviews')
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                }
                                                if (!snapshot.hasData ||
                                                    snapshot.data!.docs.isEmpty) {
                                                  return const CustomText(
                                                    textLabel:
                                                        'No reviews yet. Be the first to leave one!',
                                                    fontSize: 16,
                                                    textColor: Colors.grey,
                                                  );
                                                }
        
                                                final reviews =
                                                    snapshot.data!.docs;
        
                                                return Column(
                                                  children:
                                                      reviews.map((reviewDoc) {
                                                    final review = reviewDoc
                                                            .data()
                                                        as Map<String, dynamic>;
                                                    final userId = reviewDoc.id;
                                                    final comment =
                                                        review['comment'] ?? '';
                                                    final stars =
                                                        review['stars'] ?? 0;
        
                                                    return FutureBuilder<
                                                        DocumentSnapshot>(
                                                      future: FirebaseFirestore
                                                          .instance
                                                          .collection('customers')
                                                          .doc(userId)
                                                          .get(),
                                                      builder: (context,
                                                          userSnapshot) {
                                                        if (userSnapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const SizedBox();
                                                        }
        
                                                        if (!userSnapshot
                                                                .hasData ||
                                                            !userSnapshot
                                                                .data!.exists) {
                                                               return ListTile(
                                                          leading: CircleAvatar(
                                                            backgroundImage: AssetImage(
                                                                        'assets/images/profile.png')
                                                                    as ImageProvider,
                                                            child
                                                                : null,
                                                          ),
                                                          title: CustomText(
                                                            textLabel:
                                                                'Unknown User',
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          subtitle: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children:
                                                                    List.generate(
                                                                  5,
                                                                  (index) => Icon(
                                                                    Icons.star,
                                                                    color: index <
                                                                            stars
                                                                        ? Colors
                                                                            .amber
                                                                        : Colors
                                                                            .grey,
                                                                    size: 16,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 5),
                                                              CustomText(
                                                                textLabel:
                                                                    comment,
                                                                fontSize: 14,
                                                                maxLines: 5,
                                                              ),
                                                            ],
                                                          ),
                                                            trailing:
                                                              userId ==
                                                                      currentUser
                                                                  ? IconButton(
                                                                      icon: Icon(
                                                                          Icons
                                                                              .delete,
                                                                          color: Colors
                                                                              .red),
                                                                      onPressed:
                                                                          () {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (BuildContext
                                                                                  context) {
                                                                            return AlertDialog(
                                                                              title:
                                                                                  Text("Delete Review"),
                                                                              content:
                                                                                  Text("Are you sure you want to delete your review?"),
                                                                              actions: [
                                                                                TextButton(
                                                                                  onPressed: () {
                                                                                    Navigator.of(context).pop();
                                                                                  },
                                                                                  child: Text("Cancel"),
                                                                                ),
                                                                                TextButton(
                                                                                  onPressed: () async {
                                                                                    Navigator.of(context).pop();
                                                                                    await deleteReview();
                                                                                  },
                                                                                  child: Text(
                                                                                    "Delete",
                                                                                    style: TextStyle(color: Colors.red),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                    )
                                                                  : null,
                                                        
                                                        );
                                                  
                                                        }
        
                                                        final user =
                                                            userSnapshot.data!;
                                                        final firstName =
                                                            user['firstName'] ??
                                                                'Unknown';
                                                        final lastName =
                                                            user['lastName'] ??
                                                                'User';
                                                        final userData =
                                                            user.data() as Map<
                                                                String, dynamic>?;
                                                        final profilePicture = (userData !=
                                                                    null &&
                                                                userData.containsKey(
                                                                    'profilePicture') &&
                                                                userData[
                                                                        'profilePicture'] !=
                                                                    null)
                                                            ? userData[
                                                                    'profilePicture']
                                                                as String
                                                            : '';
        
                                                        return ListTile(
                                                          leading: CircleAvatar(
                                                            backgroundImage: profilePicture
                                                                    .isNotEmpty
                                                                ? NetworkImage(
                                                                    profilePicture)
                                                                : AssetImage(
                                                                        'assets/images/profile.png')
                                                                    as ImageProvider,
                                                         
                                                          ),
                                                          title: CustomText(
                                                            textLabel:
                                                                '$firstName $lastName',
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          subtitle: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children:
                                                                    List.generate(
                                                                  5,
                                                                  (index) => Icon(
                                                                    Icons.star,
                                                                    color: index <
                                                                            stars
                                                                        ? Colors
                                                                            .amber
                                                                        : Colors
                                                                            .grey,
                                                                    size: 16,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 5),
                                                              CustomText(
                                                                textLabel:
                                                                    comment,
                                                                fontSize: 14,
                                                                maxLines: 5,
                                                              ),
                                                            ],
                                                          ),
                                                            trailing:
                                                              userId ==
                                                                      currentUser
                                                                  ? IconButton(
                                                                      icon: Icon(
                                                                          Icons
                                                                              .delete,
                                                                          color: Colors
                                                                              .red),
                                                                      onPressed:
                                                                          () {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (BuildContext
                                                                                  context) {
                                                                            return AlertDialog(
                                                                              title:
                                                                                  Text("Delete Review"),
                                                                              content:
                                                                                  Text("Are you sure you want to delete your review?"),
                                                                              actions: [
                                                                                TextButton(
                                                                                  onPressed: () {
                                                                                    Navigator.of(context).pop();
                                                                                  },
                                                                                  child: Text("Cancel"),
                                                                                ),
                                                                                TextButton(
                                                                                  onPressed: () async {
                                                                                    Navigator.of(context).pop();
                                                                                    await deleteReview();
                                                                                  },
                                                                                  child: Text(
                                                                                    "Delete",
                                                                                    style: TextStyle(color: Colors.red),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                    )
                                                                  : null,
                                                        
                                                        );
                                                      },
                                                    );
                                                  }).toList(),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                  ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Divider(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

 

  Future<void> addToWishlist(String serviceId, String sellerId) async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      errorSnackbar(context, "You must be logged in to add to the wishlist.");
      return;
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('wishlist')
        .doc(serviceId);

    final wishlistDoc = await wishlistRef.get();

    if (wishlistDoc.exists) {
      if (!mounted) return;
      errorSnackbar(context, "Service is already in your wishlist.");
    } else {
      await wishlistRef.set({'sellerId': sellerId});
      setState(() {
        isInWishlist = true;
      });
      if (!mounted) return;
      successSnackbar(context, "Service added to your wishlist.");
    }
  }

void showBookDialog(String serviceId, String title, String sellerId, double price, DateTime dateTime) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
        title: const Text(
          'Confirm Booking',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              textLabel: title,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CustomText(
                  textLabel: 'Date: ',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                CustomText(
                  textLabel: DateFormat('yyyy-MM-dd').format(dateTime),
                  fontSize: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CustomText(
                  textLabel: 'Time: ',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                CustomText(
                  textLabel: DateFormat('hh:mm a').format(dateTime),
                  fontSize: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CustomText(
                  textLabel: 'Price: ₱',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                CustomText(
                  textLabel: price.toStringAsFixed(2),
                  fontSize: 18,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: ()async {
           await bookNow(serviceId, sellerId, dateTime);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}


Future<void> bookNow(String serviceId, String sellerId, DateTime dateBooked) async {
  final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

  if (userId == null) {
    errorSnackbar(context, "You must be logged in to book.");
    return;
  }

  final now = Timestamp.now();

  try {
    final serviceRef = FirebaseFirestore.instance.collection('services').doc(serviceId);
    final serviceSnapshot = await serviceRef.get();

    if (!serviceSnapshot.exists) {
      if (!mounted) return;
      errorSnackbar(context, "Service not found.");
      return;
    }

    final serviceData = serviceSnapshot.data()!;
    final double originalPrice = (serviceData['price'] as num).toDouble();
    final String serviceName = serviceData['serviceName'];
    final String serviceDescription = serviceData['description'];
    final String category = serviceData['category'] ?? "Uncategorized";

    final promo = (serviceData['promo'] is Map<String, dynamic>)
        ? serviceData['promo'] as Map<String, dynamic>
        : null;

    final bool hasPromo = promo?['enabled'] == true;
    final String promoType = promo?['type'] ?? '';
    final num promoValue = promo?['value'] ?? 0;

    double finalPrice = originalPrice;

    if (hasPromo) {
      if (promoType == 'percentage') {
        finalPrice = originalPrice * (1 - promoValue / 100);
      } else if (promoType == 'fixed') {
        finalPrice = (originalPrice - promoValue).clamp(0, double.infinity);
      }
    }

    final bookingId = FirebaseFirestore.instance.collection('bookings').doc().id;
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);

    await bookingRef.set({
      'bookingId': bookingId,
      'customerId': userId,
      'serviceId': serviceId,
      'sellerId': sellerId,
      'dateBooked': dateBooked,
      'dateOrdered': now,
      'price': finalPrice, 
      'status': 'pending',
    });

    final historyRef = FirebaseFirestore.instance.collection('bookingHistory');

    await historyRef.add({
      'serviceId': serviceId,
      'serviceName': serviceName,
      'description': serviceDescription,
      'category': category,
      'price': finalPrice, 
      'dateBooked': dateBooked,
      'timestamp': now,
    });

    if (!mounted) return;
    successSnackbar(context, "Booked Successfully!");
  } catch (error) {
    if (!mounted) return;
    errorSnackbar(context, "Failed to book: $error");
  }
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

  void showLeaveReviewDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController commentController = TextEditingController();
    int rating = 0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CustomText(
                        textLabel: "Leave a Review",
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => IconButton(
                            onPressed: () {
                              setState(() {
                                rating = index + 1;
                              });
                            },
                            icon: Icon(
                              Icons.star,
                              color:
                                  index < rating ? Colors.amber : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: commentController,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          hintText: "Write your comment here...",
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Comment cannot be empty.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              navPop(context);
                            },
                            child: const CustomText(
                              textLabel: 'Cancel',
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }
                              if (rating == 0) {
                                errorSnackbar(context, "Please give a rating.");
                                return;
                              }

                              await leaveReview(
                                commentController.text.trim(),
                                rating,
                              );
                              if (!context.mounted) return;

                              navPop(context);
                            },
                            child: const CustomText(
                              textLabel: 'Submit',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  Future<void> deleteReview() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      errorSnackbar(context, "You must be logged in to delete your review.");
      return;
    }

    final reviewRef = FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceId)
        .collection('reviews')
        .doc(userId);

    try {
      await reviewRef.delete();
      if (!mounted) return;
      successSnackbar(context, "Your review has been deleted.");
    } catch (e) {
      errorSnackbar(context, "Failed to delete review: $e");
    }
  }

  Future<void> leaveReview(String comment, int stars) async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      errorSnackbar(context, "You must be logged in to leave a review.");
      return;
    }

    final reviewRef = FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceId)
        .collection('reviews')
        .doc(userId);

    await reviewRef.set({
      'comment': comment,
      'stars': stars,
    });
    if (!mounted) return;
    successSnackbar(context, "Thank you for your review!");
  }
}
