import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/seller/product_details.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import '../components/cloudinary.dart';
import '../components/categories.dart';
import '../components/product_image.dart';
import '../provider/user_provider.dart';

class SellerEditProduct extends StatefulWidget {
  final String productId;
  const SellerEditProduct({super.key, required this.productId});

  @override
  State<SellerEditProduct> createState() => _SellerEditProductState();
}

class _SellerEditProductState extends State<SellerEditProduct> {
  final productNameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final descriptionController = TextEditingController();
  final materialsController = TextEditingController();
  final promoValueController = TextEditingController();
  late AppEvent currentEvent = getCurrentEvent();

  String? selectedCategory;
  String? localImagePath;
  String? existingImagePath;
  String? selectedPromoType;

  String? selectedLocation;
  List<String> locations = [];
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool hasPromo = false;

  @override
  void initState() {
    super.initState();
    fetchProductData();
    fetchSellerAddresses();
  }

  Future<void> fetchProductData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
   setState(() {
  productNameController.text = data['productName'] ?? '';
  priceController.text = data['price']?.toString() ?? '';
  stockController.text = data['stock']?.toString() ?? '';
  descriptionController.text = data['description'] ?? '';
  materialsController.text = data['materials'] ?? '';
  selectedCategory = data['category'] ?? 'Uncategorized';
  selectedLocation = data['pickupLocation'] ?? '';
  existingImagePath = data['imageUrl'];

  final promo = data['promo'];
  if (promo != null && promo['enabled'] == true) {
    hasPromo = true;
    selectedPromoType = promo['type'];
    promoValueController.text = promo['value'].toString();
  } else {
    hasPromo = false;
    selectedPromoType = null;
    promoValueController.clear();
  }
});

      } else {
        if (!mounted) return;
        errorSnackbar(context, 'Product not found.');
        navPop(context);
        navPushReplacement(
            context, SellerProductDetails(productId: widget.productId));
      }
    } catch (e) {
      if (!mounted) return;

      errorSnackbar(context, 'Failed to fetch product data.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchSellerAddresses() async {
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    final sellerId = userInfo?.uid ?? "";

    try {
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .get();

      if (sellerDoc.exists) {
        final data = sellerDoc.data();

        final List<dynamic> fetchedLocations = data?['addresses'] ?? [];
        setState(() {
          locations = fetchedLocations.cast<String>();
        });
      }
    } catch (e) {
      if (!mounted) return;

      errorSnackbar(context, 'Failed to fetch pickup locations.');
    }
  }

  Future<void> addNewAddress(String sellerId, String newAddress) async {
    if (locations.contains(newAddress)) {
      errorSnackbar(context, 'This address already exists.');
      return;
    }

    try {
      final sellerDoc =
          FirebaseFirestore.instance.collection('sellers').doc(sellerId);

      await sellerDoc.update({
        'addresses': FieldValue.arrayUnion([newAddress]),
      });

      setState(() {
        locations.add(newAddress);
        selectedLocation = newAddress;
      });

      if (!mounted) return;
      successSnackbar(context, 'Address added successfully.');
    } catch (e) {
      errorSnackbar(context, 'Failed to add address.');
    }
  }

 Future<void> updateProduct() async {
  FocusManager.instance.primaryFocus?.unfocus();

  if (!formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    String imageUrl = existingImagePath ?? '';
    if (localImagePath != null) {
      final cloudinaryUrl = await CloudinaryService.uploadImageToCloudinary(
        File(localImagePath!),
      );

      if (cloudinaryUrl == null) {
        if (!mounted) return;
        errorSnackbar(context, 'Failed to upload product image.');
        return;
      }
      imageUrl = cloudinaryUrl;
    }

    if (selectedLocation == null || selectedLocation!.isEmpty) {
      if (!mounted) return;

      errorSnackbar(context, 'Please select a valid pickup location.');
      return;
    }

    List<String> searchKeywords = productNameController.text
        .trim()
        .toLowerCase()
        .split(' ')
        .toSet()
        .toList();

    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .update({
      'productName': productNameController.text.trim(),
      'searchKeywords': searchKeywords,
      'category': selectedCategory ?? "Uncategorized",
      'price': double.parse(priceController.text.trim()),
      'stock': int.parse(stockController.text.trim()),
      'materials': materialsController.text.trim(),
      'description': descriptionController.text.trim(),
      'imageUrl': imageUrl,
      'pickupLocation': selectedLocation,
      "promo": hasPromo
    ? {
        "enabled": true,
        "type": selectedPromoType,
        "value": double.tryParse(promoValueController.text) ?? 0,
      }
    : {
        "enabled": false,
      },

    });

    if (!mounted) return;
    successSnackbar(context, "Product updated successfully!");

    navPop(context);
    navPushReplacement(
      context,
      SellerProductDetails(
        productId: widget.productId,
      ),
    );
  } catch (e) {
    errorSnackbar(context, 'Failed to update product.');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    final sellerId = userInfo?.uid ?? "";

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ModalProgressHUD(
        inAsyncCall: isLoading,
        color: Colors.black,
        progressIndicator: const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 5,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                navPop(context);
              },
              icon:  Icon(
                Icons.arrow_back,
                color:  currentEvent == AppEvent.none ? Colors.white :headerTitleColor(currentEvent),
              ),
            ),
            backgroundColor: currentEvent == AppEvent.none ? AppColors.primary :backgroundColor(currentEvent),
            title:  CustomText(
              textLabel: "Edit Product",
              fontSize: 22,
              fontWeight: FontWeight.bold,
              textColor: currentEvent == AppEvent.none ? Colors.white :headerTitleColor(currentEvent),
            ),
            centerTitle: true,
          ),
          body: Container(decoration: BoxDecoration(
          image: DecorationImage(image: 
          AssetImage(backgroundImage(currentEvent)),
          fit: BoxFit.cover)
        ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: ProductImage(
                          imageUrl: localImagePath ?? existingImagePath,
                          onFileChanged: (imagePath) {
                            setState(() {
                              localImagePath = imagePath;
                            });
                          },
                          onLoadingChanged: (loading) {
                            setState(() {
                              isLoading = loading;
                            });
                          },
                        ),
                      ),
                    ),
                    const CustomText(
                      textLabel: "Product Name",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: productNameController,
                      maxLength: 50,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        hintText: "Enter product name",
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Product name is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const CustomText(
                      textLabel: "Category",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      hint: const CustomText(
                        textLabel: "Select Category",
                        fontSize: 14,
                        textColor: Colors.grey,
                      ),
                      items: productCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: CustomText(
                            textLabel: category,
                            fontSize: 14,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Category is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const CustomText(
                      textLabel: "Price (₱)",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        hintText: "Enter price",
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Price is required";
                        }
                        if (double.tryParse(value) == null) {
                          return "Enter a valid number";
                        }
                        return null;
                      },
                    ),
  const SizedBox(height: 20),
Row(
  children: [
    Checkbox(
      value: hasPromo,
      onChanged: (value) {
        setState(() {
          hasPromo = value ?? false;
          if (!hasPromo) {
            selectedPromoType = null;
            promoValueController.clear();
          }
        });
      },
    ),
    const CustomText(
      textLabel: "Add Promo",
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ],
),
if (hasPromo) ...[
  const SizedBox(height: 10),
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const CustomText(
        textLabel: "Promo Type",
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      IconButton(
        icon: Icon(
          Icons.info_outline,
          size: 20,
          color: Colors.grey.shade700,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Promo Type Info"),
                content: const Text(
                  "Promos are applied per item.\n\n"
                  "• Percentage: Deducts a percentage of the price for each item.\n"
                  "   Example: 10 = 10% off each item\n\n"
                  "• Fixed Amount: Deducts a peso amount per item.\n"
                  "   Example: 50 = ₱50 off per item\n\n"
                  "If the buyer purchases multiple quantities, the discount is applied to each one.",
                  style: TextStyle(fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Got it"),
                  ),
                ],
              );
            },
          );
        },
      ),
    ],
  ),
  const SizedBox(height: 10),
  DropdownButtonFormField<String>(
    value: selectedPromoType,
    decoration: InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    hint: const Text("Select promo type"),
    items: const [
      DropdownMenuItem(value: "percentage", child: Text("Percentage")),
      DropdownMenuItem(value: "fixed", child: Text("Fixed Amount")),
    ],
    onChanged: (value) {
      setState(() {
        selectedPromoType = value;
      });
    },
    validator: (value) {
      if (hasPromo && (value == null || value.isEmpty)) {
        return "Select a promo type";
      }
      return null;
    },
  ),
  const SizedBox(height: 20),
  const CustomText(
    textLabel: "Promo Value",
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
  const SizedBox(height: 10),
TextFormField(
  controller: promoValueController,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    hintText: selectedPromoType == "percentage"
        ? "Enter percentage (e.g. 20)"
        : "Enter fixed amount (e.g. 100)",
  ),
  validator: (value) {
    if (hasPromo) {
      if (value == null || value.trim().isEmpty) {
        return "Promo value is required";
      }

      final promoValue = double.tryParse(value);
      final priceValue = double.tryParse(priceController.text);

      if (promoValue == null) {
        return "Enter a valid number";
      }

      if (selectedPromoType == "fixed" && priceValue != null) {
        if (promoValue >= priceValue) {
          return "Fixed discount must be less than product price";
        }
      }

      if (selectedPromoType == "percentage") {
        if (promoValue >= 100) {
          return "Percentage must be less than 100%";
        }
      }
    }
    return null;
  },
),

 const SizedBox(height: 20),
],


  const SizedBox(height: 20),
                    const CustomText(
                      textLabel: "Stock Quantity",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      maxLength: 7,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        hintText: "Enter stock quantity",
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Stock quantity is required";
                        }
                        if (int.tryParse(value) == null) {
                          return "Enter a valid number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const CustomText(
                      textLabel: "Pickup Location",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      hint: const CustomText(
                        textLabel: "Select Pickup Location",
                        fontSize: 14,
                        textColor: Colors.grey,
                      ),
                      items: [
                        ...locations.map(
                          (location) => DropdownMenuItem<String>(
                            value: location,
                            child: CustomText(
                              textLabel: location,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (locations.length < 5)
                          const DropdownMenuItem<String>(
                            value: "AddNew",
                            child: CustomText(
                              textLabel: "Add New Address",
                              fontSize: 14,
                              textColor: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == "AddNew") {
                          showAddAddressDialog(sellerId);
                        } else {
                          setState(() {
                            selectedLocation = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            value == 'AddNew') {
                          return "Pickup location is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const CustomText(
                      textLabel: "Materials (Optional)",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: materialsController,
                      maxLength: 100,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        hintText: "Enter materials used",
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomText(
                      textLabel: "Description",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        hintText: "Enter product description",
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Description is required";
                        }
            
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          updateProduct();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const CustomText(
                          textLabel: "Edit Product",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          textColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showAddAddressDialog(String sellerId) {
    final formKey = GlobalKey<FormState>();
    final newAddressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CustomText(
                    textLabel: "Add New Address",
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: newAddressController,
                  decoration: InputDecoration(
                    hintText: "Enter new address",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Address cannot be empty.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => navPop(context),
                      child: CustomText(
                        textLabel: "Cancel",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final newAddress = newAddressController.text.trim();
                          addNewAddress(sellerId, newAddress);
                          navPop(context);
                        }
                      },
                      child: CustomText(
                        textLabel: "Add",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
