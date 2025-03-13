import 'package:flutter/material.dart';

void navPop(context) {
  Navigator.pop(context);
}

void navPush(context, Widget page) {
  Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ));
}

void navPushReplacement(context, Widget page) {
  Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ));
}

void navPushRemove(context, Widget page) {
  Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
      (route) => false);
}
