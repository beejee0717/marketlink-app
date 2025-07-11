import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/categories.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/seller/home.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import '../components/cloudinary.dart';
import '../components/product_image.dart';
import '../provider/user_provider.dart';

class SellerAddService extends StatefulWidget {
  const SellerAddService({super.key});

  @override
  State<SellerAddService> createState() => _SellerAddServiceState();
}

class _SellerAddServiceState extends State<SellerAddService> {
  final serviceNameController = TextEditingController();
  late AppEvent currentEvent = getCurrentEvent();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final promoValueController = TextEditingController();
  List<String> availableDays = [];
  List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? selectedPromoType;

  String? selectedCategory;
  String? localImagePath;
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool? showWarning;
  bool hasPromo = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> pickTime(bool isStart) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isStart ? startTime ?? TimeOfDay.now() : endTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  Future<void> addService(String sellerId) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }
    if (localImagePath == null) {
      errorSnackbar(context, 'Please upload a Service image.');
      return;
    }
    if (availableDays.isEmpty) {
      errorSnackbar(context, 'Please select at least one available day.');
      return;
    }
    if (startTime == null || endTime == null) {
      errorSnackbar(context, 'Please select service hours.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String formattedStartTime =
        "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}";
    final String formattedEndTime =
        "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}";

    try {
      final cloudinaryUrl = await CloudinaryService.uploadImageToCloudinary(
          File(localImagePath!));

      if (cloudinaryUrl == null) {
        if (!mounted) return;
        errorSnackbar(context, 'Failed to upload Service image.');
        return;
      }

      List<String> searchKeywords = serviceNameController.text
          .trim()
          .toLowerCase()
          .split(' ')
          .toSet()
          .toList();

      await FirebaseFirestore.instance.collection('services').add({
        'serviceName': serviceNameController.text.trim(),
        'searchKeywords': searchKeywords,
        'price': double.parse(priceController.text.trim()),
        'description': descriptionController.text.trim(),
        'sellerId': sellerId,
        'imageUrl': cloudinaryUrl,
        'serviceLocation': addressController.text.trim(),
        'dateCreated': FieldValue.serverTimestamp(),
        'category': selectedCategory,
        'availableDays': availableDays,
        'serviceHours': {
          'start': formattedStartTime,
          'end': formattedEndTime,
        },
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
      successSnackbar(context, "Service added successfully!");

      serviceNameController.clear();
      priceController.clear();
      stockController.clear();
      descriptionController.clear();
      addressController.clear();
      setState(() {
        selectedCategory = null;
        localImagePath = null;
        availableDays.clear();
        startTime = null;
        endTime = null;
      });

      if (showWarning != null && showWarning == true) {
        showWarningDialog();
      } else {
        navPushRemove(context, const SellerHome());
      }
    } catch (e) {
      debugPrint('Debug Error: $e');
      errorSnackbar(context, 'Failed to add service.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
              icon: Icon(
                Icons.arrow_back,
                color: currentEvent == AppEvent.none
                    ? Colors.white
                    : headerTitleColor(currentEvent),
              ),
            ),
            backgroundColor: currentEvent == AppEvent.none
                ? Colors.purple.shade800
                : backgroundColor(currentEvent),
            title: CustomText(
              textLabel: "Add Service",
              fontSize: 22,
              fontWeight: FontWeight.bold,
              textColor: currentEvent == AppEvent.none
                  ? Colors.white
                  : headerTitleColor(currentEvent),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(backgroundImage(currentEvent)),
                    fit: BoxFit.cover)),
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
                      textLabel: "Service Name",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: serviceNameController,
                      maxLength: 50,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        hintText: "Enter Service Name",
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Service name is required";
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
                      items: serviceCategories.map((category) {
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
                    const SizedBox(height: 20,),
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
                        children: [
                          const CustomText(
                            textLabel: "Promo Type",
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              size: 30,
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
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
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
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        hint: const Text("Select promo type"),
                        items: const [
                          DropdownMenuItem(
                              value: "percentage", child: Text("Percentage")),
                          DropdownMenuItem(
                              value: "fixed", child: Text("Fixed Amount")),
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
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
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
                            final priceValue =
                                double.tryParse(priceController.text);

                            if (promoValue == null) {
                              return "Enter a valid number";
                            }

                            if (selectedPromoType == "fixed" &&
                                priceValue != null) {
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
    
                    const SizedBox(
                      height: 20,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomText(
                          textLabel: "Available Days",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        Wrap(
                          spacing: 10,
                          children: daysOfWeek.map((day) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: availableDays.contains(day),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        availableDays.add(day);
                                      } else {
                                        availableDays.remove(day);
                                      }
                                    });
                                  },
                                ),
                                CustomText(
                                  textLabel: day,
                                  fontSize: 14,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomText(
                          textLabel: "Service Hours",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => pickTime(true),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    startTime != null
                                        ? startTime!.format(context)
                                        : "Start Time",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => pickTime(false),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    endTime != null
                                        ? endTime!.format(context)
                                        : "End Time",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const CustomText(
                      textLabel: "Service Address",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressController,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        hintText: "Enter Service Address",
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Address is required";
                        }

                        return null;
                      },
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
                        hintText: "Enter service description",
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
                          addService(sellerId);
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
                          textLabel: "Add Service",
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
                        "All Services must be approved by the admin before they are visible to customers for ordering. Please wait for the admin's approval.",
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
