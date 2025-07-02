import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/notif.dart';
import 'package:provider/provider.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/components/navigator.dart';
import '../provider/user_provider.dart';
import 'product.dart';

class CustomerWishlist extends StatefulWidget {
  const CustomerWishlist({super.key});

  @override
  State<CustomerWishlist> createState() => _CustomerWishlistState();
}

class _CustomerWishlistState extends State<CustomerWishlist> {
  List<Map<String, dynamic>> _wishlistItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlistItems();
  }

  Future<void> _loadWishlistItems() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final wishlistItems = await fetchWishlistItems(userId);
    if (!mounted) return;
    setState(() {
      _wishlistItems = wishlistItems;
      isLoading = false;
    });
  }

Future<List<Map<String, dynamic>>> fetchWishlistItems(String userId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('wishlists')
      .where('customerId', isEqualTo: userId)
      .get();

  if (querySnapshot.docs.isEmpty) {
    debugPrint('No wishlist items found for user: $userId');
    return [];
  }

  List<Map<String, dynamic>> wishlistItems = [];

  for (var doc in querySnapshot.docs) {
    final productId = doc['productId']; 

    final productDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();

    if (productDoc.exists) {
      final productData = productDoc.data()!;
      wishlistItems.add({
        'productId': productId,
        'productName': productData['productName'],
        'price': productData['price'],
        'pickupLocation': productData['pickupLocation'],
        'imageUrl': productData['imageUrl'],
        'sellerId': productData['sellerId'], 
      });
    } else {
      debugPrint('⚠️ Product not found: $productId');
    }
  }

  return wishlistItems;
}


  Future<void> removeFromWishlist(String userId, String productId) async {
    final wishlistRef = FirebaseFirestore.instance
        .collection('wishlists')
        .doc('${userId}_$productId');
    await wishlistRef.delete();
    setState(() {
      _wishlistItems.removeWhere((item) => item['productId'] == productId);
    });
    if (!mounted) return;
    successSnackbar(context, "Product removed from your wishlist.");
  }

  void showAddToCartDialog(
      String productId, String sellerId, double pricePerUnit) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    int quantity = 1;
    double totalPrice = pricePerUnit;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CustomText(
                        textLabel: "Add to Cart",
                        fontSize: 20,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 30),
                      const CustomText(
                        textLabel: "Enter the quantity:",
                        fontSize: 16,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                  totalPrice = pricePerUnit * quantity;
                                });
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                          ),
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              readOnly: true,
                              key: ValueKey(quantity),
                              initialValue: quantity.toString(),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                final int? input = int.tryParse(value ?? "");
                                if (input == null || input <= 0) {
                                  return "Invalid quantity";
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                quantity++;
                                totalPrice = pricePerUnit * quantity;
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppColors.purple),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CustomText(
                        textLabel:
                            "Total Price: ₱${totalPrice.toStringAsFixed(2)}",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        textColor: AppColors.purple,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final userId = Provider.of<UserProvider>(context,
                                      listen: false)
                                  .user
                                  ?.uid;
                              if (!formKey.currentState!.validate() ||
                                  userId == null) {
                                errorSnackbar(context, 'Invalid action.');
                                return;
                              }

                              await addToCart(
                                  userId, productId, sellerId, quantity);
                              await removeFromWishlist(userId, productId);

                              if (!context.mounted) return;
                              navPop(context);
                              successSnackbar(
                                  context, "Product added to cart.");
                            },
                            child: const CustomText(
                              textLabel: 'Confirm',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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

  Future<void> addToCart(
      String userId, String productId, String sellerId, int quantity) async {
    final cartRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(userId)
        .collection('cart')
        .doc(productId);

    final cartDoc = await cartRef.get();

    if (cartDoc.exists) {
      await cartRef.update({'quantity': FieldValue.increment(quantity)});
    } else {
      await cartRef.set({'sellerId': sellerId, 'quantity': quantity});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    if (userId == null) {
      return Scaffold(
        body: const Center(
          child: CustomText(
            textLabel: 'You must be logged in to view your wishlist.',
            fontSize: 16,
            textColor: Colors.red,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(textLabel: 'Wishlist', fontSize: 25),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(
              child: SpinKitFadingCircle(
                size: 80,
                color: AppColors.purple,
              ),
            )
          : _wishlistItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      const CustomText(
                        textLabel: "Your wishlist is empty.",
                        fontSize: 18,
                        textColor: Colors.grey,
                      ),
                      ElevatedButton(
  onPressed: () {
    NotificationService.showNotification(
      title: 'Hello!',
      body: 'This is your first notification 🎉',
    );
  },
  child: Text('Show Notification'),
)

                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _wishlistItems.length,
                  itemBuilder: (context, index) {
                    final wishlistItem = _wishlistItems[index];
                    return GestureDetector(
                      onTap: () {
                        final productId = wishlistItem['productId'];
                        navPush(context, CustomerProduct(productId: productId));
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              wishlistItem['imageUrl'] ?? '',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
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
                          title: CustomText(
                            textLabel: wishlistItem['productName'] ??
                                'Unnamed Product',
                            fontSize: 18,
                            maxLines: 2,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                textLabel:
                                    '₱${wishlistItem['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                fontSize: 16,
                                textColor: AppColors.purple,
                              ),
                              const SizedBox(height: 5),
                              ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_shopping_cart),
                                onPressed: () => showAddToCartDialog(
                                    wishlistItem['productId'],
                                    wishlistItem['sellerId'],
                                    wishlistItem['price']),
                                color: AppColors.purple,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => removeFromWishlist(
                                  userId,
                                  wishlistItem['productId'],
                                ),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
