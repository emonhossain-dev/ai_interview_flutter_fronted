import 'dart:convert';
import 'package:ai_interview/network/Api_URL.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> initGoogle() async {
    await _googleSignIn.initialize(
      // যদি Firebase / Web না use করো তাহলে null রাখো
      serverClientId: "1009889489171-do9ffjpnco5hrjbhhip5recpkua2s42e.apps.googleusercontent.com",
    );
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final user = await _googleSignIn.authenticate();
      return user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
  }
}


Future<void> sendTokenToBackend(GoogleSignInAccount user) async {
  final auth = await user.authentication;

  final idToken = auth.idToken;

  final response = await http.post(
    Uri.parse(ApiURL.LoginWithGoogleURL),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "id_token": idToken,
    }),
  );

  print(response.body);
}