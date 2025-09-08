import 'package:flutter/material.dart';
import 'package:marketlinkapp/components/colors.dart';

enum AppEvent {
  none,
  valentines,
  halloween,
  christmas,
}

AppEvent getCurrentEvent() {
  final now = DateTime.now(); //use this as default
  // final now = DateTime(2025, 2,14);//Valentines -- change this to show the theme during defense (YYYY,MM,DD)   
  // final now = DateTime(2025, 10,28);//halloween  
  //  final now = DateTime(2025, 12,25);//christmas
  //restart build after changing date for full implementation

  if (_isInRange(now, DateTime(now.year, 2, 10), DateTime(now.year, 2, 20))) {
    return AppEvent.valentines;
  }

  if (_isInRange(now, DateTime(now.year, 10, 30), DateTime(now.year, 11, 3))) {
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

Color sellerAddButton(AppEvent currentEvent) {
  switch (currentEvent) {
    case AppEvent.valentines:
    
      return const Color.fromARGB(255, 255, 215, 228);
    case AppEvent.halloween:
    return const Color.fromARGB(255, 97, 36, 106);
    case AppEvent.christmas:
    
      return Color.fromARGB(255, 73, 243, 81); 
    default:
      return AppColors.primary;
  }
}


Color productDetails(AppEvent currentEvent) {
  switch (currentEvent) {
   
    case AppEvent.valentines:
      return Color(0xFFD81B60); 
    case AppEvent.halloween:
    return const Color.fromARGB(255, 97, 36, 106);

    case AppEvent.christmas:
      return const Color.fromARGB(255, 207, 23, 23);
    default:
      return Color.fromARGB(255, 119, 22, 136);
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
      return 'assets/images/default_bg.png';
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

Color sellerHeaderColor(AppEvent currentEvent) {
  switch (currentEvent) {
    case AppEvent.valentines:
      return const Color.fromARGB(255, 255, 215, 228);
    case AppEvent.halloween:
    return const Color.fromARGB(255, 97, 36, 106);

    case AppEvent.christmas:
      return const Color.fromARGB(255, 207, 23, 23);
    default:
      return Colors.purple.shade900;
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


List<Color> getEventGradient(AppEvent currentEvent) {
  switch (currentEvent) {
    case AppEvent.valentines:
      return [
        const Color(0xFFFFC1E3),
        const Color(0xFFFF8DAA),
        const Color(0xFFD81B60),
      ];
    case AppEvent.halloween:
      return [
        const Color(0xFFFFD180),
        const Color(0xFFFFAB40),
        const Color(0xFFEF6C00),
      ];
    case AppEvent.christmas:
      return [
        const Color(0xFFC8FACC),
        const Color(0xFF9DF79E),
        const Color(0xFF49F351),
      ];
    default:
      return [
        Colors.purple.shade900,
        Colors.purple.shade600,
        Colors.purple.shade300,
      ];
  }
}