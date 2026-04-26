import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
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

  // ── Camera ──
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _isCameraOn = true;

  // ── Mic ──
  bool _isMicOn = true;

  // ── Speech ──
  final SpeechToText _speechToText = SpeechToText();
  bool _speechReady = false;
  String _spokenText = '';
  String _lastFinalText = '';

  bool _isRestarting = false; // ← নতুন variable যোগ করো

  // ── Camera Toggle ──
  Future<void> _toggleCamera() async {
    if (_isCameraOn) {
      await _cameraController?.pausePreview();
    } else {
      await _cameraController?.resumePreview();
    }
    setState(() => _isCameraOn = !_isCameraOn);
  }

  // ── Mic Toggle ──
  Future<void> _toggleMic() async {
    if (_isMicOn) {
      _stopListening();
    } else {
      _lastFinalText = ''; // ← reset
      _spokenText = '';
      if (_speechReady) _startListening();
    }
    setState(() => _isMicOn = !_isMicOn);
  }



  void _onSpeechStatus(String status) {
    if ((status == 'done' || status == 'notListening') && !_isRestarting) {
      if (_isMicOn && _speechReady && mounted) {
        _isRestarting = true;
        _speechToText.stop();
        Future.delayed(const Duration(milliseconds: 50), () { // ← মাত্র 50ms!
          if (_isMicOn && mounted) {
            _startListening();
          }
          _isRestarting = false;
        });
      }
    }
  }

  void _startListening() {
    _speechToText.listen(
      onResult: (result) {
        setState(() {
          if (result.finalResult) {
            _lastFinalText = (_lastFinalText + ' ' + result.recognizedWords).trim();
            _spokenText = _lastFinalText;
          } else {
            _spokenText = (_lastFinalText + ' ' + result.recognizedWords).trim();
          }
        });
      },
      localeId: _selectedLang == 'BN'
          ? 'bn_BD'
          : _selectedLang == 'HI'
          ? 'hi_IN'
          : 'en_US',
      listenMode: ListenMode.dictation,
      pauseFor: const Duration(seconds: 60),
      listenFor: const Duration(minutes: 10),
      partialResults: true,
    );
  }





  // ── Speech Stop ──
  void _stopListening() {
    _speechToText.stop();
  }

  // ── Speech Init ──

  Future<void> _initSpeech() async {
    _speechReady = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) => print('Speech error: $error'),
      debugLogging: false, // ← sound/log বন্ধ
    );
    if (_speechReady && mounted) _startListening();
  }

  // ── Camera Init ──
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
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
  void initState() {
    super.initState();
    _recTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      setState(() => _recVisible = !_recVisible);
    });
    _initCamera();
    _initSpeech();
  }

  @override
  void dispose() {
    _recTimer.cancel();
    _cameraController?.dispose();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(),
            AIProfileCard(
              name: 'Dr. Sarah (AI)',
              subtitle: 'Clinical Assessment',
              imagePath: 'assets/icon/ic_ai_avater.png',
            ),
            _QuestionBox(),
            const SizedBox(height: 10),
            _your_video_live(),
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
                    ? const Icon(Icons.videocam_off,
                    color: Colors.white38, size: 50)
                    : const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF4F52D3)),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          style:
                          TextStyle(color: Colors.white, fontSize: 13)),
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
            icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
            onTap: _toggleCamera,
          ),
          _RoundIconButton(
            icon: _isMicOn ? Icons.mic : Icons.mic_off,
            onTap: _toggleMic,
          ),
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
          _spokenText.isEmpty ? 'Listening...' : '"$_spokenText"',
         // maxLines: 3,
          minFontSize: 8,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            height: 1.6,
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
                    onTap: () {
                      setState(() => _selectedLang = lang);
                      // ── Language change এ listening restart ──
                      if (_isMicOn && _speechReady) {
                        _stopListening();
                        _startListening();
                      }
                    },
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