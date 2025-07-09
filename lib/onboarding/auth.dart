import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/onboarding/loading.dart';
import 'package:marketlinkapp/onboarding/login.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/theme/event_theme.dart';

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> with SingleTickerProviderStateMixin {
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
      ),)
    );
 
  }
}
