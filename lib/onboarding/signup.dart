import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../components/cloudinary.dart';
import '../components/navigator.dart';

class SignUp extends StatefulWidget {
  final String role;
  const SignUp({super.key, required this.role});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isAccepted = false;
  bool isLoading = false;
  bool isSigning = false;
  String? localImagePath;

  String _verificationCode = "";

  @override
  void initState() {
    super.initState();
    _generateVerificationCode();
  }

  void _generateVerificationCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    _verificationCode =
        List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> sendCode(String email) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'service_id': 'service_xjq7426',
            'template_id': 'template_aa8r5a2',
            'user_id': 'RgQmzTTkHC0oT3eWe',
            'template_params': {
              'email': email,
              'code': _verificationCode,
            }
          }));
      if (!mounted) return;

      successSnackbar(context, 'Verification code sent to $email');
    } catch (e) {
      errorSnackbar(context, 'Error sending verification code.');
    }
  }

  Future<void> _signUp() async {
    try {
      setState(() {
        isLoading = true;
      });

      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty ||
          _confirmPasswordController.text.trim().isEmpty) {
        errorSnackbar(context, 'Please fill in all fields.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (!EmailValidator.validate(_emailController.text.trim())) {
        errorSnackbar(context, 'Invalid email format');
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (_passwordController.text.trim().length < 6) {
        errorSnackbar(context, 'Password must be at least 6 characters.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        errorSnackbar(context, 'Passwords do not match.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (!_isAccepted) {
        errorSnackbar(context, 'Please accept the Terms and Conditions.');
        setState(() {
          isLoading = false;
        });
        return;
      }
      if (widget.role == 'Seller' &&
          (localImagePath == null || localImagePath!.isEmpty)) {
        errorSnackbar(context, 'Please upload your identification image.');
        setState(() {
          isLoading = false;
        });
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();

      await sendCode(_emailController.text.trim());

      _showVerificationDialog();
    } catch (e) {
      if (!mounted) return;

      errorSnackbar(context, 'Sign-up failed');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Verify Email"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A verification code has been sent to ${_emailController.text.trim()}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: "Enter Verification Code",
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Code cannot be empty.';
                    }
                    if (value.length != 6) {
                      return 'Code must be 6 characters.';
                    }
                    if (value != _verificationCode) {
                      return 'Incorrect verification code.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: _confirmVerification,
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmVerification() async {
    if (_formKey.currentState?.validate() == true) {
      navPop(context);
      setState(() {
        isSigning = true;
      });
      try {
        final UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final User? user = userCredential.user;

        if (user != null) {
          final String collectionName =
              widget.role == 'Customer' ? 'customers' : 'sellers';

          final Map<String, dynamic> userData = {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': widget.role,
            'createdAt': Timestamp.now(),
            'disabled': false
          };

          if (widget.role == 'Seller') {
            final cloudinaryUrl =
                await CloudinaryService.uploadImageToCloudinary(
                    File(localImagePath!));

            if (cloudinaryUrl == null) {
              if (!mounted) return;
              errorSnackbar(context, 'Failed to upload identification image.');
              return;
            }
            userData['imageID'] = cloudinaryUrl;
            userData['approved'] = false;
          }

          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(user.uid)
              .set(userData);

          if (!mounted) return;
          successSnackbar(context, 'Account created successfully.');
          navPop(context);
        }
      } catch (e) {
        if (!mounted) return;
        errorSnackbar(context, 'Sign-up failed: ${e.toString()}');
      } finally {
        setState(() {
          isSigning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ModalProgressHUD(
        inAsyncCall: isSigning,
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
          backgroundColor: Colors.purple.shade900,
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 40),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 200,
                      width: 200,
                    ),
                  ),
                  CustomText(
                    textLabel: widget.role,
                    fontSize: 25,
                    textColor: Colors.white,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _firstNameController,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white, width: 1)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.yellow, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _lastNameController,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white, width: 1)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.yellow, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(
                        Icons.email,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white, width: 1)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.yellow, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white, width: 1)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.yellow, width: 2)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _confirmPasswordController,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Re-enter Password',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white, width: 1)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.yellow, width: 2)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (widget.role == 'Seller') ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: SellerIdentification(
                          imageUrl: localImagePath,
                          onFileChanged: (imagePath) {
                            setState(() {
                              localImagePath = imagePath;
                            });
                          },
                          onLoadingChanged: (loading) {
                            setState(() {
                              isSigning = loading;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Checkbox(
                        value: _isAccepted,
                        activeColor: Colors.yellow.shade800,
                        onChanged: (bool? value) {
                          setState(() {
                            _isAccepted = value ?? false;
                          });
                        },
                        side: BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      CustomText(
                        textLabel: 'I accept the Terms and Conditions.',
                        fontSize: 15,
                        textColor: Colors.white,
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          padding: EdgeInsets.symmetric(vertical: 10)),
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: Colors.purple.shade800,
                            )
                          : CustomText(
                              textLabel: 'SIGN UP',
                              textColor: Colors.purple.shade800,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => navPop(context),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: 'Log In',
                            style: const TextStyle(
                              color: Colors.yellow,
                              letterSpacing: 1,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SellerIdentification extends StatefulWidget {
  final Function(String? imagePath) onFileChanged;
  final String? imageUrl;
  final Function(bool isLoading) onLoadingChanged;

  const SellerIdentification({
    required this.onFileChanged,
    this.imageUrl,
    required this.onLoadingChanged,
    super.key,
  });

  @override
  State<SellerIdentification> createState() => _SellerIdentificationState();
}

class _SellerIdentificationState extends State<SellerIdentification> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: widget.imageUrl == null || widget.imageUrl!.isEmpty
              ? const Icon(
                  Icons.assignment_ind_rounded,
                  color: Colors.white,
                  size: 50,
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: widget.imageUrl!.startsWith('http')
                      ? Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
                              size: 50,
                            );
                          },
                        )
                      : Image.file(
                          File(widget.imageUrl!),
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
                              size: 50,
                            );
                          },
                        ),
                ),
        ),
        TextButton(
            onPressed: selectPhoto,
            child: CustomText(
              textLabel: 'Select ID',
              fontSize: 20,
              textColor: Colors.white,
              fontWeight: FontWeight.bold,
            ))
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

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      );

      if (croppedFile == null) {
        widget.onLoadingChanged(false);
        return;
      }

      widget.onFileChanged(croppedFile.path);
    } catch (e) {
      if (!mounted) return;
      errorSnackbar(context, "Failed to select image. Please try again.");
    } finally {
      widget.onLoadingChanged(false);
    }
  }
}
