import 'dart:async';

import 'package:flutter/material.dart';

import '../../widget/aIProfileCard.dart';

class InterviewCallScreen extends StatefulWidget {
  const InterviewCallScreen({super.key});

  @override
  State<InterviewCallScreen> createState() => _InterviewCallScreenState();
}

class _InterviewCallScreenState extends State<InterviewCallScreen> {
  String _selectedLang = 'EN';
  bool _recVisible = true;
  late Timer _recTimer;

  @override
  void initState() {
    super.initState();
    _recTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      setState(() => _recVisible = !_recVisible);
    });
  }

  @override
  void dispose() {
    _recTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),

      body: SafeArea(
        child: Column(
          children: [


            Stack(

              children: [
                _AppBar(),

                AIProfileCard(
                  name: 'Dr. Sarah (AI)',
                  subtitle: 'Clinical Assessment',
                  imagePath: 'assets/icon/ic_ai_avater.png',
                ),
              ],
            )




          ],
        ),
      ),
    );
  }

  Container _AppBar() {
    return Container(
            color: const Color(0xFF3C3C47),
            height: 56,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    Row(
                      children: [
                        AnimatedOpacity(
                          opacity: _recVisible ? 1.0 : 0.15,
                          duration: const Duration(milliseconds: 400),
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'REC 12:00',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // EN / BN / HI tab group  — matches screenshot exactly
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1C35),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['EN', 'BN', 'HI'].map((lang) {
                          final active = lang == _selectedLang;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedLang = lang),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF4F52D3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                lang,
                                style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFF9090B0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          );
  }

}
