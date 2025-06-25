import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/provider/user_provider.dart';
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
    super.dispose();
  }

  final TextEditingController _addressController = TextEditingController();
  bool isEditingAddress = false;
  bool isAddressValid = true;
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
      debugging("Product Data: $productData");

      final sellerId = productData?['sellerId'];
      totalPrice = (productData?['price'] ?? 0).toDouble();

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
        _addressController.text = address ?? '';
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
    double unitPrice = (productData?['price'] ?? 0).toDouble();
    setState(() {
      totalPrice = unitPrice * quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    String selectedPaymentMethod = "Cash on Delivery";

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
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
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                        CustomText(
                          textLabel:
                              '₱${(productData?['price'] ?? 0).toStringAsFixed(2)}',
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
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppColors.purple),
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
                        errorText: isAddressValid ? null : 'Please add address',
                        suffixIcon: IconButton(
                          icon: Icon(
                            isEditingAddress ? Icons.check : Icons.edit,
                            color: AppColors.purple,
                          ),
                          onPressed: () {
                            setState(() {
                              isEditingAddress = !isEditingAddress;

                              if (!isEditingAddress) {
                                final newAddress =
                                    _addressController.text.trim();
                                isAddressValid = newAddress.isNotEmpty;

                                if (userId != null) {
                                  FirebaseFirestore.instance
                                      .collection('customers')
                                      .doc(userId)
                                      .update({'address': newAddress});
                                }
                              }
                            });
                          },
                        ),
                      ),
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
                      activeColor: AppColors.purple,
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
      bottomSheet: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
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
                        textColor: AppColors.purple,
                      ),
                      ElevatedButton(
                       onPressed: isAddressValid
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
                              isAddressValid ? AppColors.purple : Colors.grey,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                        ),
                        child: const Text(
                          'Buy Now',
                          style:
                              TextStyle(fontSize: 16, color: AppColors.white),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }

  Future<void> buyNow(String productId, String sellerId, int quantity, String deliveryAddress) async {
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
    final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
    final productSnapshot = await productRef.get();

    if (!productSnapshot.exists) {
      if (!mounted) return;
      errorSnackbar(context, "Product not found.");
      return;
    }

    final productData = productSnapshot.data()!;
    final double price = (productData['price'] as num).toDouble();
    final String sellerId = productData['sellerId'];

    final now = DateTime.now();
    final orderId = FirebaseFirestore.instance.collection('orders').doc().id;

    final ordersRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

    await ordersRef.set({
      'orderId': orderId,
      'customerId': userId,
      'productId': productId,
      'price': price,
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
}

}
