import 'package:ai_interview/models/UserModel.dart';
import 'package:ai_interview/screen/history_screen.dart';
import 'package:ai_interview/screen/ui/chat_screen.dart';
import 'package:ai_interview/screen/ui/home_screen.dart';
import 'package:ai_interview/screen/ui/interview_all_screens/interviewCallScreen.dart';
import 'package:ai_interview/screen/ui/profile_screen.dart';
import 'package:ai_interview/utils/pathclass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Service/auth_service.dart';

import 'auth/login_screen.dart';

class BottomNavScreen extends StatefulWidget {
  final UserModel? user; // ✅

  const BottomNavScreen({super.key, this.user});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {

  late final List<Widget> _screen; // ✅ late — initState এ build হবে

  int _selectedIndex = 0;
  bool? isLoggedIn;

  String get userId => widget.user?.id.toString() ?? "";

  @override
  void initState() {
    super.initState();

    // ✅ widget.user এখানে available
    _screen = [
      HomeScreen(),
      ChatScreen(),
      InterviewCallScreen(),
      HistoryScreen(),
      ProfileScreen(),
    ];

    checkLogin();
  }

  Future<void> checkLogin() async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.isEmpty) {
      setState(() => isLoggedIn = false);

      Future.microtask(() {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
              (route) => false,
        );
      });
      return;
    }

    setState(() => isLoggedIn = true);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screen[_selectedIndex],

      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFCCB0B).withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _onItemTapped(2),
          backgroundColor: const Color(0xFFFCCB0B),
          elevation: 6,
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: null,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildItem(0),
              buildItem(1),
              const SizedBox(width: 40),
              buildItem(3),
              buildItem(4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getIcon(int index, bool isSelected) {
    final color = isSelected ? Colors.white : Colors.grey;

    switch (index) {
      case 0:
        return SvgPicture.asset(
          Pathclass.ic_home_Path,
          width: 20, height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case 1:
        return SvgPicture.asset(
          Pathclass.ic_chat_Path,
          width: 20, height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case 3:
        return Icon(Icons.folder, color: color, size: 24);
      case 4:
        return Icon(Icons.person, color: color, size: 24);
      default:
        return SvgPicture.asset(
          Pathclass.ic_home_Path,
          width: 20, height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
    }
  }

  Widget buildItem(int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(user: widget.user), // ✅
            ),
          );
          return;
        }
        _onItemTapped(index);
      },
      child: SizedBox(
        width: 50, height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              SvgPicture.asset(
                Pathclass.bottomSelected_background_Path,
                width: 50, height: 50,
                fit: BoxFit.cover,
              ),
            _getIcon(index, isSelected),
          ],
        ),
      ),
    );
  }
}