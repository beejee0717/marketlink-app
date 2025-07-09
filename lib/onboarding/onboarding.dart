import 'package:flutter/material.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/onboarding/auth.dart';
import 'package:marketlinkapp/theme/event_theme.dart';

import '../components/navigator.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  double _imageOpacity = 0.0;
  double _textOpacity = 0.0;
  double _buttonOpacity = 0.0;
  late AppEvent currentEvent;

  @override
  void initState() {
    super.initState();

    currentEvent = getCurrentEvent();
    // currentEvent = getCurrentEvent(DateTime(2025, 2, 14)); // <- test for Valentines


    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _imageOpacity = 1.0;
      });
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _textOpacity = 1.0;
      });
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() {
        _buttonOpacity = 1.0;
      });
    });
  }

@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    child: Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(wallpaper(currentEvent)),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: _imageOpacity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 300,
                      width: 300,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    AnimatedOpacity(
                      duration: const Duration(seconds: 1),
                      opacity: _textOpacity,
                      child:  Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: CustomText(
                          textLabel:
                              'A digital marketplace designed to enhance MSME visibility, expand access, and simplify selling!',
                          fontSize: 18,
                          textColor: onboardingTextColor(currentEvent),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 150),
                    AnimatedOpacity(
                      duration: const Duration(seconds: 1),
                      opacity: _buttonOpacity,
                      child: ElevatedButton(
                        onPressed: () =>
                            navPushReplacement(context, const AuthChecker()),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          backgroundColor: buttonColor(currentEvent),
                          foregroundColor: Colors.white,
                          shadowColor: Colors.black45,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: CustomText(
                          textLabel: 'Get Started',
                          textColor: Colors.purple.shade800,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}




}