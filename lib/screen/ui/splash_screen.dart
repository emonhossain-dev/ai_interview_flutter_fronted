import 'dart:async';
import 'package:ai_interview/utils/pathclass.dart';
import 'package:flutter/material.dart';

import '../../Service/auth_service.dart';
import 'auth/login_screen.dart';
import 'bottom_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    await Future.delayed(const Duration(seconds: 3)); // ⏳ wait 3 sec

    final isLogin = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (isLogin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // dark blue theme
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
        
              // Logo
              Image.asset(
                Pathclass.ic_logo_Path,
                width: 150,
              ),
        
              const SizedBox(height: 20),
        
              // App Name
              const Text(
                "AI Interview",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        
              const SizedBox(height: 10),
        
              // Tagline
              const Text(
                "Practice Smarter, Get Hired Faster",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
        
              const SizedBox(height: 40),
        
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}