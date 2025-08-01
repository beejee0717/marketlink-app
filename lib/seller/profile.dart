import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketlinkapp/components/editable_textfield.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/onboarding/login.dart';
import 'package:marketlinkapp/theme/event_theme.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

import '../components/auto_size_text.dart';
import '../components/cloudinary.dart';
import '../components/dialog.dart';
import '../components/navigator.dart';
import '../components/user_info.dart';
import '../provider/user_provider.dart';

class SellerProfile extends StatefulWidget {
  const SellerProfile({super.key});

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  bool isLoading = false;
  bool isEditingFirstName = false;
  bool isEditingLastName = false;
  bool isEditingContact = false;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  late AppEvent currentEvent = getCurrentEvent();
  List<String> addresses = [];
  @override
  void initState() {
    super.initState();
    _fetchSellerData();
     final user = Provider.of<UserProvider>(context, listen: false).user!;
    firstNameController.text = user.firstName;
    lastNameController.text = user.lastName;
    contactController.text = user.contactNumber;
  }
 void saveField(String field, String value) async {
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      await FirebaseFirestore.instance.collection('sellers').doc(uid).update({
        field: value,
      });

      if (!mounted) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final updatedUser = userProvider.user!.copyWith(
        firstName: field == 'firstName' ? value : userProvider.user!.firstName,
        lastName: field == 'lastName' ? value : userProvider.user!.lastName,
        contactNumber:
            field == 'contactNumber' ? value : userProvider.user!.contactNumber,
      );
      userProvider.setUser(updatedUser);
    }
    successSnackbar(context, 'Updated Successfully!');

