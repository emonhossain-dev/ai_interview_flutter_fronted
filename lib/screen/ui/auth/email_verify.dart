import 'package:flutter/material.dart';

class EmailVerifyScreen extends StatefulWidget {
  final String email;

  const EmailVerifyScreen({
    super.key,
    this.email = 'user@example.com',
  });

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  final List<String> _otpDigits = List.filled(6, '');
  int _currentIndex = 0;
  int _resendSeconds = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 30;
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

  void _onKeyPress(String value) {
    if (_currentIndex < 6) {
      setState(() {
        _otpDigits[_currentIndex] = value;
        _currentIndex++;
      });
    }
  }

  void _onBackspace() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _otpDigits[_currentIndex] = '';
      });
    }
  }

  void _onVerify() {
    final otp = _otpDigits.join();
    if (otp.length < 6) return;
    debugPrint('OTP entered: $otp');
    // TODO: call your verify API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF333333),
                    size: 22,
                  ),
                ),
              ),
            ),

            // ── Title + subtitle ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 13,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                            text: 'We sent a 6-digit code to your email\n'),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(
                            color: Color(0xFF4A90E2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── OTP boxes ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  final isFilled = _otpDigits[i].isNotEmpty;
                  final isActive = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF4A90E2)
                            : isFilled
                            ? const Color(0xFFCCCCCC)
                            : Colors.transparent,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _otpDigits[i],
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // ── Resend + Change Email ──
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "You didn't receive any code? ",
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: _canResend ? _startResendTimer : null,
                        child: Text(
                          _canResend
                              ? 'Resend OTP'
                              : 'Resend OTP ($_resendSeconds s)',
                          style: TextStyle(
                            color: _canResend
                                ? const Color(0xFF4A90E2)
                                : const Color(0xFF4A90E2),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Text(
                      'Change Email',
                      style: TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Verify button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _currentIndex == 6 ? _onVerify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    disabledBackgroundColor: const Color(0xFFB0C8EE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Verify Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // ── Custom number keyboard ──
            _buildKeyboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3']),
          const SizedBox(height: 6),
          _buildKeyRow(['4', '5', '6']),
          const SizedBox(height: 6),
          _buildKeyRow(['7', '8', '9']),
          const SizedBox(height: 6),
          _buildKeyRow(['', '0', 'back']),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        if (key.isEmpty) {
          return const Expanded(child: SizedBox());
        }
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                if (key == 'back') {
                  _onBackspace();
                } else {
                  _onKeyPress(key);
                }
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: key == 'back'
                    ? const Icon(
                  Icons.backspace_outlined,
                  size: 20,
                  color: Color(0xFF333333),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      key,
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_keySubtitle(key).isNotEmpty)
                      Text(
                        _keySubtitle(key),
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _keySubtitle(String key) {
    const subtitles = {
      '2': 'ABC',
      '3': 'DEF',
      '4': 'GHI',
      '5': 'JKL',
      '6': 'MNO',
      '7': 'PQRS',
      '8': 'TUV',
      '9': 'WXYZ',
    };
    return subtitles[key] ?? '';
  }
}