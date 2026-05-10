import 'dart:convert';
import 'package:ai_interview/network/Api_URL.dart';
import 'package:ai_interview/utils/DeviceIdService.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // ✅ v6 এ এভাবে initialize করতে হয়
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: "1009889489171-0sjoi50tobnmu49q3jfrjgfvipnvubou.apps.googleusercontent.com",
    scopes: ['email', 'profile'],
  );

  // ✅ Sign In
  Future<Map<String, dynamic>?> signIn() async {
    try {
      // Silent sign-in আগে try করো
      GoogleSignInAccount? user = await _googleSignIn.signInSilently();

      // Silent fail হলে normal sign-in
      user ??= await _googleSignIn.signIn();

      if (user == null) {
        debugPrint("⚠️ User canceled sign-in");
        return null;
      }

      debugPrint("✅ Google User: ${user.email}");
      return await _sendTokenToBackend(user);

    } catch (e, stackTrace) {
      debugPrint("❌ Google Sign-In Error: $e");
      debugPrint("StackTrace: $stackTrace");
      return null;
    }
  }

  // ✅ Backend এ token পাঠানো
  Future<Map<String, dynamic>?> _sendTokenToBackend(
      GoogleSignInAccount user) async {
    try {
      final auth = await user.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        debugPrint("❌ ID Token is null — serverClientId চেক করো");
        return null;
      }

      final deviceId = await DeviceIdService.getDeviceId();

      final response = await http.post(
        Uri.parse(ApiURL.LoginWithGoogleURL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_token": idToken,
          "device_id": deviceId,
          "email": user.email,
          "name": user.displayName,
          "profile_pic": user.photoUrl,
        }),
      );

      debugPrint("📡 Response [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint("❌ Backend Failed: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Backend Error: $e");
      return null;
    }
  }

  // ✅ Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint("✅ Sign-Out successful");
    } catch (e) {
      debugPrint("❌ Sign-Out Error: $e");
    }
  }
}