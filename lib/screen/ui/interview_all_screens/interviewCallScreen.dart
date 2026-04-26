import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../widget/aIProfileCard.dart';
import '../../widget/font_size_scalble.dart';

class InterviewCallScreen extends StatefulWidget {
  const InterviewCallScreen({super.key});

  @override
  State<InterviewCallScreen> createState() => _InterviewCallScreenState();
}

class _InterviewCallScreenState extends State<InterviewCallScreen> {
  String _selectedLang = 'EN';
  bool _recVisible = true;
  late Timer _recTimer;

  // ── Camera ──
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _isCameraOn = true;

  Future<void> _toggleCamera() async {
    if (_isCameraOn) {
      await _cameraController?.pausePreview();
    } else {
      await _cameraController?.resumePreview();
    }
    setState(() => _isCameraOn = !_isCameraOn);
  }

  @override
  void initState() {
    super.initState();
    _recTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      setState(() => _recVisible = !_recVisible);
    });
    _initCamera(); // ← camera init
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    // ✅ front camera নেবে
    final front = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  @override
  void dispose() {
    _recTimer.cancel();
    _cameraController?.dispose(); // ← dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: SafeArea(
        child: Column(
          children: [

            // ── App Bar ──
            _AppBar(),

            // ── AI Profile Card ──
            AIProfileCard(
              name: 'Dr. Sarah (AI)',
              subtitle: 'Clinical Assessment',
              imagePath: 'assets/icon/ic_ai_avater.png',
            ),

            // ── Question Box ──
            _QuestionBox(),

            const SizedBox(height: 10),

            // ── "You" Video Card — Expanded দিয়ে বাকি সব জায়গা নেবে ──
            _your_video_live(),

            // ── Bottom Bar ──
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: _BottomBar(context),
            ),
          ],
        ),
      ),
    );

  }

  Expanded _your_video_live() {
    return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [

                    // ✅ Camera ready হলে preview, না হলে placeholder
                    _cameraReady && _isCameraOn
                        ? SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value.previewSize!.height,
                          height: _cameraController!.value.previewSize!.width,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    )
                        : Container(
                      color: const Color(0xFF1E1E2E),
                      child: _cameraReady
                          ? const Icon(Icons.videocam_off, color: Colors.white38, size: 50)
                          : const Center(
                        child: CircularProgressIndicator(color: Color(0xFF4F52D3)),
                      ),
                    ),

                    // "You" label
                    Positioned(
                      bottom: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('You',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );




  }

  Widget _BottomBar(context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A22),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundIconButton(
            // এটা করুন
            icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
            onTap: _toggleCamera,
          ),
          _RoundIconButton(icon: Icons.mic, onTap: () {}),
          _RoundIconButton(icon: Icons.more_vert, onTap: () {}),
          _EndCallButton(onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }




  Padding _QuestionBox() {
    return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4F52D3).withOpacity(0.6),
                  width: 1.5,
                ),
              ),
              child: AutoSizeText(
                '"Could You describe your experience Could You describe your experience Could You describe your experience Could You describe your experience "',
                maxLines: 3,
                minFontSize: 8,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
  }

  Widget _AppBar() {
    return Container(
      color: const Color(0xFF3C3C47),
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // REC indicator
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
            // Language selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
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
                          horizontal: 14, vertical: 6),
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
    );
  }
}

// ── Bottom Bar ──────────────────────────────────────────────────────────────


// ── Round Icon Button ───────────────────────────────────────────────────────
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Color(0xFF2C2C38),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── End Call Button ─────────────────────────────────────────────────────────
class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_end, color: Colors.white, size: 20),
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