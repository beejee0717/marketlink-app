import 'package:flutter/material.dart';

enum AppEvent {
  none,
  valentines,
  halloween,
  christmas,
}

AppEvent getCurrentEvent() {
  final now = DateTime.now(); //use this as default
  // final now = DateTime(2025, 12,25);//change this to show the theme during defense (YYYY,MM,DD) 
  //available dates are Feb 10-20(Valentines), Oct 25-Nov 2(Halloween), Dec 20-31 (Christmas)
  //restart build after changing date for full implementation
  //TODO: also add on the search portion

  if (_isInRange(now, DateTime(now.year, 2, 10), DateTime(now.year, 2, 20))) {
    return AppEvent.valentines;
  }

  if (_isInRange(now, DateTime(now.year, 10, 25), DateTime(now.year, 11, 2))) {
    return AppEvent.halloween;
  }

  if (_isInRange(now, DateTime(now.year, 12, 20), DateTime(now.year, 12, 31))) {
    return AppEvent.christmas;
  }

  return AppEvent.none;
}

bool _isInRange(DateTime date, DateTime start, DateTime end) {
  return date.isAfter(start.subtract(const Duration(days: 1))) &&
         date.isBefore(end.add(const Duration(days: 1)));
}

String wallpaper(AppEvent currentEvent) {
  switch (currentEvent) {
    case AppEvent.valentines:
      return 'assets/images/valentines_wp.png';
    case AppEvent.halloween:
      return 'assets/images/halloween_wp.png';
    case AppEvent.christmas:
      return 'assets/images/christmas_wp.png';
    default:
      return 'assets/images/default_wp.png';
  }
}
Color buttonColor(AppEvent currentEvent) {
  switch (currentEvent) {
    case AppEvent.valentines:
      return Colors.pinkAccent;
    case AppEvent.halloween:
      return const Color.fromARGB(255, 211, 95, 59);
    case AppEvent.christmas:
      return Colors.green;
    default:
      return Colors.yellow;
  }
}
Color onboardingTextColor(AppEvent currentEvent) {
  switch (currentEvent) {
    case AppEvent.valentines:
      return Colors.white;
    case AppEvent.halloween:
      return Colors.white;
    case AppEvent.christmas:
      return Colors.white;
    default:
      return Colors.yellow;
  }
}



String backgroundImage(AppEvent currentEvent) {
  switch (currentEvent) {
    case AppEvent.valentines:
      return 'assets/images/valentines_bg.png';
    case AppEvent.halloween:
      return 'assets/images/halloween_bg.png';
    case AppEvent.christmas:
      return 'assets/images/christmas_bg.png';
    default:
      return 'assets/images/default_wp.png';
  }
}
Color backgroundColor(AppEvent currentEvent) {
  switch (currentEvent) {
    case AppEvent.valentines:
      return const Color.fromARGB(255, 255, 215, 228);
    case AppEvent.halloween:
    return const Color.fromARGB(255, 97, 36, 106);

    case AppEvent.christmas:
      return const Color.fromARGB(255, 207, 23, 23);
    default:
      return const Color.fromARGB(255, 255, 255, 255);
  }
}

Color headerTitleColor (AppEvent currentEvent){
  switch (currentEvent){

case AppEvent.valentines:
      return const Color.fromARGB(255, 0, 0, 0);
    case AppEvent.halloween:
      return const Color.fromARGB(255, 252, 252, 252);
    case AppEvent.christmas:
      return const Color.fromARGB(255, 255, 255, 255);
    default:
      return const Color.fromARGB(255, 0, 0, 0);
  }
}