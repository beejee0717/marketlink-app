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
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
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
  final AppEvent currentEvent = getCurrentEvent();

  bool _isPasswordVisible = false;
  bool _isAccepted = false;
  bool isLoading = false;
  bool isSigning = false;
  String? idPhoto;
  String? selfiePhoto;

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
      if (widget.role == 'seller' && (idPhoto == null || idPhoto!.isEmpty)) {
        errorSnackbar(context, 'Please upload your identification image.');
        setState(() {
          isLoading = false;
        });
        return;
      }
      if (widget.role == 'seller' &&
          (selfiePhoto == null || selfiePhoto!.isEmpty)) {
        errorSnackbar(context, 'Please upload your selfie image.');
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
          final String collectionName = '${widget.role}s';

          final Map<String, dynamic> userData = {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': widget.role[0].toUpperCase() + widget.role.substring(1),
            'createdAt': Timestamp.now(),
            'disabled': false
          };

          if (widget.role == 'seller' || widget.role == 'rider') {
            final idUrl =
                await CloudinaryService.uploadImageToCloudinary(File(idPhoto!));

            if (idUrl == null) {
              if (!mounted) return;
              errorSnackbar(context, 'Failed to upload identification image.');
              return;
            }
            final selfieUrl = await CloudinaryService.uploadImageToCloudinary(
                File(selfiePhoto!));

            if (selfieUrl == null) {
              if (!mounted) return;
              errorSnackbar(context, 'Failed to upload selfie image.');
              return;
            }
            userData['imageID'] = idUrl;
            userData['imageSelfie'] = selfieUrl;
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.5,
      ),
    );
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
           body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(wallpaper(currentEvent)),
            fit: BoxFit.cover,
          ),
        ),
        child:SingleChildScrollView(
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
                    textLabel:
                        widget.role[0].toUpperCase() + widget.role.substring(1),
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
                  if (widget.role == 'seller' || widget.role == 'rider') ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: IdUpload(
                          idImage: idPhoto,
                          selfieImage: selfiePhoto,
                          onIdChanged: (idPath) {
                            debugging(idPath.toString());
                            setState(() {
                              idPhoto = idPath;
                            });
                          },
                          onSelfieChanged: (selfiePath) {
                            debugging(selfiePath.toString());
                            setState(() {
                              selfiePhoto = selfiePath;
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _isAccepted,
                        activeColor: Colors.yellow.shade800,
                        onChanged: (_) {
                          _isAccepted
                              ? setState(() {
                                  _isAccepted = false;
                                })
                              : _termsAndConditions(context);
                        },
                        side: BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Row(
                          children: [
                            CustomText(
                              textLabel: 'I accept the',
                              fontSize: 15,
                              textColor: Colors.white,
                            ),
                            SizedBox(width: 4),
                            TextButton(
                              onPressed: () {
                                // pwede sab diri ang terms and conditions
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: CustomText(
                                textLabel: 'Terms and Conditions.',
                                fontSize: 15,
                                textColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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
        ),)
      ),
    );
  }

  void _termsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: Text('Terms and Conditions'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('General'),
                _sectionText(
                    'By using this app, you agree to comply with all applicable laws and regulations. '
                    'We reserve the right to modify the platform at any time without prior notice. '
                    'Users must not engage in fraudulent, abusive, or illegal activity on the platform.'),
                SizedBox(height: 10),
                _sectionTitle('For Customers'),
                _sectionText(
                    '• Customers are responsible for ensuring that their delivery details are correct.\n'
                    '• Payment should be made through approved payment methods only.\n'
                    '• Any dispute with an order should be reported within 48 hours after delivery.\n'
                    '• Customers should treat sellers and riders with respect at all times.'),
                SizedBox(height: 10),
                _sectionTitle('For Sellers'),
                _sectionText(
                    '• Sellers must ensure that all product listings are accurate and up-to-date.\n'
                    '• Orders must be fulfilled within the time agreed upon during listing.\n'
                    '• Sellers must handle returns and complaints in accordance with our platform policy.\n'
                    '• Any misuse or misrepresentation may lead to suspension or removal.'),
                SizedBox(height: 5),
                Text.rich(
                  TextSpan(
                    text: 'IMPORTANT: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red),
                    children: [
                      TextSpan(
                        text:
                            'There should be a clear memorandum of agreement between MarketLink and the seller. Sellers must also submit a proof of legitimacy in their business. These requirements must be submitted in physical copy to the admin personally within 3–5 days after registration.',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                _sectionTitle('For Delivery Riders'),
                _sectionText(
                    '• Riders must ensure timely and safe delivery of orders.\n'
                    '• Only verified riders are allowed to accept delivery tasks.\n'
                    '• Riders are expected to maintain professional conduct when interacting with customers and sellers.\n'
                    '• Failure to complete deliveries or repeated complaints may result in account suspension.'),
                SizedBox(height: 5),
                Text.rich(
                  TextSpan(
                    text: 'IMPORTANT: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red),
                    children: [
                      TextSpan(
                        text:
                            'There should be a clear memorandum of agreement between MarketLink and the rider. These requirements must be submitted in physical copy to the admin personally within 3–5 days after registration.',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _sectionText(
                    'By continuing to use this platform, you confirm that you have read, understood, and agreed to these Terms and Conditions.'),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _isAccepted = true;
                        });
                      },
                      child: Text('Accept'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class IdUpload extends StatefulWidget {
  final Function(String? idPath) onIdChanged;
  final Function(String? selfiePath) onSelfieChanged;
  final String? idImage;
  final String? selfieImage;
  final Function(bool isLoading) onLoadingChanged;

  const IdUpload({
    required this.onIdChanged,
    required this.onSelfieChanged,
    this.idImage,
    this.selfieImage,
    required this.onLoadingChanged,
    super.key,
  });

  @override
  State<IdUpload> createState() => _IdUploadState();
}

class _IdUploadState extends State<IdUpload> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: selectPhoto,
              child: Container(
                width: width * 0.65,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: CustomText(
                    textLabel: 'Select ID',
                    fontSize: 20,
                    textColor: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (widget.idImage != null && widget.idImage!.isNotEmpty)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: takeSelfie,
              child: Container(
                width: width * 0.65,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: CustomText(
                    textLabel: 'Take Selfie',
                    fontSize: 20,
                    textColor: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (widget.selfieImage != null && widget.selfieImage!.isNotEmpty)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
          ],
        )
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
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  'Please take a clear photo of the front side of your legal ID.\n'
                  'Make sure it is well-lit, not blurry, and all details are visible.',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera, onPicked: widget.onIdChanged);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery, onPicked: widget.onIdChanged);
                },
              ),
            ],
          ),
        ),
        onClosing: () {},
      ),
    );
  }

  Future<void> takeSelfie() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheet(
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  'Please take a clear selfie of yourself.\n'
                  'Use the front camera. Make sure your face is clearly visible, well-lit, and centered.\n'
                  'No hats, masks, or sunglasses. This will be used for identity verification.',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a selfie'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera,
                      useFrontCamera: true, onPicked: widget.onSelfieChanged);
                },
              ),
            ],
          ),
        ),
        onClosing: () {},
      ),
    );
  }

  Future<void> pickImage(
    ImageSource source, {
    bool useFrontCamera = false,
    required Function(String) onPicked,
  }) async {
    widget.onLoadingChanged(true);
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice:
            useFrontCamera ? CameraDevice.front : CameraDevice.rear,
      );

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

      onPicked(croppedFile.path);
    } catch (e) {
      if (!mounted) return;
      errorSnackbar(context, "Failed to select image. Please try again.");
    } finally {
      widget.onLoadingChanged(false);
    }
  }
}
