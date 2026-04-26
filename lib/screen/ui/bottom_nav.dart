import 'package:ai_interview/screen/ui/home_screen.dart';
import 'package:ai_interview/screen/ui/interview_all_screens/interviewCallScreen.dart';
import 'package:ai_interview/utils/pathclass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  List<Widget> _screen = [
    HomeScreen(),
    InterviewCallScreen(),
    HomeScreen(),
    InterviewCallScreen(),
    InterviewCallScreen(),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screen[_selectedIndex],

      // Floating center button
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFCCB0B).withOpacity(0.6), // 👈 yellow glow
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _onItemTapped(2),
          backgroundColor: const Color(0xFFFCCB0B),
          elevation: 6,
          // light base shadow
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getIcon(int index, bool isSelected) {
    final color = isSelected ? Colors.white : Colors.grey;

    switch (index) {
      case 0:
        return SvgPicture.asset(
          Pathclass.ic_home_Path,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );

      case 1:
        return SvgPicture.asset(
          Pathclass.ic_chat_Path,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );

      case 3:
        return Icon(Icons.folder, color: color, size: 24);

      case 4:
        return Icon(Icons.person, color: color, size: 24);

      default:
        return SvgPicture.asset(
          Pathclass.ic_home_Path,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
    }
  }

  Widget buildItem(int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              SvgPicture.asset(
                Pathclass.bottomSelected_background_Path,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),

            _getIcon(index, isSelected),
          ],
        ),
      ),
    );
  }
}
