import 'package:flutter/material.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/theme/event_theme.dart';



void successSnackbar(BuildContext context, String content) {

  var currentEvent = getCurrentEvent();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: AppColors.primary,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    content: CustomText(
      textLabel: content,
      fontSize: 15,
      maxLines: 2,
      textColor: currentEvent == AppEvent.christmas ? Colors.black: Colors.white ,
      fontWeight: FontWeight.bold,
    ),
  ));
}

void errorSnackbar(BuildContext context, String content) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: const Color.fromARGB(255, 255, 106, 0),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    content: CustomText(
      textLabel: content,
      fontSize: 15,
      maxLines: 2,
      textColor: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ));
}
