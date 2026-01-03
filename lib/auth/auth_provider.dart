import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class AuthProvider extends ChangeNotifier {
  final Api _api = Api();
  late SharedPreferences _prefs;
  bool _isLoggedIn = false;
  String? _token;
  Map<String, dynamic>? _user;

  // Public getter for API instance
  Api get api => _api;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    String? token = _prefs.getString('token');
    String? userJson = _prefs.getString('user');
    if (token != null) {
      _token = token;
      _api.setToken(_token!);
      if (userJson != null) {
        _user = json.decode(userJson);
      }
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<void> _saveAuthData() async {
    await _prefs.setString('token', _token!);
    await _prefs.setString('user', json.encode(_user));
  }

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
      bool success = data['success'] ?? true;
      if (success) {
        _token = data['data']['token'];
        _api.setToken(_token!);
        _user = data['data']['user'];
        _isLoggedIn = true;
        await _saveAuthData();
        notifyListeners();
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
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
      bool success = data['success'] ?? true;
      if (success) {
        _token = data['data']['token'];
        _api.setToken(_token!);
        _user = data['data']['user'];
        _isLoggedIn = true;
        await _saveAuthData();
        notifyListeners();
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } else {
      throw Exception('Registration failed');
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _isLoggedIn = false;
    _token = null;
    _user = null;
    await _prefs.remove('token');
    await _prefs.remove('user');
    notifyListeners();
  }

  Future<void> getCurrentUser() async {
    final response = await _api.getUser();
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _user = data['data'];
      notifyListeners();
    }
  }
}
