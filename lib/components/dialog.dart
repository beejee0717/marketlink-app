import 'package:flutter/material.dart';

import 'auto_size_text.dart';
import 'navigator.dart';

void customDialog(context, String title, String content, VoidCallback onPressed,
    {bool barrierDismissible = true}) {
  showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  textLabel: title,
                  fontSize: 20,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(
                  height: 30,
                ),
                CustomText(
                  textLabel: content,
                  fontSize: 16,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                        onPressed: () {
                          navPop(context);
                        },
                        child: const CustomText(
                          textLabel: 'Cancel',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                    TextButton(
                        onPressed: onPressed,
                        child: const CustomText(
                          textLabel: 'Confirm',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ))
                  ],
                ),
              ],
            ),
          ),
        );
      });
}
