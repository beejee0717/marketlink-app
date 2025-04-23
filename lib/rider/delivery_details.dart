import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

import '../components/auto_size_text.dart';
import '../components/navigator.dart';
import '../components/snackbar.dart';

class DeliveryDetails extends StatelessWidget {
  
  final Map<String, dynamic> data;

  const DeliveryDetails({super.key, required this.data});

  

  @override
  Widget build(BuildContext context) {
    debugging('recieved data $data');
    return Scaffold(
      backgroundColor: AppColors.white,
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
      
        backgroundColor: AppColors.purple,
        elevation: 0,
        title: const CustomText(
          textLabel: "Product Details",
          fontSize: 22,
          fontWeight: FontWeight.bold,
          textColor: Colors.white,
        ),
      ),
      body:  Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: data['imageUrl'] != null
                          ? Image.network(
                              data['imageUrl'],
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
                        markAsDelivery(context, data['productId'], data['customerId'], data['orderId']);
                        },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        backgroundColor: AppColors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const CustomText(
                        textLabel: "Deliver Product",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomText(
                    textLabel: data['productName'] ?? "Unnamed Product",
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    textColor: Colors.black,
                  ),
                 const SizedBox(height: 10),
                  Row(
                    children: [
                      const CustomText(
                        textLabel: "Quantity: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      CustomText(
                        textLabel: "${data['quantity']} pc(s)",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const CustomText(
                        textLabel: "Total Payment: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      CustomText(
                        textLabel:
                            "₱${data['price']?.toStringAsFixed(2) ?? 'N/A'}",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                 
                  const Divider(height: 30, thickness: 1.5, color: Colors.orange),

                  const CustomText(
                    textLabel: "Customer Data",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    textColor: Colors.black,
                  ),
                  const SizedBox(height: 5),
                     Row(
                    children: [
                      const CustomText(
                        textLabel: "Name: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      CustomText(
                        textLabel:
                            data['customerName'],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.black,
                      ),
                      
                    ],
                  ),const SizedBox(height: 5),
                     Row(
                    children: [
                      const CustomText(
                        textLabel: "Contact Number: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      CustomText(
                        textLabel:
                            data['customerContact'],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.black,
                      ),
                      
                    ],
                  ),const SizedBox(height: 5),
                     Row(
                    children: [
                      const CustomText(
                        textLabel: "Delivery Address: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      CustomText(
                        textLabel:
                            data['customerAddress'],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.black,
                      ),
                      
                    ],
                  ),
                 
                  const Divider(height: 30, thickness: 1.5, color: Colors.orange),
                  const CustomText(
                    textLabel: "Seller Data",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    textColor: Colors.black,
                  ),
                  const SizedBox(height: 5),
                     Row(
                    children: [
                      const CustomText(
                        textLabel: "Name: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      CustomText(
                        textLabel:
                            data['sellerName'],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.black,
                      ),
                      
                    ],
                  ),const SizedBox(height: 5),
                     Row(
                    children: [
                      const CustomText(
                        textLabel: "Contact Number: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      CustomText(
                        textLabel:
                            data['sellerContact'],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.black,
                      ),
                      
                    ],
                  ),const SizedBox(height: 5),
                     Row(
                    children: [
                      const CustomText(
                        textLabel: "Pickup Address: ",
                        fontSize: 16,
                        textColor: Colors.grey,
                      ),
                      CustomText(
                        textLabel:
                            data['pickupLocation'],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.black,
                      ),
                      
                    ],
                  ),
                 ],
              ),
            ),
          )
        );
  }

  Future<void> deleteReview(
      BuildContext context, String productId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
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
  Future<void> markAsDelivery(BuildContext context,
      String productId, String customerId, String orderId) async {
    final serviceBookingRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('orders')
        .doc(orderId);

    final customerBookingRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .collection('orders')
        .doc(orderId);


    try {
        await Future.wait([
        serviceBookingRef.update({'hasRider': true}),
        customerBookingRef.update({'hasRider': true}),
      ]);
 if(context.mounted){
       successSnackbar(context, "Order Marked as Delivery!");
     }
     
    } catch (e) {
     
     if(context.mounted){
       errorSnackbar(context, "Failed to mark as Delivery: $e");
     }
    }
  }