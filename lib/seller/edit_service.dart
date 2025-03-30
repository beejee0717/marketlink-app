import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/components/product_image.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/seller/service_details.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../components/cloudinary.dart';
import '../components/categories.dart';

class SellerEditService extends StatefulWidget {
  final String serviceId;
  const SellerEditService({super.key, required this.serviceId});

  @override
  State<SellerEditService> createState() => _SellerEditServiceState();
}

class _SellerEditServiceState extends State<SellerEditService> {
  final serviceNameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final selectedLocation = TextEditingController();
  List<String> serviceDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];
  List<String> selectedDays = [];
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  String? selectedCategory;
  String? localImagePath;
  String? existingImagePath;

  List<String> locations = [];
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchServiceData();
  }

  Future<void> fetchServiceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          serviceNameController.text = data['serviceName'] ?? '';
          priceController.text = data['price']?.toString() ?? '';
          descriptionController.text = data['description'] ?? '';
          selectedCategory = data['category'] ?? 'Uncategorized';
          selectedLocation.text = data['serviceLocation'] ?? '';
          existingImagePath = data['imageUrl'];

          selectedDays = List<String>.from(data['availableDays'] ?? []);

          if (data['serviceHours'] != null) {
            startTime = _parseTime(data['serviceHours']['start']);
            endTime = _parseTime(data['serviceHours']['end']);
          }
        });
      } else {
        if (!mounted) return;
        errorSnackbar(context, 'Service not found.');
        navPop(context);
        navPushReplacement(
            context, SellerServiceDetails(serviceId: widget.serviceId));
      }
    } catch (e) {
      if (!mounted) return;
      errorSnackbar(context, 'Failed to fetch service data.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickTime(bool isStart) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (startTime ?? TimeOfDay.now())
          : (endTime ?? TimeOfDay.now()),
    );

    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          startTime = pickedTime;
        } else {
          endTime = pickedTime;
        }
      });
    }
  }

  TimeOfDay _parseTime(String? timeString) {
    if (timeString == null || !timeString.contains(':')) {
      return TimeOfDay.now(); 
    }
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

Future<void> updateService() async {
  FocusManager.instance.primaryFocus?.unfocus();

  if (!formKey.currentState!.validate()) {
    return;
  }

  if (selectedDays.isEmpty) {
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

  try {
    String imageUrl = existingImagePath ?? '';
    if (localImagePath != null) {
      final cloudinaryUrl = await CloudinaryService.uploadImageToCloudinary(
        File(localImagePath!),
      );

      if (cloudinaryUrl == null) {
        if (!mounted) return;
        errorSnackbar(context, 'Failed to upload service image.');
        return;
      }
      imageUrl = cloudinaryUrl;
    }

    if (selectedLocation.text.isEmpty) {
      if (!mounted) return;
      errorSnackbar(context, 'Please select a valid service location.');
      return;
    }

    final String formattedStartTime =
        "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}";
    final String formattedEndTime =
        "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}";

    List<String> searchKeywords = serviceNameController.text
        .trim()
        .toLowerCase()
        .split(' ')
        .toSet()
        .toList();

    await FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceId)
        .update({
      'serviceName': serviceNameController.text.trim(),
      'searchKeywords': searchKeywords,
      'category': selectedCategory ?? "Uncategorized",
      'price': double.parse(priceController.text.trim()),
      'description': descriptionController.text.trim(),
      'imageUrl': imageUrl,
      'serviceLocation': selectedLocation.text.trim(),
      'availableDays': selectedDays,
      'serviceHours': {
        'start': formattedStartTime,
        'end': formattedEndTime,
      },
    });

    if (!mounted) return;
    successSnackbar(context, "Service updated successfully!");

    navPop(context);
    navPushReplacement(
      context,
      SellerServiceDetails(serviceId: widget.serviceId),
    );
  } catch (e) {
    errorSnackbar(context, 'Failed to update service.');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: Colors.purple.shade900,
            title: const CustomText(
              textLabel: "Edit Service",
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
                      hintText: "Enter service name",
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
                    textLabel: "Select Service Days",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: serviceDays.map((day) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: selectedDays.contains(day),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedDays.add(day);
                                } else {
                                  selectedDays.remove(day);
                                }
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          SizedBox(width: 5),
                          CustomText(
                            textLabel: day,
                            fontSize: 14,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(
                    height: 10,
                  ),
                  const CustomText(
                    textLabel: "Service Location",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: selectedLocation,
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
                        updateService();
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
                        textLabel: "Edit Service",
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
}
