import 'package:flutter/material.dart';

class OTP_verify_screen extends StatefulWidget {
  const OTP_verify_screen({super.key});

  /// Show as a bottom sheet modal
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OTP_verify_screen(),
    );
  }

  @override
  State<OTP_verify_screen> createState() => _OTP_verify_screenState();
}

class _OTP_verify_screenState extends State<OTP_verify_screen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendSeconds = 59;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 59;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) _canResend = true;
      });
      return _resendSeconds > 0;
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  void _onVerify() {
    final otp = _otpValue;
    if (otp.length < 6) return;
    debugPrint('OTP verified: $otp');
    // TODO: call your verify API
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '2FA Verify',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF888888),
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Title ──
              const Center(
                child: Text(
                  'Enter OTP Code',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Subtitle ──
              const Center(
                child: Text(
                  "We've sent a 6 digit verification code to\nyour device.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── OTP boxes ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return Material(
                    child: SizedBox(
                      width: 46,
                      height: 52,
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6B35),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => _onDigitChanged(i, value),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // ── Verify OTP button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _otpValue.length == 6 ? _onVerify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    disabledBackgroundColor: const Color(0xFFFFCDB8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Didn't receive code? ──
              const Center(
                child: Text(
                  "Didn't receive code?",
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Resend button ──
              Center(
                child: GestureDetector(
                  onTap: _canResend ? _startResendTimer : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: _canResend
                              ? const Color(0xFF333333)
                              : const Color(0xFF888888),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _canResend
                              ? 'Resend Code'
                              : 'Resend Code (0:${_resendSeconds.toString().padLeft(2, '0')})',
                          style: TextStyle(
                            color: _canResend
                                ? const Color(0xFF333333)
                                : const Color(0xFF888888),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}