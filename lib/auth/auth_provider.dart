import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<void> login(String email, String password) async {
    // Simulate login API call
    await Future.delayed(Duration(seconds: 1));
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    // Simulate register API call
    await Future.delayed(Duration(seconds: 1));
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}