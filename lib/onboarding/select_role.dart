import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/onboarding/signup.dart';

class SelectRole extends StatelessWidget {
  const SelectRole({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
            onPressed: () {
              navPop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 100,
          ),
          Center(
            child: CustomText(
              textLabel: 'Select Role',
              fontSize: 25,
              textColor: Colors.white,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 50,
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                      onTap: () {
                        navPushReplacement(
                            context, const SignUp(role: 'Customer'));
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                width: 5, color: Colors.yellow.shade800)),
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/svg/cart.svg',
                              width: 110,
                              height: 110,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            CustomText(
                              textLabel: 'Customer',
                              fontSize: 25,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                              textColor: Colors.purple.shade900,
                            )
                          ],
                        ),
                      )),
                  GestureDetector(
                      onTap: () {
                        navPushReplacement(
                            context, const SignUp(role: 'Seller'));
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                width: 5, color: Colors.yellow.shade800)),
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/svg/store.svg',
                              width: 110,
                              height: 110,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            CustomText(
                              textLabel: 'Seller',
                              fontSize: 25,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                              textColor: Colors.purple.shade900,
                            )
                          ],
                        ),
                      )),
                ],
              ),
              SizedBox(height: 20),
              GestureDetector(
                  onTap: () {
                    navPushReplacement(context, const SignUp(role: 'Rider'));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            width: 5, color: Colors.yellow.shade800)),
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/helmet.svg',
                          width: 110,
                          height: 110,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        CustomText(
                          textLabel: 'Rider',
                          fontSize: 25,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          textColor: Colors.purple.shade900,
                        )
                      ],
                    ),
                  )),
            ],
          )
        ],
      ),
    );
  }
}
