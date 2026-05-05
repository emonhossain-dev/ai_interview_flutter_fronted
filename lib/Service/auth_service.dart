import 'package:shared_preferences/shared_preferences.dart';

import '../models/UserModel.dart';

class AuthService {

  static const String _keyLogin = "isLoggedIn";
  static const String _accessToken = "accessToken";
  static const String _refreshToken = "refreshToken";

  static UserModel? currentUser;

  // ==============================
  // SAVE LOGIN + TOKENS
  // ==============================
  static Future<void> setLoggedIn(
      bool value,
      String refreshToken,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyLogin, value);
    await prefs.setString(_refreshToken, refreshToken);
  }

  // ==============================
  // CHECK LOGIN STATUS
  // ==============================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLogin) ?? false;
  }

  // ==============================
  // GET ACCESS TOKEN
  // ==============================
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessToken);
  }

  // ==============================
  // GET REFRESH TOKEN
  // ==============================
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshToken);
  }

  // ==============================
  // SAVE NEW ACCESS TOKEN ONLY
  // (USED AFTER REFRESH)
  // ==============================
  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessToken, token);
  }

  // ==============================
  // LOGOUT
  // ==============================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}