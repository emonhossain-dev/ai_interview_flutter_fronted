import 'package:ai_interview/screen/ui/auth/password_forget/new_password_set.dart';
import 'package:flutter/material.dart';

import '../../../../network/Api_URL.dart';
import '../../../../network/network_called.dart';
import '../../../../utils/scafoled_message.dart';

class OTPVerifyScreen extends StatefulWidget {
  final String email;

  const OTPVerifyScreen({
    super.key,
    this.email = 'user@example.com',
  });

  @override
  State<OTPVerifyScreen> createState() => _OTPVerifyScreenState();
}

class _OTPVerifyScreenState extends State<OTPVerifyScreen> {
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

    _OTPVerifyAPIcall(otp);




  }

  Future<bool> _OTPVerifyAPIcall(String code) async {


    final response = await NetworkCaller.postJson(
      ApiURL.otp_verify_URL,
      {
        "email": widget.email,
        "code": code
      },
      requiresAuth: false,
    );

    if (response.isSuccess && response.statusCode == 200) {

      final message = response.responseData["message"];
      final resetToken = response.responseData["reset_token"];
      ScafoldMessage.showMessage(context, message);


      Navigator.push(context, MaterialPageRoute(
        builder: (_) => SetNewPasswordScreen(email: widget.email, reset_token: resetToken),
      ));



      debugPrint("✅ Registration Success");
      return true;
    } else {
      debugPrint("❌ ${response.errorMessage}");
      return false;
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 80),

                    // Title and Subtitle


                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            const Text(
                              "Enter OTP Code",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              "We've sent a 6-digit verification code to your device.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],

                        )
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

                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

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
              );
            }

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