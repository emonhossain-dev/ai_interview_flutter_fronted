import 'package:ai_interview/screen/ui/auth/email_verify.dart';
import 'package:ai_interview/screen/ui/auth/login_screen.dart';
import 'package:ai_interview/screen/ui/auth/password_forget/email_send_otp.dart';
import 'package:ai_interview/screen/ui/auth/password_forget/new_password_set.dart';
import 'package:ai_interview/screen/ui/auth/password_forget/otp_verify.dart';
import 'package:ai_interview/screen/ui/interview_all_screens/interviewCallScreen.dart';
import 'package:ai_interview/screen/ui/splash_screen.dart';
import 'package:flutter/material.dart';

import 'screen/ui/bottom_nav.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SetNewPasswordScreen(),
    );
  }
}