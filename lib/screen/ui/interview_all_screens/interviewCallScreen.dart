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
          mainAxisAlignment: MainAxisAlignment.start,
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
            ),

            // ── Text box উপরে থাকবে, বাকি জায়গা Spacer নেবে ──
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4F52D3).withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  '"Could You describe your experience Could You describe your experience Could You describe your experience Could You describe your experience "',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),
              ),
            ),

            const Spacer(), // ← মাঝখানের জায়গা নেবে

            _BottomBar(context),



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


// ── Bottom Bar ─────────────────────────────────────────────────────────────
Widget _BottomBar(context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A22),
      borderRadius: BorderRadius.circular(32), // যত বড় চান
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundIconButton(icon: Icons.videocam, onTap: () {}),
        _RoundIconButton(icon: Icons.mic, onTap: () {}),
        _RoundIconButton(icon: Icons.more_vert, onTap: () {}),
        _EndCallButton(onTap: () => Navigator.pop(context)),
      ],
    ),
  );
}


// ── Reusable round icon button ─────────────────────────────────────────────
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFF2C2C38),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// ── End call button ────────────────────────────────────────────────────────
class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_end, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'End',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
