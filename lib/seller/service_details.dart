import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:marketlinkapp/seller/edit_service.dart';
import 'package:marketlinkapp/seller/seller.dart';
import 'package:provider/provider.dart';

import '../components/auto_size_text.dart';
import '../components/navigator.dart';
import '../components/snackbar.dart';

class SellerServiceDetails extends StatelessWidget {
  final String serviceId;

  const SellerServiceDetails({super.key, required this.serviceId});

  Future<Map<String, dynamic>> fetchServiceDetails(String serviceId) async {
    final doc = await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .get();

    debugging(doc.data().toString());

    if (doc.exists) {
      return doc.data()!;
    } else {
      throw Exception('Service not found');
    }
  }

  Future<void> deleteService(BuildContext context, String serviceId) async {
    final userId = Provider.of<UserProvider>(context, listen: false).user!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .delete();
      if (!context.mounted) return;
      successSnackbar(context, 'Service deleted successfully.');
      navPushRemove(context, Seller(userId: userId));
    } catch (e) {
      errorSnackbar(context, 'Failed to delete service.');
    }
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            navPop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => customDialog(context, 'Delete Service',
                'Are you sure you want to delete this service?', () {
              deleteService(context, serviceId);
            }),
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const CustomText(
          textLabel: "Service Details",
          fontSize: 22,
          fontWeight: FontWeight.bold,
          textColor: Colors.white,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchServiceDetails(serviceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            debugging(snapshot.error.toString());
            return const Center(
              child: CustomText(
                textLabel: "Error fetching service details.",
                fontSize: 16,
                textColor: Colors.red,
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: CustomText(
                textLabel: "Service not found.",
                fontSize: 16,
                textColor: Colors.grey,
              ),
            );
          }

          final service = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Image
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: service['imageUrl'] != null
                          ? Image.network(
                              service['imageUrl'],
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.image,
                              size: 200,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        navPush(
                            context, SellerEditService(serviceId: serviceId));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const CustomText(
                        textLabel: "Edit Service",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomText(
                    textLabel: service['serviceName'] ?? "Unnamed Service",
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    textColor: Colors.white,
                  ),
                  const Divider(height: 30, thickness: 1.5, color: Colors.grey),

                  Row(
                    children: [
                      const CustomText(
                        textLabel: "Category: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      CustomText(
                        textLabel: service['category'] ?? "Uncategorized",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const CustomText(
                        textLabel: "Price: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      CustomText(
                        textLabel:
                            "₱${service['price']?.toStringAsFixed(2) ?? 'N/A'}",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText(
                        textLabel: "Service Days: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                (service['availableDays'] as List<dynamic>?)
                                        ?.map((day) => Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: CustomText(
                                                textLabel: day.toString(),
                                                fontSize: 16,
                                                textColor: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ))
                                        .toList() ??
                                    [
                                      CustomText(
                                        textLabel: "Not specified",
                                        fontSize: 14,
                                        textColor: Colors.grey.shade400,
                                      )
                                    ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const CustomText(
                        textLabel: "Service Hours: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      CustomText(
                        textLabel: formatServiceHours(service['serviceHours']),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Divider(height: 30, thickness: 1.5, color: Colors.grey),

                  const CustomText(
                    textLabel: "Description",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 5),
                  Card(
                    color: Colors.white.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CustomText(
                        textLabel: service['description'] ??
                            "No description available.",
                        fontSize: 16,
                        textColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomText(
                    textLabel:
                        "Service Location: ${service['serviceLocation'] ?? 'Not specified'}",
                    fontSize: 16,
                    textColor: Colors.grey.shade300,
                  ),
                  const Divider(height: 30, thickness: 1.5, color: Colors.grey),

                  const CustomText(
                    textLabel: "Customer Reviews",
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('services')
                        .doc(serviceId)
                        .collection('reviews')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const CustomText(
                          textLabel: "No reviews yet.",
                          fontSize: 16,
                          textColor: Colors.grey,
                        );
                      }

                      final reviews = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          final userId = review.id;
                          final comment =
                              review['comment'] ?? "No comment provided.";
                          final stars = review['stars'] ?? 0;

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('customers')
                                .doc(userId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox();
                              }

                              if (!userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                return const CustomText(
                                  textLabel: "Unknown user left a review.",
                                  fontSize: 16,
                                  textColor: Colors.grey,
                                );
                              }

                              final user = userSnapshot.data!;
                              final firstName = user['firstName'];
                              final lastName = user['lastName'];
                              final userData = user.data() as Map<String,
                                  dynamic>?; // Cast to Map<String, dynamic> or null
                              final profilePicture = (userData != null &&
                                      userData.containsKey('profilePicture') &&
                                      userData['profilePicture'] != null)
                                  ? userData['profilePicture'] as String
                                  : '';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: profilePicture.isNotEmpty
                                      ? NetworkImage(profilePicture)
                                      : AssetImage('assets/images/profile.png')
                                          as ImageProvider,
                                  child: profilePicture.isEmpty ? null : null,
                                ),
                                title: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: CustomText(
                                        textLabel: '$firstName $lastName',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        textColor: Colors.white,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (index) => Icon(
                                          index < stars
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: CustomText(
                                  textLabel: comment,
                                  fontSize: 14,
                                  textColor: Colors.grey.shade300,
                                  maxLines: 5,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    customDialog(context, 'Delete Review',
                                        'Are you sure you want to remove this user\'s comment?',
                                        () {
                                      deleteReview(context, serviceId, userId);
                                      navPop(context);
                                    });
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> deleteReview(
      BuildContext context, String serviceId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .collection('reviews')
          .doc(userId)
          .delete();
      if (!context.mounted) return;
      successSnackbar(context, "Review deleted successfully.");
    } catch (e) {
      errorSnackbar(context, "Failed to delete review: $e");
    }
  }
}
  String formatServiceHours(Map<String, dynamic>? serviceHours) {
    if (serviceHours == null ||
        !serviceHours.containsKey('start') ||
        !serviceHours.containsKey('end')) {
      return "Not specified";
    }

    DateFormat inputFormat = DateFormat("HH:mm");
    DateFormat outputFormat = DateFormat("h:mm a");

    try {
      String startTime =
          outputFormat.format(inputFormat.parse(serviceHours['start']));
      String endTime =
          outputFormat.format(inputFormat.parse(serviceHours['end']));
      return "$startTime - $endTime";
    } catch (e) {
      return "Invalid time format";
    }
  }