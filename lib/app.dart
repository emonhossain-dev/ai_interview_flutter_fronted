import 'package:ai_interview/screen/ui/splash_screen.dart';
import 'package:flutter/material.dart';

import 'screen/ui/bottom_nav.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const BottomNavScreen(),
    );
  }
}