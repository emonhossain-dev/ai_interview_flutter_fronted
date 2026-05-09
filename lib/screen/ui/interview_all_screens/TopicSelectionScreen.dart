import 'package:ai_interview/screen/ui/interview_all_screens/InterviewCallScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'AvatarSelectionScreen.dart';
import 'QuickSessionScreen.dart';


// ── Data model ──────────────────────────────────────────────────────────────
class TopicCategory {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<String> topics;

  const TopicCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.topics,
  });
}

// ── Screen ───────────────────────────────────────────────────────────────────
class TopicSelectionScreen extends StatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  static const Color _accent        = Color(0xFF4F46E5);
  static const Color _accentLight   = Color(0xFFEEEDFE);
  static const Color _bg            = Color(0xFFF0F1F5);
  static const Color _surface       = Colors.white;
  static const Color _textPrimary   = Color(0xFF0F0F1A);
  static const Color _textSecondary = Color(0xFF9CA3AF);
  static const Color _border        = Color(0xFFE8EAF0);

  static const List<TopicCategory> _categories = [
    TopicCategory(
      title: "Technical",
      icon: Icons.code_rounded,
      color: Color(0xFF4F46E5),
      bgColor: Color(0xFFEEEDFE),
      topics: [
        "Data Structures", "Algorithms", "System Design",
        "OOP Concepts", "Database", "OS Concepts",
        "Networking", "Problem Solving",
      ],
    ),
    TopicCategory(
      title: "HR / Behavioral",
      icon: Icons.people_rounded,
      color: Color(0xFF059669),
      bgColor: Color(0xFFD1FAE5),
      topics: [
        "Tell Me About Yourself", "Strengths & Weaknesses",
        "Teamwork", "Leadership", "Conflict Resolution",
        "Career Goals", "Work Under Pressure", "Achievements",
      ],
    ),
    TopicCategory(
      title: "Job Role",
      icon: Icons.work_rounded,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFEF3C7),
      topics: [
        "Frontend Developer", "Backend Developer",
        "Full Stack", "Android Developer",
        "DevOps", "Data Scientist", "UI/UX Designer", "QA Engineer",
      ],
    ),
    TopicCategory(
      title: "English Speaking",
      icon: Icons.record_voice_over_rounded,
      color: Color(0xFFDB2777),
      bgColor: Color(0xFFFCE7F3),
      topics: [
        "Introduction", "Describe Your Experience",
        "Explain a Project", "Opinion Questions",
        "Vocabulary Practice", "Fluency Building",
        "Formal Communication", "Email Writing",
      ],
    ),
  ];

  String? _selectedCategory;
  final Set<String> _selectedTopics = {};
  final TextEditingController _customController = TextEditingController();
  bool _showCustomField = false;
  String _difficulty = "Medium"; // ✅ parent এ difficulty state

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  TopicCategory? get _currentCategory => _selectedCategory == null
      ? null
      : _categories.firstWhere((c) => c.title == _selectedCategory);

  bool get _canProceed =>
      _selectedTopics.isNotEmpty ||
          (_showCustomField && _customController.text.trim().isNotEmpty);

  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  void _selectCategory(String title) {
    setState(() {
      if (_selectedCategory == title) {
        _selectedCategory = null;
        _selectedTopics.clear();
      } else {
        _selectedCategory = title;
        _selectedTopics.clear();
      }
      _showCustomField = false;
      _customController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5B52F0), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
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
                              "Quick Session",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 36),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "CHOOSE YOUR FOCUS",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "What do you want to\npractice today?",
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
          ),

          // ── Body ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  18, 20, 18, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Select Category",
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat.title;
                      return GestureDetector(
                        onTap: () => _selectCategory(cat.title),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: selected ? cat.bgColor : _surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? cat.color : _border,
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selected
                                    ? cat.color.withOpacity(0.15)
                                    : Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? cat.color.withOpacity(0.15)
                                        : cat.bgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(cat.icon,
                                      color: cat.color, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.title,
                                    style: TextStyle(
                                      color: selected
                                          ? cat.color
                                          : _textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (_currentCategory != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          "Select Topics",
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "(${_selectedTopics.length} selected)",
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._currentCategory!.topics.map((topic) {
                          final selected = _selectedTopics.contains(topic);
                          final cat = _currentCategory!;
                          return GestureDetector(
                            onTap: () => _toggleTopic(topic),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: selected ? cat.bgColor : _surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? cat.color : _border,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selected) ...[
                                    Icon(Icons.check_rounded,
                                        color: cat.color, size: 14),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    topic,
                                    style: TextStyle(
                                      color: selected
                                          ? cat.color
                                          : _textSecondary,
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showCustomField = !_showCustomField;
                              if (!_showCustomField) {
                                _customController.clear();
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: _showCustomField ? _accentLight : _surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _showCustomField ? _accent : _border,
                                width: _showCustomField ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showCustomField
                                      ? Icons.close_rounded
                                      : Icons.add_rounded,
                                  color: _showCustomField
                                      ? _accent
                                      : _textSecondary,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Custom Topic",
                                  style: TextStyle(
                                    color: _showCustomField
                                        ? _accent
                                        : _textSecondary,
                                    fontSize: 13,
                                    fontWeight: _showCustomField
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_showCustomField) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _accent, width: 1.5),
                        ),
                        child: TextField(
                          controller: _customController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: "e.g. Flutter State Management...",
                            hintStyle: TextStyle(
                              color: _textSecondary.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(Icons.edit_rounded,
                                color: _accent, size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],

                  if (_canProceed) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "Difficulty Level",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ✅ selected + onChanged pass করা হচ্ছে
                    _DifficultySelector(
                      selected: _difficulty,
                      onChanged: (val) => setState(() => _difficulty = val),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Bottom CTA ──────────────────────────
          if (_canProceed)
            Container(
              padding: EdgeInsets.fromLTRB(
                  18, 12, 18, 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _border, width: 1)),
              ),
              child: GestureDetector(
                onTap: () {
                  final topics = _showCustomField &&
                      _customController.text.trim().isNotEmpty
                      ? [..._selectedTopics, _customController.text.trim()]
                      : _selectedTopics.toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AvatarSelectionScreen(
                        sessionConfig: SessionConfig(
                          category: _selectedCategory!,
                          topics: topics,
                          difficulty: _difficulty,
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B52F0), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Start Practicing",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
            ),
        ],
      ),
    );
  }
}

// ── Difficulty Selector Widget ───────────────────────────────────────────────
class _DifficultySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _DifficultySelector({
    required this.selected,
    required this.onChanged,
  });

  static const _levels = [
    {"label": "Easy",   "color": Color(0xFF22C55E), "bg": Color(0xFFDCFCE7)},
    {"label": "Medium", "color": Color(0xFFD97706), "bg": Color(0xFFFEF3C7)},
    {"label": "Hard",   "color": Color(0xFFEF4444), "bg": Color(0xFFFEE2E2)},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _levels.map((level) {
        final label      = level["label"] as String;
        final color      = level["color"] as Color;
        final bg         = level["bg"]    as Color;
        final isSelected = selected == label;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(label), // ✅ parent setState trigger করে
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: label == "Hard" ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? bg : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE8EAF0),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    label == "Easy" ? "🟢" : label == "Medium" ? "🟡" : "🔴",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : const Color(0xFF9CA3AF),
                      fontSize: 12.5,
                      fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}