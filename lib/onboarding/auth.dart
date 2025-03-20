import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/onboarding/loading.dart';
import 'package:marketlinkapp/onboarding/login.dart';
import 'package:marketlinkapp/components/navigator.dart';

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading time
    final user = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (user != null) {
        navPush(context, const Loading()); // Navigate to HomePage
      } else {
navPush(context, LogIn());      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose(); // Dispose animation controller to free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.purple.shade900,
        body: Stack(
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
    );
 
  }
}
