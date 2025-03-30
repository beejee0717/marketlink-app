import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/seller/home.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import '../components/cloudinary.dart';
import '../components/categories.dart';
import '../components/product_image.dart';
import '../provider/user_provider.dart';

class SellerAddProduct extends StatefulWidget {
  const SellerAddProduct({super.key});

  @override
  State<SellerAddProduct> createState() => _SellerAddProductState();
}

class _SellerAddProductState extends State<SellerAddProduct> {
  final productNameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final descriptionController = TextEditingController();
  final materialsController = TextEditingController();
  String? selectedCategory;
  String? localImagePath;
  String? selectedLocation;
  List<String> locations = [];
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool? showWarning;





  @override
  void initState() {
    super.initState();
    fetchSellerAddresses();
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
          showWarning = data?['showWarning'] ?? false;
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

Future<void> addProduct(String sellerId) async {
  FocusManager.instance.primaryFocus?.unfocus();

  if (!formKey.currentState!.validate()) {
    return;
  }
  if (localImagePath == null) {
    errorSnackbar(context, 'Please upload a product image.');
    return;
  }
  setState(() {
    isLoading = true;
  });

  try {
    final cloudinaryUrl = await CloudinaryService.uploadImageToCloudinary(
        File(localImagePath!));

    if (cloudinaryUrl == null) {
      if (!mounted) return;
      errorSnackbar(context, 'Failed to upload product image.');
      return;
    }
    if (selectedLocation == null || selectedLocation == "AddNew") {
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

    await FirebaseFirestore.instance.collection('products').add({
      'productName': productNameController.text.trim(),
      'searchKeywords': searchKeywords, 
      'category': selectedCategory ?? "Uncategorized",
      'price': double.parse(priceController.text.trim()),
      'stock': int.parse(stockController.text.trim()),
      'materials': materialsController.text.trim(),
      'description': descriptionController.text.trim(),
      'sellerId': sellerId,
      'imageUrl': cloudinaryUrl,
      'pickupLocation': selectedLocation,
      'dateCreated': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    successSnackbar(context, "Product added successfully!");

    productNameController.clear();
    priceController.clear();
    stockController.clear();
    descriptionController.clear();
    materialsController.clear();
    setState(() {
      selectedCategory = null;
      localImagePath = null;
      selectedLocation = null;
    });

    if (showWarning != null && showWarning == true) {
      showWarningDialog();
    } else {
      navPushRemove(context, const SellerHome());
    }
  } catch (e) {
    errorSnackbar(context, 'Failed to add product.');
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
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.purple.shade800,
            title: const CustomText(
              textLabel: "Add Product",
              fontSize: 22,
              fontWeight: FontWeight.bold,
              textColor: Colors.white,
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
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
                        imageUrl: localImagePath,
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
                        addProduct(sellerId);
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
                        textLabel: "Add Product manually",
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

  void showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool checkboxValue = false;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomText(
                    textLabel: "Important Notice",
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const CustomText(
                    textLabel:
                        "All products must be approved by the admin before they are visible to customers for ordering. Please wait for the admin's approval.",
                    fontSize: 16,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: checkboxValue,
                        onChanged: (bool? value) {
                          setState(() {
                            checkboxValue = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: CustomText(
                          textLabel: "Do not show this message again.",
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      if (checkboxValue) {
                        final userInfo =
                            Provider.of<UserProvider>(context, listen: false)
                                .user;
                        final sellerId = userInfo?.uid ?? "";

                        FirebaseFirestore.instance
                            .collection('sellers')
                            .doc(sellerId)
                            .update({'showWarning': false});
                      }
                      navPushRemove(context, const SellerHome());
                    },
                    child: const CustomText(
                      textLabel: "Continue",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}
