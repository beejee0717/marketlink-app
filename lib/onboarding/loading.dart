import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/components/notifications.dart';
import 'package:marketlinkapp/customer/customer.dart';
import 'package:marketlinkapp/onboarding/login.dart';
import 'package:marketlinkapp/rider/rider.dart';
import 'package:marketlinkapp/seller/seller.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:provider/provider.dart';
import '../components/snackbar.dart';
import '../components/user_info.dart';
import '../provider/user_provider.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AppEvent currentEvent;


  @override
  void initState() {
    super.initState();

    
    currentEvent = getCurrentEvent();

    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();

    fetchUserAndNavigate();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

 Future<void> fetchUserAndNavigate() async {
  try {
    final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      errorSnackbar(context, "No user found. Please log in again.");
      navPushReplacement(context, const LogIn());
      return;
    }

    final String email = currentUser.email!.trim().toLowerCase();
    DocumentSnapshot? userDoc;

    for (final role in ['customers', 'sellers', 'riders']) {
      final snap = await FirebaseFirestore.instance
          .collection(role)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        userDoc = snap.docs.first;
        final roleName = role[0].toUpperCase() + role.substring(1, role.length - 1);
        await handleUserFound(userDoc, roleName);
        return;
      }
    }

    if (!mounted) return;
    errorSnackbar(context, "User not found");
    navPop(context);
  } catch (e) {
    errorSnackbar(context, "An error occurred: ${e.toString()}");
    navPop(context);
  }
}

  Future<void> handleUserFound(DocumentSnapshot userDoc, String role) async {
    UserInformation userInfo = UserInformation.fromFirestore(userDoc);

    final bool isDisabled = userDoc.get('disabled') ?? false;
    if (isDisabled) {
      await auth.FirebaseAuth.instance.signOut();

      if (!mounted) return;
      errorSnackbar(context, "This account is disabled by the admin.");
      navPushRemove(context, const LogIn());
      return;
    }
    Provider.of<UserProvider>(context, listen: false).setUser(userInfo);

    await FirebaseFirestore.instance
         .collection('${role.toLowerCase()}s') 
        .doc(userInfo.uid)
        .update({'dateLastLogin': FieldValue.serverTimestamp()});
await getToken(userDoc, role);

    if (!mounted) return;

    successSnackbar(context, "Welcome back, ${userInfo.firstName}!");

  navPushRemove(
  context,
  role == 'Customer'
      ? const Customer()
      : role == 'Seller'
          ? Seller(userId: userInfo.uid)
          : Rider(userId: userInfo.uid),
);

  }
  @override
Widget build(BuildContext context) {
  return FadeTransition(
    opacity: _fadeAnimation,
    child: Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(wallpaper(currentEvent)),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo_no_text.png',
                width: 200,
              ),
            ),
            Center(
              child: SpinKitPulse(
                color: Colors.yellow,
                size: 400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}}