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
        _strengthColor = const Color(0xFFE05555);
      } else if (pass.length < 10) {
        _strength = PasswordStrength.medium;
        _strengthLabel = 'Medium';
        _strengthColor = const Color(0xFFFF9F43);
      } else {
        _strength = PasswordStrength.strong;
        _strengthLabel = 'Strong';
        _strengthColor = const Color(0xFF1DD1A1);
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
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF252540),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const Text(
                    'SECURITY',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 40), // spacer
                ],
              ),

              const SizedBox(height: 40),

              // Title
              const Text(
                'Create New\nPassword',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Your new password must be unique from\nthose previously used.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // New password field
              _PasswordField(
                controller: _newPasswordController,
                hint: 'New password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),

              const SizedBox(height: 12),

              // Strength bar
              if (_strength != PasswordStrength.none) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Password Strength',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
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
                    backgroundColor: const Color(0xFF2E2E4E),
                    valueColor:
                    AlwaysStoppedAnimation<Color>(_strengthColor),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Must be at least 8 characters.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 8),
              ],

              // Confirm password field
              _PasswordField(
                controller: _confirmPasswordController,
                hint: 'Confirm password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const Spacer(),

              // Reset button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D4DFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Reset Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable password field widget
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
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFF252540),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Color(0xFF4D4DFF), width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white38,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

enum PasswordStrength { none, weak, medium, strong }