import 'package:ai_interview/Service/auth_service.dart';
import 'package:ai_interview/models/UserModel.dart';
import 'package:ai_interview/network/Api_URL.dart';
import 'package:ai_interview/screen/ui/auth/password_forget/email_send_otp.dart';
import 'package:ai_interview/screen/ui/auth/sign_up_screen.dart';
import 'package:ai_interview/screen/ui/bottom_nav.dart';
import 'package:ai_interview/utils/pathclass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Service/google_auth_service.dart';
import '../../../network/network_called.dart';
import '../../../utils/DeviceIdService.dart';
import '../../../utils/showDialoguePrograssbar.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ✅ একটাই instance
  final GoogleAuthService _googleAuth = GoogleAuthService();

  // ✅ Google Sign-In
  void _googleLogin() async {
    showLoadingDialog(context);

    final result = await _googleAuth.signIn();

    if (!mounted) return;
    hideLoadingDialog(context);

    if (result != null) {
      debugPrint("✅ Google Login Success: $result");
      _handleLoginSuccess(result);
    } else {
      debugPrint("❌ Google Login Failed");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Google Sign-In failed. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Login success হলে navigate করো
  void _handleLoginSuccess(Map<String, dynamic> data) {
    final accessToken = data["access_token"];
    final refreshToken = data["refresh_token"];
    final rawUser = data["user"] as Map<String, dynamic>? ?? {};

    AuthService.setLoggedIn(true, refreshToken);
    AuthService.saveAccessToken(accessToken);

    final safeUser = {
      "id": rawUser["id"],
      "email": rawUser["email"],
      "name": rawUser["name"],
      "mobile": rawUser["mobile"],
      "is_verified": rawUser["is_verified"] ?? false,
      "auth_provider": rawUser["auth_provider"],
      "profile_pic": rawUser["profile_pic"],
      "created_at": rawUser["created_at"],
      "updated_at": rawUser["updated_at"],
    };

    AuthService.setUser(UserModel.fromJson(safeUser)); // ✅ fromJson use করো

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back 👋',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Login to continue your interview practice',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Image.asset(
                  Pathclass.ic_logo_Path,
                  fit: BoxFit.cover,
                ),

                const SizedBox(height: 32),

                _InputField(
                  controller: _emailController,
                  hint: 'Email address',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 14),

                _InputField(
                  controller: _passwordController,
                  hint: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF999999),
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Email_Send_OTP()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Login button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loginAPIcall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── OR divider ──
                const Row(
                  children: [
                    Expanded(
                        child:
                        Divider(color: Color(0xFFDDDDDD), thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(
                              color: Color(0xFF999999), fontSize: 13)),
                    ),
                    Expanded(
                        child:
                        Divider(color: Color(0xFFDDDDDD), thickness: 1)),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Google button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _googleLogin, // ✅ fixed
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          Pathclass.ic_google_logo_Path,
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Sign up link ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style:
                      TextStyle(color: Color(0xFF888888), fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loginAPIcall() async {
    // ✅ Validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email and password cannot be empty"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showLoadingDialog(context);

    final deviceId = await DeviceIdService.getDeviceId();
    final response = await NetworkCaller.postJson(
      ApiURL.loginURL,
      {
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
        "device_id": deviceId,
      },
      requiresAuth: false,
    );

    if (!mounted) return;
    hideLoadingDialog(context);

    if (response.isSuccess && response.statusCode == 200) {
      _handleLoginSuccess(response.responseData);
    } else {
      debugPrint("❌ ${response.errorMessage}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.errorMessage ?? "Login failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ── Reusable Input Field ──────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF333333), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          prefixIcon:
          Icon(prefixIcon, color: const Color(0xFFAAAAAA), size: 20),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}