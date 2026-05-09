import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// Data model passed from TopicSelectionScreen
// ─────────────────────────────────────────────────────────────────────────────
class SessionConfig {
  final String category;
  final List<String> topics;
  final String difficulty;

  const SessionConfig({
    required this.category,
    required this.topics,
    required this.difficulty,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Message model
// ─────────────────────────────────────────────────────────────────────────────
class _Message {
  final String role;   // "user" | "assistant"
  final String text;
  final bool isFeedback;

  const _Message({
    required this.role,
    required this.text,
    this.isFeedback = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class QuestionCardScreen extends StatefulWidget {
  final SessionConfig config;

  const QuestionCardScreen({super.key, required this.config});

  @override
  State<QuestionCardScreen> createState() => _QuestionCardScreenState();
}

class _QuestionCardScreenState extends State<QuestionCardScreen> {
  // ── Colors ──
  static const Color _accent        = Color(0xFF4F46E5);
  static const Color _accentLight   = Color(0xFFEEEDFE);
  static const Color _bg            = Color(0xFFF0F1F5);
  static const Color _surface       = Colors.white;
  static const Color _textPrimary   = Color(0xFF0F0F1A);
  static const Color _textSecondary = Color(0xFF9CA3AF);
  static const Color _border        = Color(0xFFE8EAF0);

  // ── State ──
  final List<_Message> _messages = [];
  final TextEditingController _answerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _awaitingAnswer = false;  // true = question shown, waiting for user
  int _questionCount = 0;
  static const int _maxQuestions = 5;

  // ── API key — replace with your key or pass via env ──
  static const String _apiKey = "YOUR_ANTHROPIC_API_KEY";

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    // Start session — AI asks first question
    WidgetsBinding.instance.addPostFrameCallback((_) => _askNextQuestion());
  }

  @override
  void dispose() {
    _answerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build system prompt ──────────────────────────────────────────────────
  String get _systemPrompt => """
You are a professional interviewer conducting a Quick Practice Session.

Session Details:
- Category: ${widget.config.category}
- Topics: ${widget.config.topics.join(", ")}
- Difficulty: ${widget.config.difficulty}

Your job:
1. Ask ONE clear interview question at a time based on the topics above.
2. After the candidate answers, give SHORT constructive feedback (2-3 sentences max):
   - What was good about the answer
   - What could be improved
   - A quick tip
3. Then ask the NEXT question.
4. Keep questions relevant to the selected topics and difficulty level.
5. Be encouraging but honest.
6. After ${_maxQuestions} questions, give a final overall summary of performance.

Format rules:
- When asking a question: start with "Q${_questionCount + 1}:" 
- When giving feedback: start with "✅ Feedback:"
- When giving final summary: start with "🎯 Session Complete!"
- Keep responses concise and clear.
- Do NOT ask multiple questions at once.
""";

  // ── Ask next question ────────────────────────────────────────────────────
  Future<void> _askNextQuestion() async {
    if (_questionCount >= _maxQuestions) return;

    setState(() => _isLoading = true);

    final historyForApi = _messages.map((m) => {
      "role": m.role,
      "content": m.text,
    }).toList();

    final userPrompt = _questionCount == 0
        ? "Start the interview. Ask the first question."
        : "Good. Now ask the next question.";

    try {
      final response = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {
          "Content-Type": "application/json",
          "x-api-key": _apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: jsonEncode({
          "model": "claude-sonnet-4-20250514",
          "max_tokens": 1000,
          "system": _systemPrompt,
          "messages": [
            ...historyForApi,
            {"role": "user", "content": userPrompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data["content"][0]["text"] as String;

        setState(() {
          _messages.add(_Message(role: "assistant", text: aiText));
          _questionCount++;
          _awaitingAnswer = true;
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        _handleError("Failed to get question. Please try again.");
      }
    } catch (e) {
      _handleError("Network error. Please check your connection.");
    }
  }

  // ── Submit answer ────────────────────────────────────────────────────────
  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_Message(role: "user", text: answer));
      _answerController.clear();
      _awaitingAnswer = false;
      _isLoading = true;
    });
    _scrollToBottom();

    final historyForApi = _messages.map((m) => {
      "role": m.role,
      "content": m.text,
    }).toList();

    // determine what to request — feedback or final summary
    final isLast = _questionCount >= _maxQuestions;
    final requestText = isLast
        ? "That was the last answer. Now give the final overall summary."
        : "Give feedback on my answer, then ask the next question.";

    try {
      final response = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {
          "Content-Type": "application/json",
          "x-api-key": _apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: jsonEncode({
          "model": "claude-sonnet-4-20250514",
          "max_tokens": 1000,
          "system": _systemPrompt,
          "messages": [
            ...historyForApi,
            {"role": "user", "content": requestText},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data["content"][0]["text"] as String;

        setState(() {
          _messages.add(_Message(
            role: "assistant",
            text: aiText,
            isFeedback: true,
          ));
          _isLoading = false;

          // if not last, ready for next answer
          if (!isLast) {
            _awaitingAnswer = true;
            _questionCount++;
          }
        });
        _scrollToBottom();
      } else {
        _handleError("Failed to get feedback. Please try again.");
      }
    } catch (e) {
      _handleError("Network error. Please check your connection.");
    }
  }

  void _handleError(String msg) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _isSessionDone =>
      _messages.any((m) => m.text.contains("🎯 Session Complete!"));

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
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    // AppBar row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showExitDialog(),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 20),
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
                        // Question counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${_questionCount.clamp(0, _maxQuestions)}/$_maxQuestions",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _questionCount / _maxQuestions,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 4,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Topic chips
                    SizedBox(
                      height: 26,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.config.topics.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.config.topics[i],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Chat area ───────────────────────────
          Expanded(
            child: _messages.isEmpty && _isLoading
                ? _buildInitialLoader()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return msg.role == "assistant"
                    ? _buildAIBubble(msg)
                    : _buildUserBubble(msg);
              },
            ),
          ),

          // ── Input area ──────────────────────────
          if (!_isSessionDone)
            _buildInputArea(),
        ],
      ),
    );
  }

  // ── Initial loader ───────────────────────────────────────────────────────
  Widget _buildInitialLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _accentLight,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(
                color: _accent,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Preparing your session...",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── AI bubble ────────────────────────────────────────────────────────────
  Widget _buildAIBubble(_Message msg) {
    final isFinal = msg.text.contains("🎯 Session Complete!");
    final isFeedback = msg.isFeedback || msg.text.contains("✅ Feedback:");

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          Container(
            width: 34, height: 34,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5B52F0), Color(0xFF4F46E5)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isFinal
                    ? const Color(0xFFEEEDFE)
                    : isFeedback
                    ? const Color(0xFFF0FDF4)
                    : _surface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: isFinal
                      ? _accent.withOpacity(0.3)
                      : isFeedback
                      ? const Color(0xFF22C55E).withOpacity(0.3)
                      : _border,
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── User bubble ──────────────────────────────────────────────────────────
  Widget _buildUserBubble(_Message msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B52F0), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Typing indicator ─────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5B52F0), Color(0xFF4F46E5)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(delay: i * 200)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input area ───────────────────────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: _answerController,
                maxLines: null,
                enabled: _awaitingAnswer && !_isLoading,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: _awaitingAnswer
                      ? "Type your answer here..."
                      : "Waiting for next question...",
                  hintStyle: TextStyle(
                    color: _textSecondary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send button
          GestureDetector(
            onTap: (_awaitingAnswer &&
                !_isLoading &&
                _answerController.text.trim().isNotEmpty)
                ? _submitAnswer
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: (_awaitingAnswer &&
                    _answerController.text.trim().isNotEmpty &&
                    !_isLoading)
                    ? const LinearGradient(
                  colors: [Color(0xFF5B52F0), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: (_awaitingAnswer &&
                    _answerController.text.trim().isNotEmpty &&
                    !_isLoading)
                    ? null
                    : _border,
                shape: BoxShape.circle,
                boxShadow: (_awaitingAnswer &&
                    _answerController.text.trim().isNotEmpty &&
                    !_isLoading)
                    ? [
                  BoxShadow(
                    color: _accent.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : null,
              ),
              child: Icon(
                Icons.send_rounded,
                color: (_awaitingAnswer &&
                    _answerController.text.trim().isNotEmpty &&
                    !_isLoading)
                    ? Colors.white
                    : _textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Exit dialog ──────────────────────────────────────────────────────────
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "End Session?",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: const Text(
          "Your progress will be lost if you leave now.",
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Continue",
                style: TextStyle(color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("End Session",
                style: TextStyle(color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated dot for typing indicator
// ─────────────────────────────────────────────────────────────────────────────
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7, height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: const BoxDecoration(
            color: Color(0xFF9CA3AF),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}