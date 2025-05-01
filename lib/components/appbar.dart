import 'package:flutter/material.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';

PreferredSizeWidget  appbar(BuildContext context, {required Widget destination}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    actions: [
      IconButton(
        onPressed: () => navPush(context, destination),
        icon: const Icon(Icons.person, color: Colors.black),
      ),
    ],
    title: Row(
      children: [
        Image.asset(
          'assets/images/logo_no_text.png',
          width: 35,
          height: 35,
        ),
        const SizedBox(width: 10),
        const CustomText(
          textLabel: 'Market Link',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          textColor: Colors.black,
        ),
      ],
    ),
  );
}
