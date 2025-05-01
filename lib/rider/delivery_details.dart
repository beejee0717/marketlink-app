import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

import '../components/auto_size_text.dart';
import '../components/navigator.dart';
import '../components/snackbar.dart';

class DeliveryDetails extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isDelivery;

  const DeliveryDetails(
      {super.key, required this.data, required this.isDelivery});

  @override
  State<DeliveryDetails> createState() => _DeliveryDetailsState();
}

class _DeliveryDetailsState extends State<DeliveryDetails> {
  bool _isLoading = false;
  String? localImagePath;

  Stream<bool> checkIfMarkedAsDelivery(String? riderId, String orderId) {
    return FirebaseFirestore.instance
        .collection('riders')
        .doc(riderId)
        .collection('deliveries')
        .doc(orderId)
        .snapshots()
        .map((docSnapshot) => docSnapshot.exists);
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;
    // debugging('recieved data ${widget.isDelivery}');
    // debugging('Local Image path $localImagePath');

    bool isDelivery = widget.isDelivery;
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
            textLabel: 'Product Details',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            textColor: Colors.white,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.data['imageUrl'] != null
                        ? Image.network(
                            widget.data['imageUrl'],
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
                  child: _isLoading
                      ? ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : StreamBuilder<bool>(
                          stream: checkIfMarkedAsDelivery(
                            userId,
                            widget.data['orderId'],
                          ),
                          builder: (context, snapshot) {
                            final isMarkedAsDelivered = snapshot.data == true;

                            return Column(
                              children: [
                                isDelivery && isMarkedAsDelivered
                                    ? ElevatedButton(
                                        onPressed: () {
                                          showCameraDialog(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 40, vertical: 15),
                                          backgroundColor: Colors.orange,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: CustomText(
                                          textLabel: 'Mark As Delivered',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          textColor: Colors.white,
                                        ),
                                      )
                                    : SizedBox(),
                                SizedBox(
                                  height: 10,
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (isMarkedAsDelivered) {
                                      _cancelDelivery(
                                        context,
                                        widget.data['productId'],
                                        widget.data['customerId'],
                                        widget.data['orderId'],
                                        widget.data,
                                      );
                                    } else {
                                      _markAsDelivery(
                                        context,
                                        widget.data['productId'],
                                        widget.data['customerId'],
                                        widget.data['orderId'],
                                        widget.data,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 15),
                                    backgroundColor: isMarkedAsDelivered
                                        ? Colors.red
                                        : AppColors.purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: CustomText(
                                    textLabel: isMarkedAsDelivered
                                        ? 'Cancel Delivery'
                                        : 'Deliver Product',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    textColor: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),

                const SizedBox(height: 20),

                CustomText(
                  textLabel: widget.data['productName'] ?? 'Unnamed Product',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  textColor: Colors.black,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const CustomText(
                      textLabel: 'Quantity: ',
                      fontSize: 16,
                      textColor: Colors.grey,
                    ),
                    CustomText(
                      textLabel: '${widget.data['quantity']} pc(s)',
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
                      textLabel: 'Total Payment: ',
                      fontSize: 16,
                      textColor: Colors.grey,
                    ),
                    CustomText(
                      textLabel:
                          '₱${widget.data['price']?.toStringAsFixed(2) ?? 'N/A'}',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      textColor: Colors.black,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Divider(height: 30, thickness: 1.5, color: Colors.orange),

                const CustomText(
                  textLabel: 'Customer Data',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  textColor: Colors.black,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const CustomText(
                      textLabel: 'Name: ',
                      fontSize: 16,
                      textColor: Colors.grey,
                    ),
                    CustomText(
                      textLabel: widget.data['customerName'],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      textColor: Colors.black,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const CustomText(
                      textLabel: 'Contact Number: ',
                      fontSize: 16,
                      textColor: Colors.grey,
                    ),
                    CustomText(
                      textLabel: widget.data['customerContact'],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      textColor: Colors.black,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const CustomText(
                      textLabel: 'Delivery Address: ',
                      fontSize: 16,
                      textColor: Colors.grey,
                    ),
                    CustomText(
                      textLabel: widget.data['customerAddress'] ??
                          'No Address Indicated',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      textColor: Colors.black,
                    ),
                  ],
                ),

                const Divider(height: 30, thickness: 1.5, color: Colors.orange),
                const CustomText(
                  textLabel: 'Seller Data',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  textColor: Colors.black,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const CustomText(
                      textLabel: 'Name: ',
                      fontSize: 16,
                      textColor: Colors.grey,
                    ),
                    CustomText(
                      textLabel: widget.data['sellerName'],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      textColor: Colors.black,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const CustomText(
                      textLabel: 'Contact Number: ',
                      fontSize: 16,
                      textColor: Colors.grey,
                    ),
                    CustomText(
                      textLabel: widget.data['sellerContact'],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      textColor: Colors.black,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const CustomText(
                      textLabel: 'Pickup Address: ',
                      fontSize: 16,
                      textColor: Colors.grey,
                    ),
                    CustomText(
                      textLabel: widget.data['pickupLocation'],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      textColor: Colors.black,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Future<void> _buyNow(BuildContext context, Map<String, dynamic> data) async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      errorSnackbar(context, 'You must be logged in to place an order.');
      return;
    }
    try {
      final ridersRef = FirebaseFirestore.instance
          .collection('riders')
          .doc(userId)
          .collection('deliveries')
          .doc(data['orderId']);
      await ridersRef.set({
        'orderId': data['orderId'],
        'productId': data['productId'],
        'productName': data['productName'],
        'price': data['price'],
        'quantity': data['quantity'],
        'imageUrl': data['imageUrl'],
        'customerId': data['customerId'],
        'customerName': data['customerName'],
        'customerContact': data['customerContact'],
        'deliveryAddress': data['customerAddress'],
        'sellerName': data['sellerName'],
        'sellerContact': data['sellerContact'],
        'pickupLocation': data['pickupLocation']
      });
    } catch (error) {
      if (!context.mounted) return;
      errorSnackbar(context, 'Failed to mark as deliver: $error');
    }
  }

  Future<void> _markAsDelivery(BuildContext context, String productId,
      String customerId, String orderId, Map<String, dynamic> data) async {
    setState(() => _isLoading = true);

    final productsRef = FirebaseFirestore.instance
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
      await _buyNow(context, data);
      await Future.wait([
        productsRef.update({'hasRider': true}),
        customerBookingRef.update({'hasRider': true}),
      ]);
      if (context.mounted) {
        successSnackbar(context, 'Order Marked as Delivery!');
      }
    } catch (e) {
      if (context.mounted) {
        errorSnackbar(context, 'Failed to mark as Delivery: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
//TODO: make function for successfull delivery
  Future<String?> showCameraDialog(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BottomSheet(
        onClosing: () {},
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  try {
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.camera);
                    if (pickedFile == null) {
                      if (context.mounted) {
                        Navigator.pop(context);
                      } // No image picked, just close
                      return;
                    }

                    final croppedFile = await ImageCropper().cropImage(
                      sourcePath: pickedFile.path,
                      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                    );

                    if (croppedFile != null) {
                      if (context.mounted) {
                        debugging(croppedFile.path);
                          setState(() {
                              localImagePath = croppedFile.path;
                            });
                        Navigator.pop(context, croppedFile.path); // Return path
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.pop(context); // Cropping cancelled
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Safely close the sheet first
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to capture image')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelDelivery(BuildContext context, String productId,
      String customerId, String orderId, Map<String, dynamic> data) async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    setState(() => _isLoading = true);

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

    final riderDeliveryRef = FirebaseFirestore.instance
        .collection('riders')
        .doc(userId)
        .collection('deliveries')
        .doc(data['orderId']);

    try {
      await Future.wait([
        serviceBookingRef.update({'hasRider': false}),
        customerBookingRef.update({'hasRider': false}),
        riderDeliveryRef.delete()
      ]);
      if (context.mounted) {
        successSnackbar(context, 'Order Delivery Cancelled!');
      }
    } catch (e) {
      if (context.mounted) {
        errorSnackbar(context, 'Failed to Cancel Delivery: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

