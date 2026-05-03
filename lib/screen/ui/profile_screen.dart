import 'package:ai_interview/Service/auth_service.dart';
import 'package:flutter/material.dart';

import 'auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(

      children: [


        ElevatedButton(onPressed: (){
          AuthService.logout();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SignInScreen()),
          );
        }, child: Center(child: Text("LogOut Button")))


      ],
    ));
  }
}
