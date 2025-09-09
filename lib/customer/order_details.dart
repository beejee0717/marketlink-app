import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketlinkapp/api/ai_recommendation/send_event.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:provider/provider.dart';
import '../components/auto_size_text.dart';
import '../components/navigator.dart';

class OrderDetails extends StatefulWidget {
  final String productId;

  const OrderDetails({super.key, required this.productId});

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  bool _isLoading = true;
  late AppEvent currentEvent = getCurrentEvent();

  Map<String, dynamic>? productData;
  Map<String, dynamic>? sellerData;
  Map<String, dynamic>? customerData;

  int quantity = 1;
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    fetchAllDetails();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  bool isEditingAddress = false;
  bool isAddressValid = true;
  bool isEditingContactNumer = false;
  bool isContactNumberValid = true;
  double shippingFee = 25.00;
  String? userId;

  Future<void> fetchAllDetails() async {
    try {
      userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

      final productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (!productSnapshot.exists) {
        debugging("Product not found");
        setState(() => _isLoading = false);
        return;
      }

      productData = productSnapshot.data();

      final sellerId = productData?['sellerId'];

      final double originalPrice = (productData?['price'] ?? 0).toDouble();
      double finalPrice = originalPrice;

      final promo = productData?['promo'];
      final hasPromo = promo != null && promo['enabled'] == true;

      if (hasPromo) {
        final promoType = promo['type'];
        final promoValue = (promo['value'] ?? 0).toDouble();

        if (promoType == 'percentage') {
          finalPrice -= (originalPrice * promoValue / 100);
        } else if (promoType == 'fixed') {
          finalPrice -= promoValue;
        }

        finalPrice = finalPrice.clamp(0, double.infinity);
      }

      totalPrice = finalPrice * quantity + shippingFee;

      productData?['finalPrice'] = finalPrice;

      if (sellerId != null) {
        final sellerSnapshot = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(sellerId)
            .get();
        sellerData = sellerSnapshot.data();
      }

      if (userId != null) {
        final customerSnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .doc(userId)
            .get();

        customerData = customerSnapshot.data();

        String? address = customerData?['address'];
        String? contactNumber = customerData?['contactNumber'];
        _contactNumberController.text = contactNumber ?? '';
        _addressController.text = address ?? '';
        isContactNumberValid =
            (contactNumber != null && contactNumber.trim().isNotEmpty);
        isAddressValid = (address != null && address.trim().isNotEmpty);
      }
    } catch (e) {
      debugging("Error fetching data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void updateTotalPrice() {
    double basePrice = (productData?['price'] ?? 0).toDouble();

    final promo = productData?['promo'];
    final hasPromo = promo != null && promo['enabled'] == true;

    if (hasPromo) {
      final promoType = promo['type'];
      final promoValue = (promo['value'] ?? 0).toDouble();

      if (promoType == 'percentage') {
        basePrice -= basePrice * (promoValue / 100);
      } else if (promoType == 'fixed') {
        basePrice -= promoValue;
      }

      basePrice = basePrice.clamp(0, double.infinity);
      productData?['finalPrice'] = basePrice;
    }

    setState(() {
      totalPrice = basePrice * quantity + shippingFee;
    });
  }

  @override
  Widget build(BuildContext context) {
    String selectedPaymentMethod = "Cash on Delivery";
    final double originalPrice = (productData?['price'] ?? 0).toDouble();
    final double finalPrice =
        (productData?['finalPrice'] ?? originalPrice).toDouble();
    final hasPromo = productData?['promo']?['enabled'] == true;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: backgroundColor(currentEvent),
        leading: IconButton(
          onPressed: () => navPop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0,
        title: const CustomText(
          textLabel: 'Order Details',
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundImage(currentEvent)),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(child: CircularProgressIndicator()))
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundImage(currentEvent)),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 8, bottom: 100),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (productData?['imageUrl'] != null)
                        Center(
                          child: Image.network(
                            productData!['imageUrl'],
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      CustomText(
                        textLabel:
                            '${productData?['productName'] ?? 'No Product Name'}',
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const CustomText(textLabel: 'Price: ', fontSize: 18),
                          if (hasPromo) ...[
                            CustomText(
                              textLabel:
                                  '₱${originalPrice.toStringAsFixed(2)} ',
                              fontSize: 16,
                              textColor: Colors.grey,
                              fontWeight: FontWeight.normal,
                              decoration: TextDecoration.lineThrough,
                            ),
                            const SizedBox(width: 5),
                            CustomText(
                              textLabel: '₱${finalPrice.toStringAsFixed(2)}',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              textColor: Colors.orange,
                            ),
                          ] else
                            CustomText(
                              textLabel: '₱${originalPrice.toStringAsFixed(2)}',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(textLabel: 'Quantity', fontSize: 16),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: () {
                                  if (quantity > 1) {
                                    setState(() {
                                      quantity--;
                                      updateTotalPrice();
                                    });
                                  }
                                },
                              ),
                              Text(
                                '$quantity',
                                style: const TextStyle(fontSize: 16),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: AppColors.primary),
                                onPressed: () {
                                  setState(() {
                                    quantity++;
                                    updateTotalPrice();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      Divider(
                        color: AppColors.grey,
                        thickness: 2,
                      ),
                      const SizedBox(height: 10),
                      const CustomText(
                        textLabel: "Delivery Address",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        readOnly: !isEditingAddress,
                        onChanged: (value) {
                          setState(() {
                            isAddressValid = value.trim().isNotEmpty;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter delivery address',
                          hintStyle: TextStyle(
                            color: isAddressValid ? Colors.grey : Colors.red,
                          ),
                          border: const OutlineInputBorder(),
                          errorText:
                              isAddressValid ? null : 'Please add address',
                          suffixIcon: isEditingAddress
                              ? SizedBox(
                                  width: 80, // adjust as needed
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          final newAddress =
                                              _addressController.text.trim();
                                          isAddressValid =
                                              newAddress.isNotEmpty;

                                          if (isAddressValid &&
                                              userId != null) {
                                            FirebaseFirestore.instance
                                                .collection('customers')
                                                .doc(userId)
                                                .update(
                                                    {'address': newAddress});
                                          }

                                          isEditingAddress = false;
                                        });
                                      },
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(Icons.edit,
                                      color: AppColors.primary),
                                  onPressed: () {
                                    setState(() {
                                      isEditingAddress = true;
                                    });
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const CustomText(
                        textLabel: "Contact Number",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contactNumberController,
                        readOnly: !isEditingContactNumer,
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        onChanged: (value) {
                          setState(() {
                            isContactNumberValid = value.trim().isNotEmpty;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter contact number',
                          hintStyle: TextStyle(
                            color:
                                isContactNumberValid ? Colors.grey : Colors.red,
                          ),
                          border: const OutlineInputBorder(),
                          errorText: isContactNumberValid
                              ? null
                              : 'Please add contact number',
                          suffixIcon: isEditingContactNumer
                              ? SizedBox(
                                  width: 80,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          final newContactNum =
                                              _contactNumberController.text
                                                  .trim();
                                          isContactNumberValid =
                                              newContactNum.isNotEmpty;

                                          if (isContactNumberValid &&
                                              userId != null) {
                                            FirebaseFirestore.instance
                                                .collection('customers')
                                                .doc(userId)
                                                .update({
                                              'contactNumber': newContactNum
                                            });
                                          }

                                          isEditingContactNumer = false;
                                        });
                                      },
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(Icons.edit,
                                      color: AppColors.primary),
                                  onPressed: () {
                                    setState(() {
                                      isEditingContactNumer = true;
                                    });
                                  },
                                ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          const CustomText(
                              textLabel: 'Shipping Fee: ', fontSize: 18),
                          CustomText(
                            textLabel: '₱25.00',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )
                        ],
                      ),
                      SizedBox(height: 10),
                      Divider(
                        color: AppColors.grey,
                        thickness: 2,
                      ),
                      SizedBox(height: 10),
                      const CustomText(
                        textLabel: "Payment Method",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      RadioListTile<String>(
                        title: const Text("Cash on Delivery"),
                        value: "Cash on Delivery",
                        groupValue: selectedPaymentMethod,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentMethod = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomSheet: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor(currentEvent),
                border: Border(
                  top: BorderSide(color: Colors.grey, width: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        textLabel: 'Total: ₱${totalPrice.toStringAsFixed(2)}',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        textColor: AppColors.primary,
                      ),
                      ElevatedButton(
                        onPressed: isAddressValid && isContactNumberValid
                            ? () {
                                buyNow(
                                  widget.productId,
                                  productData?['sellerId'],
                                  quantity,
                                  _addressController.text.trim(),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAddressValid && isContactNumberValid
                                  ? AppColors.primary
                                  : Colors.grey,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                        ),
                        child:  Text(
                          'Buy Now',
                          style:
                              TextStyle(fontSize: 16, color: currentEvent == AppEvent.christmas ? Colors.black:AppColors.white),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }

  Future<void> buyNow(String productId, String sellerId, int quantity,
      String deliveryAddress) async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      errorSnackbar(context, "You must be logged in to place an order.");
      return;
    }

    if (deliveryAddress.trim().isEmpty) {
      errorSnackbar(context, "Please provide a valid delivery address.");
      return;
    }

    try {
      final productRef =
          FirebaseFirestore.instance.collection('products').doc(productId);
      final productSnapshot = await productRef.get();

      if (!productSnapshot.exists) {
        if (!mounted) return;
        errorSnackbar(context, "Product not found.");
        return;
      }

      final productData = productSnapshot.data()!;
      final String sellerId = productData['sellerId'];
      double originalPrice = (productData['price'] as num).toDouble();
      double finalPrice = originalPrice;

      final promo = productData['promo'];
      final hasPromo = promo != null && promo['enabled'] == true;

      if (hasPromo) {
        final promoType = promo['type'];
        final promoValue = (promo['value'] ?? 0).toDouble();

        if (promoType == 'percentage') {
          finalPrice -= originalPrice * (promoValue / 100);
        } else if (promoType == 'fixed') {
          finalPrice -= promoValue;
        }

        finalPrice = finalPrice.clamp(0, double.infinity);
      }

      final double totalPayment = finalPrice * quantity + shippingFee;

      final now = DateTime.now();
      final orderId = FirebaseFirestore.instance.collection('orders').doc().id;

      final ordersRef =
          FirebaseFirestore.instance.collection('orders').doc(orderId);

      await ordersRef.set({
        'orderId': orderId,
        'customerId': userId,
        'productId': productId,
        'price': finalPrice,
        'totalPayment': totalPayment,
        'sellerId': sellerId,
        'quantity': quantity,
        'dateOrdered': now,
        'status': 'ordered',
        'hasRider': false,
        'deliveryAddress': deliveryAddress,
      });

      if (!mounted) return;
      successSnackbar(context, "Order placed successfully!");
      navPop(context);
    } catch (error) {
      if (!mounted) return;
      errorSnackbar(context, "Failed to place order: $error");
    }
    await sendEvent(userId, 'purchase', productId: productId);
  }
}
