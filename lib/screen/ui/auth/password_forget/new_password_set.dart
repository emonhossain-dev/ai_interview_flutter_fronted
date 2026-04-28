import 'package:ai_interview/screen/ui/auth/login_screen.dart';
import 'package:flutter/material.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() =>
      _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  PasswordStrength _strength = PasswordStrength.none;
  String _strengthLabel = '';
  Color _strengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_evaluateStrength);
  }

  void _evaluateStrength() {
    final pass = _newPasswordController.text;
    setState(() {
      if (pass.isEmpty) {
        _strength = PasswordStrength.none;
        _strengthLabel = '';
        _strengthColor = Colors.transparent;
      } else if (pass.length < 6) {
        _strength = PasswordStrength.weak;
        _strengthLabel = 'Weak';
        _strengthColor = const Color(0xFFE57373);
      } else if (pass.length < 10) {
        _strength = PasswordStrength.medium;
        _strengthLabel = 'Medium';
        _strengthColor = const Color(0xFFFFB74D);
      } else {
        _strength = PasswordStrength.strong;
        _strengthLabel = 'Strong';
        _strengthColor = const Color(0xFF4CAF50);
      }
    });
  }

  double get _strengthFraction {
    switch (_strength) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
      default:
        return 0.0;
    }
  }

  void _onResetPassword() {
    final pass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (pass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset successfully!')),
    );


    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
          (route) => false,
    );


  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // 🔥 IMPORTANT FIX
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Top bar

                  Align(
                    alignment: Alignment.center,
                    child: const Text(
                      'SECURITY',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),

                  const Text(
                    'Create New\nPassword',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Your new password must be unique from\nthose previously used.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  _PasswordField(
                    controller: _newPasswordController,
                    hint: 'New password',
                    obscure: _obscureNew,
                    onToggle: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),

                  const SizedBox(height: 12),

                  if (_strength != PasswordStrength.none) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Password Strength',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        Text(
                          _strengthLabel,
                          style: TextStyle(
                            color: _strengthColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _strengthFraction,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE6E8F0),
                        valueColor:
                        AlwaysStoppedAnimation<Color>(_strengthColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _PasswordField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm password',
                    obscure: _obscureConfirm,
                    onToggle: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                  ),


                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onResetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A67FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Reset Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// PASSWORD FIELD
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFF1F3F9),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.black45,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

enum PasswordStrength { none, weak, medium, strong }