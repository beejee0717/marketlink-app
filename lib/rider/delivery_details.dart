import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:marketlinkapp/chat/messages.dart';
import 'package:marketlinkapp/components/cloudinary.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
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
  late AppEvent currentEvent = getCurrentEvent();

  Stream<DocumentSnapshot<Map<String, dynamic>>> deliveryStream(
    String? riderId,
    String orderId,
  ) {
    return FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots();
  }
  void messageCustomer(
      String customerId, String customerFirstName, String customerProfilePic) {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      errorSnackbar(context, "You must be logged in to message the seller.");
      return;
    }

    navPush(
      context,
      UserMessages(
        userId: userId,
        receiverUserId: customerId,
        receiverFirstName: customerFirstName,
        receiverProfilePic: customerProfilePic,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;
    debugging('recieved data: ${widget.data}');

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              navPop(context);
            },
            icon: Icon(Icons.arrow_back,
                color: currentEvent == AppEvent.none
                    ? Colors.white
                    : headerTitleColor(currentEvent)),
          ),
          backgroundColor: currentEvent == AppEvent.none
              ? AppColors.primary
              : backgroundColor(currentEvent),
          elevation: 0,
          title: CustomText(
              textLabel: 'Product Details',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              textColor: currentEvent == AppEvent.none
                  ? Colors.white
                  : headerTitleColor(currentEvent)),
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImage(currentEvent)),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
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
                          : StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(widget.data['orderId'])
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    snapshot.data?.data() == null) {
                                  return const SizedBox();
                                }

                                final deliveryData = snapshot.data!.data()!;
                                final isAssignedToCurrentRider =
                                    deliveryData['riderId'] == userId;
                                final isDelivered =
                                    deliveryData['status'] == 'delivered';

                                return Column(
                                  children: [
                                    if (!isAssignedToCurrentRider &&
                                        !isDelivered)
                                      // Case 1: Not claimed by a rider
                                      ElevatedButton(
                                        onPressed: () {
                                          _markAsDelivery(
                                            context,
                                            widget.data['orderId'],
                                            widget.data,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 40, vertical: 15),
                                          backgroundColor: currentEvent ==
                                                  AppEvent.none
                                              ? AppColors.primary
                                              : backgroundColor(currentEvent),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const CustomText(
                                          textLabel: 'Deliver Product',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          textColor: Colors.white,
                                        ),
                                      )
                                    else if (isAssignedToCurrentRider &&
                                        !isDelivered)
                                      // Case 2: Claimed but not yet delivered
                                      Column(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              showCameraDialogAndUpload(
                                                context,
                                                widget.data['orderId'],
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 40,
                                                      vertical: 15),
                                              backgroundColor: Colors.orange,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const CustomText(
                                              textLabel: 'Mark As Delivered',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              textColor: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton(
                                            onPressed: () {
                                              _cancelDelivery(
                                                context,
                                                widget.data['orderId'],
                                                widget.data,
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 40,
                                                      vertical: 15),
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const CustomText(
                                              textLabel: 'Cancel Delivery',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              textColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    else if (isDelivered)
                                      // Case 3: Delivered
                                      Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.check_circle,
                                                  color: Colors.green),
                                              SizedBox(width: 8),
                                              CustomText(
                                                textLabel: 'Product Delivered',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                textColor: Colors.green,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      'Delivery Proof'),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      deliveryData[
                                                                  'deliveryProof'] !=
                                                              null
                                                          ? Image.network(
                                                              deliveryData[
                                                                  'deliveryProof'],
                                                              loadingBuilder:
                                                                  (context,
                                                                      child,
                                                                      loadingProgress) {
                                                                if (loadingProgress ==
                                                                    null) {
                                                                  return child;
                                                                }
                                                                return const Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              16),
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                );
                                                              },
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return const Text(
                                                                    'Failed to load image');
                                                              },
                                                            )
                                                          : const Text(
                                                              'No delivery proof available'),
                                                      const SizedBox(
                                                          height: 16),
                                                      if (deliveryData[
                                                              'deliveryTimestamp'] !=
                                                          null)
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Text(
                                                              'Delivery Date & Time:',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                            Text(
                                                              DateFormat(
                                                                      'MMMM d, y – h:mm:ss a')
                                                                  .format(
                                                                (deliveryData[
                                                                            'deliveryTimestamp']
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
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child:
                                                          const Text('Close'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 30,
                                                      vertical: 15),
                                              backgroundColor: Colors.blue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const CustomText(
                                              textLabel: 'Show Delivery Proof',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              textColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                );
                              },
                            )),

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

                  const Divider(
                      height: 30, thickness: 1.5, color: Colors.orange),

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

                  if (widget.data['riderId'] == userId) ...[
                    const SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: () {
                        messageCustomer(widget.data['customerId'], widget.data['customerFirstName'], widget.data['customerProfile']);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: CustomText(
                        textLabel: 'Chat with ${widget.data['customerName']}',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                  const Divider(
                      height: 30, thickness: 1.5, color: Colors.orange),
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
                      if (widget.data['riderId'] == userId) ...[
                    const SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: () {
                        messageCustomer(widget.data['sellerId'], widget.data['sellerFirstName'], widget.data['sellerProfile']);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: CustomText(
                        textLabel: 'Chat with ${widget.data['sellerName']}',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                      ),
                    ),
                  ],
            
                ],
              ),
            ),
          ),
        ));
  }

  Future<void> _addToDeliveries(
      BuildContext context, Map<String, dynamic> data) async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      errorSnackbar(context, 'You must be logged in to place an order.');
      return;
    }

    try {
      final orderRef =
          FirebaseFirestore.instance.collection('orders').doc(data['orderId']);

      await orderRef.update({
        'riderId': userId,
        'status': 'shipped',
        'hasRider': true,
      });

      if (context.mounted) {
        successSnackbar(context, 'Order marked as delivery!');
      }
    } catch (error) {
      if (context.mounted) {
        errorSnackbar(context, 'Failed to mark as deliver: $error');
      }
    }
  }

  Future<void> _markAsDelivery(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
  ) async {
    setState(() => _isLoading = true);

    final orderRef =
        FirebaseFirestore.instance.collection('orders').doc(orderId);

    try {
      await _addToDeliveries(context, data);

      await orderRef.update({
        'status': 'shipped',
        'hasRider': true,
      });

      if (context.mounted) {
        successSnackbar(context, 'Order marked as Delivery!');
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

  Future<void> showCameraDialogAndUpload(
    BuildContext context,
    String orderId,
  ) async {
    final ImagePicker picker = ImagePicker();
    final rootContext = context;

    await showModalBottomSheet<String>(
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
                  Navigator.pop(context);
                  try {
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.camera);
                    if (pickedFile == null) return;

                    final croppedFile = await ImageCropper().cropImage(
                      sourcePath: pickedFile.path,
                      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                    );

                    if (croppedFile == null) return;

                    if (rootContext.mounted) {
                      showDialog(
                        context: rootContext,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                    }

                    final cloudinaryUrl =
                        await CloudinaryService.uploadImageToCloudinary(
                      File(croppedFile.path),
                    );

                    if (cloudinaryUrl == null) {
                      if (rootContext.mounted) {
                        Navigator.pop(rootContext);
                        errorSnackbar(rootContext, "Failed to upload image.");
                      }
                      return;
                    }

                    final now = Timestamp.now();

                    final orderRef = FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId);

                    await orderRef.update({
                      'deliveryProof': cloudinaryUrl,
                      'deliveryTimestamp': now,
                      'status': 'delivered',
                    });

                    if (rootContext.mounted) {
                      Navigator.pop(rootContext);
                      successSnackbar(
                        rootContext,
                        "Image uploaded and order marked as delivered.",
                      );
                    }
                  } catch (e) {
                    if (rootContext.mounted) {
                      Navigator.pop(rootContext);
                      errorSnackbar(rootContext, "Something went wrong: $e");
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

  Future<void> _cancelDelivery(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
  ) async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;
    if (userId == null) {
      errorSnackbar(context, 'User not logged in.');
      return;
    }

    setState(() => _isLoading = true);

    final orderRef =
        FirebaseFirestore.instance.collection('orders').doc(orderId);
    final riderDeliveryRef = FirebaseFirestore.instance
        .collection('riders')
        .doc(userId)
        .collection('deliveries')
        .doc(orderId);

    try {
      await Future.wait([
        orderRef.update({
          'hasRider': false,
          'riderId': null,
          'status': 'ordered',
        }),
        riderDeliveryRef.delete(),
      ]);

      if (context.mounted) {
        successSnackbar(context, 'Order Delivery Cancelled!');
      }
    } catch (e) {
      if (context.mounted) {
        errorSnackbar(context, 'Failed to cancel delivery: $e');
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
