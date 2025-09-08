import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/components/snackbar.dart';
import 'package:marketlinkapp/debugging.dart';
import 'package:marketlinkapp/onboarding/loading.dart';
import 'package:marketlinkapp/onboarding/select_role.dart';
import 'package:marketlinkapp/theme/event_theme.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AppEvent currentEvent;
  bool _isPasswordVisible = false;
  bool isLoading = false;

  Future<void> _logIn() async {
    try {
      setState(() {
        isLoading = true;
      });

      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        errorSnackbar(context, 'Please fill in both email and password.');

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

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        if (!mounted) return;
        FocusManager.instance.primaryFocus?.unfocus();
        navPush(context, const Loading());
      }
   } catch (e) {

  if (!mounted) return;

  String errorMessage = 'Login failed. Please try again.';

  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found for that email.';
        break;
      case 'invalid-credential':
        errorMessage = 'Incorrect password. Please try again.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is badly formatted.';
        break;
      case 'user-disabled':
        errorMessage = 'This user has been disabled.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many attempts. Please try again later.';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Email/password sign-in is not enabled.';
        break;
        case 'network-request-failed':
        errorMessage = 'Login failed, please turn on network connection';
      default:
        errorMessage = 'Login failed: ${e.message}';
    }
  } else {
    errorMessage = 'An unexpected error occurred.';
  }

  errorSnackbar(context, errorMessage);
}
finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
void initState() {
  super.initState();

    currentEvent = getCurrentEvent();
}

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
  body: Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(wallpaper(currentEvent)),
        fit: BoxFit.cover,
      ),
    ),
    child: SingleChildScrollView(
      reverse: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 50, top: 120),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 300,
                    width: 300,
                  ),
                ),
                CustomText(
                  textLabel: 'Welcome!',
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)),
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white, width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2)),
                          prefixIcon: Icon(
                            Icons.email,
                            color: Colors.white,
                          ),
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
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)),
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white, width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2)),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.white,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _logIn,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor(getCurrentEvent()),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              padding: EdgeInsets.symmetric(vertical: 10)),
                          child: isLoading
                              ? CircularProgressIndicator(
                                  color: Colors.purple.shade800,
                                )
                              : CustomText(
                                  textLabel: 'LOG IN',
                                  textColor: Colors.purple.shade800,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => navPush(context, const SelectRole()),
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign up',
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
                      SizedBox(
                        height: 10,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
     ) );
  }
}
