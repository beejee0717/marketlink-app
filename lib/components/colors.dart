import 'package:flutter/material.dart';
import 'package:marketlinkapp/theme/event_theme.dart';

class AppColors {
  static const Color appGreen = Colors.green;
  static const Color greenTransparent = Color.fromARGB(100, 76, 175, 79);
  static const Color white = Colors.white;
  static const Color grey = Colors.grey;
  static const Color skyBlue = Colors.lightBlue;
  static const Color transparentWhite =Color.fromARGB(193, 255, 255, 255);

  static final AppEvent _event = getCurrentEvent();

static Color get yellow {
  switch (_event) {
    case AppEvent.valentines:
      return Color(0xFFD81B60); 
    case AppEvent.halloween:
      return Color(0xFFEF6C00); 
  case AppEvent.christmas:
      return const Color.fromARGB(255, 207, 23, 23);
    default:
      return Colors.yellow;
  }
}


static Color get primary {
  switch (_event) {
    case AppEvent.valentines:
      return Color(0xFFD81B60); 
    case AppEvent.halloween:
      return Color(0xFFEF6C00); 
    case AppEvent.christmas:
      return Color.fromARGB(255, 47, 171, 53); 
    default:
      return Color.fromARGB(255, 119, 22, 136);
  }
}

static Color get accent {
  switch (_event) {
    case AppEvent.valentines:
      return Color.fromARGB(176, 255, 193, 227);
    case AppEvent.halloween:
      return Color.fromARGB(175, 119, 50, 202); 
    case AppEvent.christmas:
      return Color.fromARGB(175, 241, 73, 73);
    default:
      return Color.fromARGB(211, 206, 123, 212); 
  }
}

   static Color get textColor {
    switch (_event) {
      case AppEvent.valentines:
        return Color.fromARGB(255, 77, 3, 43);
      case AppEvent.halloween:
        return Color(0xFFFFA000);
      case AppEvent.christmas:
        return Color(0xFFB71C1C);
      default:
        return Color.fromARGB(210, 255, 255, 255);
    }
  }
 
}