    if (mounted) setState(() => isLoading = false);
  }


  Future<void> _fetchSellerData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(user.uid)
            .get();

        if (sellerDoc.exists) {
          final data = sellerDoc.data()!;
          setState(() {
            addresses = List<String>.from(data['addresses'] ?? []);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      errorSnackbar(context, "Failed to load seller data.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addAddress() async {
    if (addresses.length >= 5) {
      errorSnackbar(context, "You can only add up to 5 addresses.");
      return;
    }

    final TextEditingController controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Address"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Address cannot be empty.";
                }
                return null;
              },
              decoration: const InputDecoration(
                  labelText: "Enter Address", counterText: ''),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
            
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    addresses.add(controller.text.trim());
                  });
                  await _saveAddresses();
                  if (!context.mounted) return;
                  navPop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeAddress(int index) async {
    setState(() {
      addresses.removeAt(index);
    });
    await _saveAddresses();
  }

  Future<void> _saveAddresses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('sellers')
            .doc(user.uid)
            .update({'addresses': addresses});
        if (!mounted) return;

        successSnackbar(context, "Addresses updated successfully.");
      }
    } catch (e) {
      errorSnackbar(context, "Failed to update addresses.");
    }
  }

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    String? userId =
        Provider.of<UserProvider>(context, listen: false).user?.uid;

    return ModalProgressHUD(
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
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: getEventGradient(currentEvent),
              begin: Alignment.topLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () {
                  navPop(context);
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
            body: Column(
              children: [
                UserImage(
                  imageUrl: imageUrl,
                  onFileChanged: (imagePath) {
                    setState(() {
                      imageUrl = imagePath;
                    });
                  },
                  onLoadingChanged: (loading) {
                    setState(() {
                      isLoading = loading;
                    });
                  },
                ),
                const SizedBox(
                  height: 30,
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 30,
                          ),
                        Align(
                              alignment: Alignment.topLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomText(
                                        textLabel:
                                            '${userInfo!.firstName} ${userInfo.lastName}',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      Row(
                                        children: [
                                          const CustomText(
                                            textLabel: 'Successful Orders: ',
                                            fontSize: 15,
                                          ),
                                          StreamBuilder<int>(
                                            stream: successfulOrders(userId),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const CustomText(
                                                  textLabel: '...',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                );
                                              }

                                              if (snapshot.hasError) {
                                                return const CustomText(
                                                  textLabel: 'Error',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                );
                                              }

                                              final count = snapshot.data ?? 0;

                                              return CustomText(
                                                textLabel: '$count',
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  CustomText(
                                    textLabel: userInfo.email,
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ],
                              )),
                          const SizedBox(
                            height: 20,
                          ),
                        editableTextField(
                            label: 'First Name',
                            controller: firstNameController,
                            isEditing: isEditingFirstName,
                            onToggle: () => setState(
                                () => isEditingFirstName = !isEditingFirstName),
                            onSave: () => saveField(
                                'firstName', firstNameController.text),
                          ),
                         editableTextField(
                            label: 'Last Name',
                            controller: lastNameController,
                            isEditing: isEditingLastName,
                            onToggle: () => setState(
                                () => isEditingLastName = !isEditingLastName),
                            onSave: () =>
                                saveField('lastName', lastNameController.text),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomText(
                                  textLabel: "Addresses",
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(height: 10),
                                ...List.generate(addresses.length, (index) {
                                  return ListTile(
                                    title: CustomText(
                                      textLabel: addresses[index],
                                      fontSize: 16,
                                      textColor: Colors.black,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _removeAddress(index),
                                    ),
                                  );
                                }),
                                if (addresses.length < 5)
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: _addAddress,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple.shade700,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: CustomText(
                                        textLabel: 'Add Address',
                                        textColor: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                            editableTextField(
                            label: 'Contact Number',
                            controller: contactController,
                            isEditing: isEditingContact,
                            hintText: 'Please Add Your Contact Number',
                            hinstyle: contactController.text.isEmpty
                                ? const TextStyle(color: Colors.red)
                                : null,
                            onToggle: () => setState(
                                () => isEditingContact = !isEditingContact),
                            onSave: () => saveField(
                                'contactNumber', contactController.text),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: CustomText(
                              textLabel: 'PASSWORD',
                              fontSize: 16,
                              textColor: Colors.grey.shade700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            obscureText: true,
                            initialValue: '******',
                            readOnly: true,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    customDialog(context, 'Reset Password',
                                        "A password reset link will be sent to your registered email address. Do you want to proceed?",
                                        () {
                                      sendPasswordResetEmail(
                                          context, userInfo.email);
                                    });
                                  },
                                  icon: const Icon(Icons.edit)),
                              fillColor: Colors.white,
                              filled: true,
                              labelStyle: const TextStyle(fontSize: 16),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Colors.black)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Colors.black, width: 1.5)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Colors.black)),
                              errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Colors.orange)),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 50),
                              child: ElevatedButton(
                                onPressed: () {
                                  customDialog(context, 'Log Out',
                                      'Are you sure you want to log out?', () {
                                    FirebaseAuth.instance.signOut();
                                    Provider.of<UserProvider>(context,
                                            listen: false)
                                        .clearUser();

                                    navPushRemove(context, const LogIn());
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const CustomText(
                                  textLabel: "Log Out",
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  textColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Stream<int> successfulOrders(String? sellerId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .where('status', isEqualTo: 'delivered')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> sendPasswordResetEmail(
      BuildContext context, String email) async {
    navPop(context);
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      successSnackbar(context,
          "Password reset link has been sent to your email. Please check your inbox.");
    } catch (e) {
      errorSnackbar(
          context, "Failed to send password reset email. Please try again.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

class UserImage extends StatefulWidget {
  final Function(String imageUrl) onFileChanged;
  final String? imageUrl;
  final Function(bool isLoading) onLoadingChanged;

  const UserImage(
      {required this.onFileChanged,
      this.imageUrl,
      super.key,
      required this.onLoadingChanged});

  @override
  State<UserImage> createState() => _UserImageState();
}

class _UserImageState extends State<UserImage> {
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;

  @override
  void initState() {
    super.initState();

    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    if (userInfo != null && userInfo.profilePicturePath.isNotEmpty) {
      _imageUrl = userInfo.profilePicturePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: _imageUrl != null
                  ? (_imageUrl!.startsWith('http')
                      ? NetworkImage(_imageUrl!)
                      : FileImage(File(_imageUrl!)) as ImageProvider)
                  : const AssetImage('assets/images/profile.png'),
            ),
          ),
        ),
        // Edit icon overlay
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: selectPhoto,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(
                Icons.edit,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> selectPhoto() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheet(
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
        onClosing: () {},
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    widget.onLoadingChanged(true);
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) {
        widget.onLoadingChanged(false);

        return;
      }

      final file = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      );

      if (file == null) {
        widget.onLoadingChanged(false);
        return;
      }

      setState(() {
        _imageUrl = file.path;
      });

      final cloudinaryUrl =
          await CloudinaryService.uploadImageToCloudinary(File(file.path));

      if (cloudinaryUrl != null) {
        if (!mounted) return;
        final userInfo = Provider.of<UserProvider>(context, listen: false).user;
        if (userInfo != null) {
          await FirebaseFirestore.instance
              .collection('sellers')
              .doc(userInfo.uid)
              .update({'profilePicture': cloudinaryUrl});

          final updatedUser = UserInformation(
            address:userInfo.address,//might wanna check later why seller doesnt have address
              uid: userInfo.uid,
              firstName: userInfo.firstName,
              lastName: userInfo.lastName,
              email: userInfo.email,
              contactNumber: userInfo.contactNumber,
              role: userInfo.role,
              profilePicturePath: cloudinaryUrl,
              dateLastLogin: userInfo.dateLastLogin,
              approved: userInfo.approved);
          if (!mounted) return;

          Provider.of<UserProvider>(context, listen: false)
              .setUser(updatedUser);

          setState(() {
            _imageUrl = cloudinaryUrl;
          });
          successSnackbar(context, "Image uploaded successfully!");
        }
      } else {
        if (!mounted) return;

        successSnackbar(context, "Failed to upload image. Please try again.");
      }
    } catch (e) {
      successSnackbar(context,
          "An error occurred while uploading the image. Please try again.");
    } finally {
      widget.onLoadingChanged(false);
    }
  }
}

Future<UserInformation?> fetchAndSetUserData(
    String uid, BuildContext context) async {
  DocumentSnapshot userDocument =
      await FirebaseFirestore.instance.collection('sellers').doc(uid).get();

  if (userDocument.exists) {
    UserInformation fetchedUser = UserInformation.fromFirestore(userDocument);
    if (!context.mounted) return null;

    Provider.of<UserProvider>(context, listen: false).setUser(fetchedUser);
    return fetchedUser;
  } else {
    if (!context.mounted) return null;
    return null;
  }
}
