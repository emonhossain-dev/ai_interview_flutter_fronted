import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'InterviewCallScreen.dart';
import 'QuickSessionScreen.dart'; // SessionConfig এর জন্য

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Config Model — InterviewCallScreen এ pass হবে
// ─────────────────────────────────────────────────────────────────────────────
class AvatarConfig {
  final String name;
  final String role;
  final String imagePath;
  final String gender; // "male" | "female"
  final String voiceStyle; // "professional" | "friendly" | "strict"
  final String elevenLabsVoiceId;

  const AvatarConfig({
    required this.name,
    required this.role,
    required this.imagePath,
    required this.gender,
    required this.voiceStyle,
    required this.elevenLabsVoiceId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class AvatarSelectionScreen extends StatefulWidget {
  final SessionConfig sessionConfig;

  const AvatarSelectionScreen({super.key, required this.sessionConfig});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen>
    with TickerProviderStateMixin {
  // ── Colors ──
  static const Color _accent      = Color(0xFF4F46E5);
  static const Color _accentLight = Color(0xFFEEEDFE);
  static const Color _bg          = Color(0xFFF0F1F5);
  static const Color _surface     = Colors.white;
  static const Color _textPrimary = Color(0xFF0F0F1A);
  static const Color _textSecondary = Color(0xFF9CA3AF);
  static const Color _border      = Color(0xFFE8EAF0);

  // ── State ──
  String _selectedGender = 'male';
  String _selectedVoice  = 'Professional';

  // ── ElevenLabs Voice IDs — নিজের ID বসাও ──
  static const String _femaleVoiceId = 'pNInz6obpgDQGcFmaJgB'; // Rachel
  static const String _maleVoiceId   = 'pNInz6obpgDQGcFmaJgB';   // Adam

  // ── Avatars ──
  static const _avatars = [
    {
      'gender'   : 'female',
      'name'     : 'Sarah',
      'role'     : 'Senior HR Manager',
      'imagePath': 'assets/images/female_interviewer.jpg',
    },
    {
      'gender'   : 'male',
      'name'     : 'Alex',
      'role'     : 'Tech Lead Interviewer',
      'imagePath': 'assets/images/male_interviewer.jpg',
    },
  ];

  // ── Voice styles ──
  static const _voiceStyles = ['Professional', 'Friendly', 'Strict'];

  // ── Animation controllers ──
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>>   _scaleAnimations;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _scaleControllers = List.generate(
      _avatars.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
      ),
    );

    _scaleAnimations = _scaleControllers.map((ctrl) {
      return Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
    }).toList();

    // default male selected → scale in
    _scaleControllers[1].forward();
  }

  @override
  void dispose() {
    for (final c in _scaleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectAvatar(int index) {
    final gender = _avatars[index]['gender']!;
    if (_selectedGender == gender) return;

    setState(() => _selectedGender = gender);

    for (int i = 0; i < _scaleControllers.length; i++) {
      if (i == index) {
        _scaleControllers[i].forward();
      } else {
        _scaleControllers[i].reverse();
      }
    }
  }

  void _proceed() {
    final selected = _avatars.firstWhere((a) => a['gender'] == _selectedGender);

    final avatarConfig = AvatarConfig(
      name             : selected['name']!,
      role             : selected['role']!,
      imagePath        : selected['imagePath']!,
      gender           : selected['gender']!,
      voiceStyle       : _selectedVoice,
      elevenLabsVoiceId: _selectedGender == 'female'
          ? _femaleVoiceId
          : _maleVoiceId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewCallScreen(
          sessionConfig: widget.sessionConfig,
          avatarConfig : avatarConfig,
          userId: "1",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  18, 24, 18, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Choose your interviewer'),
                  const SizedBox(height: 14),
                  _buildAvatarGrid(),
                  const SizedBox(height: 28),
                  _buildSectionLabel('Voice style'),
                  const SizedBox(height: 12),
                  _buildVoiceChips(),
                  const SizedBox(height: 28),
                  _buildSessionSummary(),
                ],
              ),
            ),
          ),
          _buildBottomCTA(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B52F0), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft : Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Quick Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Step indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Step 2 of 2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'CHOOSE YOUR INTERVIEWER',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Who will interview\nyou today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar Grid ──────────────────────────────────────────────────────────
  Widget _buildAvatarGrid() {
    return Row(
      children: List.generate(_avatars.length, (index) {
        final avatar   = _avatars[index];
        final gender   = avatar['gender']!;
        final selected = _selectedGender == gender;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 0 ? 10 : 0),
            child: GestureDetector(
              onTap: () => _selectAvatar(index),
              child: ScaleTransition(
                scale: _scaleAnimations[index],
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color          : selected ? _accentLight : _surface,
                    borderRadius   : BorderRadius.circular(20),
                    border         : Border.all(
                      color: selected ? _accent : _border,
                      width: selected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color     : selected
                            ? _accent.withOpacity(0.18)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 14,
                        offset    : const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ── Photo ──
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft : Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                        child: AspectRatio(
                          aspectRatio: 0.85,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                avatar['imagePath']!,
                                fit: BoxFit.cover,
                              ),
                              // Selected overlay glow
                              if (selected)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin : Alignment.topCenter,
                                      end   : Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        _accent.withOpacity(0.15),
                                      ],
                                    ),
                                  ),
                                ),
                              // Check badge
                              if (selected)
                                Positioned(
                                  top  : 10,
                                  right: 10,
                                  child: Container(
                                    width : 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: _accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size : 16,
                                    ),
                                  ),
                                ),
                              // Live badge
                              Positioned(
                                bottom: 10,
                                left  : 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color       : Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width : 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF22C55E),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        'AI',
                                        style: TextStyle(
                                          color     : Colors.white,
                                          fontSize  : 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Info ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                        child: Column(
                          children: [
                            Text(
                              avatar['name']!,
                              style: TextStyle(
                                color     : selected ? _accent : _textPrimary,
                                fontSize  : 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              avatar['role']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color   : _textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Voice Chips ──────────────────────────────────────────────────────────
  Widget _buildVoiceChips() {
    return Row(
      children: _voiceStyles.map((style) {
        final active = _selectedVoice == style;
        return Padding(
          padding: EdgeInsets.only(
              right: style == _voiceStyles.last ? 0 : 10),
          child: GestureDetector(
            onTap: () => setState(() => _selectedVoice = style),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color       : active ? _accentLight : _surface,
                borderRadius: BorderRadius.circular(20),
                border      : Border.all(
                  color: active ? _accent : _border,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(
                style,
                style: TextStyle(
                  color     : active ? _accent : _textSecondary,
                  fontSize  : 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Session Summary ──────────────────────────────────────────────────────
  Widget _buildSessionSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color       : _surface,
        borderRadius: BorderRadius.circular(16),
        border      : Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session overview',
            style: TextStyle(
              color     : _textPrimary,
              fontSize  : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow(Icons.category_rounded,
              widget.sessionConfig.category),
          const SizedBox(height: 8),
          _summaryRow(Icons.topic_rounded,
              widget.sessionConfig.topics.join(', ')),
          const SizedBox(height: 8),
          _summaryRow(Icons.bar_chart_rounded,
              widget.sessionConfig.difficulty),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color   : _textSecondary,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Section Label ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color     : _textPrimary,
        fontSize  : 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ── Bottom CTA ───────────────────────────────────────────────────────────
  Widget _buildBottomCTA() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          18, 12, 18, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color : _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: GestureDetector(
        onTap: _proceed,
        child: Container(
          width  : double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B52F0), Color(0xFF4F46E5)],
              begin : Alignment.topLeft,
              end   : Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color     : const Color(0xFF4F46E5).withOpacity(0.3),
                blurRadius: 14,
                offset    : const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Start Interview',
                style: TextStyle(
                  color     : Colors.white,
                  fontSize  : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
