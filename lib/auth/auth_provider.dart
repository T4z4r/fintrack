import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../core/api.dart';

class AuthProvider extends ChangeNotifier {
  final Api _api = Api();
  bool _isLoggedIn = false;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<void> login(String email, String password) async {
    final response = await _api.login({
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['data']['token'];
      _api.setToken(_token!);
      _user = data['data']['user'];
      _isLoggedIn = true;
      notifyListeners();
    } else {
      throw Exception('Login failed');
    }
  }

  Future<void> register(String name, String email, String password) async {
    final response = await _api.register({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
    });

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      _token = data['data']['token'];
      _api.setToken(_token!);
      _user = data['data']['user'];
      _isLoggedIn = true;
      notifyListeners();
    } else {
      throw Exception('Registration failed');
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _isLoggedIn = false;
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<void> getCurrentUser() async {
    final response = await _api.getUser();
    if (response.statusCode == 200) {
      final data = response.body as Map<String, dynamic>;
      _user = data['data'];
      notifyListeners();
    }
  }
}