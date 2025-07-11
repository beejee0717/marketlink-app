import 'package:flutter/material.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/navigator.dart';
import 'package:marketlinkapp/theme/event_theme.dart';

PreferredSizeWidget  appbar(BuildContext context, {required Widget destination}) {
  late AppEvent currentEvent = getCurrentEvent();
  return AppBar(
    backgroundColor: currentEvent == AppEvent.none? Colors.white : backgroundColor(currentEvent),
    actions: [
      IconButton(
        onPressed: () => navPush(context, destination),
        icon:  Icon(Icons.person, color:  currentEvent == AppEvent.none? Colors.black : headerTitleColor(currentEvent)),
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
         CustomText(
          textLabel: 'Market Link',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          textColor:  currentEvent == AppEvent.none? Colors.black : headerTitleColor(currentEvent),
        ),
      ],
    ),
  );
}
