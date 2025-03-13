import 'package:flutter/material.dart';
import '../components/user_info.dart';

class UserProvider with ChangeNotifier {
  UserInformation? _user;

  UserInformation? get user => _user;

  void setUser(UserInformation user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
