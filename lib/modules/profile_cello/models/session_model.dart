import 'package:flutter/material.dart';

class SessionModel extends ChangeNotifier {
  String? username;

  void setUsername(String name) {
    username = name;
    notifyListeners();
  }

  void clear() {
    username = null;
    notifyListeners();
  }
}
