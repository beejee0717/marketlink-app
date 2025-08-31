import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/customer/product.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:provider/provider.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import '../provider/user_provider.dart';
//TODO: Finish cart section (button not showing, checkout process)
class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  State<CustomerCart> createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  List<Map<String, dynamic>> _cartItems = [];
  late AppEvent currentEvent = getCurrentEvent();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final cartItems = await fetchCartItems(userId);
    if (!mounted) return;
    setState(() {
      _cartItems = cartItems;
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchCartItems(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('cart')
        .get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> cartItems = [];
    for (var doc in querySnapshot.docs) {
      final productId = doc.id;
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      if (productDoc.exists) {
        final productData = productDoc.data()!;
        final sellerId = productData['sellerId'];

        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(sellerId)
            .get();

        if (sellerDoc.exists) {
          final sellerData = sellerDoc.data()!;
          cartItems.add({
            'productId': productId,
            'productName': productData['productName'],
            'price': productData['price'],
            'pickupLocation': productData['pickupLocation'],
            'quantity': doc['quantity'],
            'imageUrl': productData['imageUrl'],
            'contactNumber': sellerData['contactNumber'],
          });
        }
      }
    }
    return cartItems;
  }

  Future<void> updateQuantity(
      String userId, String productId, int quantity) async {
    final cartRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('cart')
        .doc(productId);

    if (quantity <= 0) {
      await cartRef.delete();
      setState(() {
        _cartItems.removeWhere((item) => item['productId'] == productId);
      });
      if (!mounted) return;
      successSnackbar(context, "Item removed from cart.");
    } else {
      await cartRef.update({'quantity': quantity});
      setState(() {
        final itemIndex =
            _cartItems.indexWhere((item) => item['productId'] == productId);
        if (itemIndex != -1) {
          _cartItems[itemIndex]['quantity'] = quantity;
        }
      });
    }
  }

Future<void> checkout(String userId) async {
  try {
    for (var item in _cartItems) {
      final productId = item['productId'];
      final quantity = item['quantity'];

      final orderId = FirebaseFirestore.instance
          .collection('orders') 
          .doc()
          .id;

      final now = Timestamp.now();

      final productOrdersRef = FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('orders')
          .doc(orderId);

      await productOrdersRef.set({
        'orderId': orderId,
        'userId': userId,
        'quantity': quantity,
        'dateOrdered': now,
        'status': 'ordered',
        'hasRider': false,
      });

      final customerOrdersRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(userId)
          .collection('orders')
          .doc(orderId);

      await customerOrdersRef.set({
        'orderId': orderId,
        'productId': productId,
        'quantity': quantity,
        'dateOrdered': now,
        'status': 'ordered',
        'hasRider': false,
      });
    }

    final cartRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('cart');

    final cartDocs = await cartRef.get();
    for (var doc in cartDocs.docs) {
      await doc.reference.delete();
    }

    setState(() {
      _cartItems.clear();
    });

    if (!mounted) return;
    successSnackbar(context, "Order placed successfully!");
  } catch (error) {
    errorSnackbar(context, "Failed to place order: $error");
  }
}

  void showCheckoutDialog(String userId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        double totalCost = 0;
        final groupedBySeller = <String, List<Map<String, dynamic>>>{};

        for (var item in _cartItems) {
          totalCost += (item['price'] * item['quantity']);
          final sellerId = item['pickupLocation'];
          groupedBySeller.putIfAbsent(sellerId, () => []).add(item);
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText(
                    textLabel: 'Checkout Summary',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 16),
                  ...groupedBySeller.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       
                        const SizedBox(height: 8),
                        ...entry.value.map((item) {
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['imageUrl'] ?? '',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, size: 40),
                              ),
                            ),
                            title: CustomText(
                              textLabel:
                                  item['productName'] ?? 'Unnamed Product',
                              fontSize: 16,
                            ),
                            subtitle: CustomText(
                              textLabel:
                                  'Quantity: ${item['quantity']} | ₱${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                              fontSize: 14,
                            ),
                          );
                        }),
                        const Divider(),
                      ],
                    );
                  }),
                  CustomText(
                    textLabel: "Total Cost: ₱${totalCost.toStringAsFixed(2)}",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    textColor: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          navPop(context);
                        },
                        child: CustomText(
                          textLabel: 'Cancel',
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await checkout(userId);
                        },
                        child: CustomText(
                          textLabel: 'Confirm',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      return Scaffold(
        body: const Center(
          child: CustomText(
            textLabel: 'You must be logged in to view your cart.',
            fontSize: 16,
            textColor: Colors.red,
          ),
        ),
      );
    }

    return Scaffold(
       appBar: AppBar(
    title:  CustomText(textLabel: 'Cart', fontSize: 25,textColor: headerTitleColor(currentEvent),),
    backgroundColor: backgroundColor(currentEvent),
    iconTheme: const IconThemeData(color: Colors.black),
  ),
  body: Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(backgroundImage(currentEvent)),
        fit: BoxFit.cover,
      ),
    ),
    child: isLoading
          ?  Center(
              child: SpinKitFadingCircle(
                size: 80,
                color: AppColors.primary,
              ),
            )
          : _cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      const CustomText(
                        textLabel: "Your cart is empty.",
                        fontSize: 18,
                        textColor: Colors.black,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final cartItem = _cartItems[index];
                          return GestureDetector(
                            onTap: () {
                              final productId = cartItem['productId'];
                              navPush(context,
                                  CustomerProduct(productId: productId));
                            },
                            child: Card(
                              color: const Color.fromARGB(164, 255, 255, 255),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      cartItem['imageUrl'] ?? '',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          textLabel: cartItem['productName'] ??
                                              'Unnamed Product',
                                          maxLines: 2,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        const SizedBox(height: 5),
                                        CustomText(
                                          textLabel:
                                              '₱${cartItem['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                          fontSize: 16,
                                          textColor: AppColors.primary,
                                        ),
                                       
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () => updateQuantity(
                                          userId,
                                          cartItem['productId'],
                                          cartItem['quantity'] + 1,
                                        ),
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        color: AppColors.primary,
                                      ),
                                      CustomText(
                                        textLabel:
                                            cartItem['quantity'].toString(),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      IconButton(
                                        onPressed: () => updateQuantity(
                                          userId,
                                          cartItem['productId'],
                                          cartItem['quantity'] - 1,
                                        ),
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () {
                          showCheckoutDialog(userId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                        ),
                        child: const CustomText(
                          textLabel: "Checkout",
                          fontSize: 18,
                          textColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),)
    );
  }
}
