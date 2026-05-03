import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static const String _keyLogin = "isLoggedIn";
  static const String _accessToken = "accessToken";
  static const String _RefreshToken = "RefreshToken";

  // Save login
  static Future<void> setLoggedIn(bool value,String accessToken, String RefreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLogin, value);
    await prefs.setString(_accessToken, accessToken);
    await prefs.setString(_RefreshToken, RefreshToken);
  }

  // Get login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLogin) ?? false;
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessToken);
  }

  // Get Refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_RefreshToken);
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}