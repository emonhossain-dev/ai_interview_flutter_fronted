import 'dart:convert';
import 'package:ai_interview/network/Api_URL.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../Service/auth_service.dart';
import '../../models/UserModel.dart';
import 'DrawerScreen.dart';

class ChatScreen extends StatefulWidget {
  final UserModel? user;

  const ChatScreen({super.key, this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  WebSocketChannel? channel;

  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [];

  bool isSocketConnected = false;
  bool isAiTyping = false;

  late AnimationController _typingController;

  double _dragOffset = 0.0;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  bool _drawerVisible = false;

  String get userId {
    final id = widget.user?.id ?? AuthService.currentUser?.id;
    return id?.toString() ?? "";
  }
  String? currentChatId;
  bool _inputFocused = false;
  late FocusNode _focusNode;

  // ── Color palette ──────────────────────────────
  static const Color _bg            = Color(0xFFE5E5E6);
  static const Color _surface       = Colors.white;
  static const Color _accent        = Color(0xFF4F46E5);
  static const Color _accentLight   = Color(0xFF818CF8);
  static const Color _textPrimary   = Color(0xFF1E1B4B);
  static const Color _textSecondary = Color(0xFF9CA3AF);
  static const Color _userBubble    = Color(0xFF4F46E5);
  static const Color _aiBubble      = Colors.white;
  static const Color _border        = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuint,
      reverseCurve: Curves.easeInOutCubic,
    );

    connectSocket();

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _inputFocused = _focusNode.hasFocus);
    });
  }

  // ── Socket ─────────────────────────────────────
  void connectSocket() {
    setState(() => isSocketConnected = false);

    channel = WebSocketChannel.connect(Uri.parse(ApiURL.Chat_URL));

    channel!.ready.then((_) {
      if (mounted) setState(() => isSocketConnected = true);
    }).catchError((e) {
      if (mounted) setState(() => isSocketConnected = false);
    });

    channel!.stream.listen(
          (data) {
        final decoded = jsonDecode(data);
        debugPrint("📨 Server response: $decoded"); // ← এইটা add করো
        if (!mounted) return;

        final reply = decoded["reply"] ?? decoded["message"] ?? "";
        if (reply.toString().trim().isEmpty) return;

        setState(() {
          isAiTyping = false;
          messages.add({
            "sender": "ai",
            "text": reply,
            "time": _formatTime(decoded["created_at"]?.toString() ?? ""), // ← change
          });
          if (decoded["chat_id"] != null) {
            currentChatId = decoded["chat_id"].toString();
          }
        });
        _scrollToBottom();
      },
      onError: (error) {
        debugPrint("Socket error: $error");
        if (mounted) setState(() {
          isSocketConnected = false;
          isAiTyping = false;
        });
      },
      onDone: () {
        debugPrint("Socket closed");
        if (mounted) setState(() {
          isSocketConnected = false;
          isAiTyping = false;
        });
      },
    );
  }

  void sendMessage() {
    if (controller.text.isEmpty) return;
    if (!isSocketConnected) return;

    debugPrint("UserID: $userId");

    if (userId.isEmpty) {
      debugPrint("❌ userId empty — user not logged in");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to send messages")),
      );
      return;
    }

    final text = controller.text;

    setState(() {
      messages.add({"sender": "user", "text": text, "time": _timeNow()});
      isAiTyping = true;
    });

    debugPrint("📤 Sending: user_id=$userId, chat_id=$currentChatId, message=$text");

    channel!.sink.add(jsonEncode({
      "user_id": userId,
      "chat_id": currentChatId,
      "message": text,
    }));

    controller.clear();
    _scrollToBottom();
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

  // ── Drawer ─────────────────────────────────────
  void _openDrawer() {
    setState(() => _drawerVisible = true);
    _slideController.animateTo(1.0,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  void _closeDrawer() {
    _slideController.animateTo(0.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic).then((_) {
      if (mounted) setState(() => _drawerVisible = false);
    });
  }

  // ── New Chat ────────────────────────────────────
  void _startNewChat() {
    setState(() {
      messages = [];
      currentChatId = null;
    });
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return _timeNow();
    }
  }

  @override
  void dispose() {
    _typingController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    channel?.sink.close();
    controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // ── Layer 1: Drawer পেছনে ──
            if (_drawerVisible)
              Positioned.fill(
                child: ChatHistoreDrawerScreen(
                  onClose: _closeDrawer,
                  userId: userId,
                  onChatSelected: (chatId, msgs) {
                    setState(() {
                      currentChatId = chatId;
                      messages = msgs;
                    });
                    _closeDrawer();
                    _scrollToBottom();
                  },
                ),
              ),

            // ── Layer 2: ChatScreen সামনে ──
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                final offset = _slideAnimation.value * screenWidth + _dragOffset;
                final clampedOffset = offset.clamp(0.0, screenWidth);

                return Transform.translate(
                  offset: Offset(clampedOffset, 0),
                  child: child,
                );
              },
              child: GestureDetector(
                onHorizontalDragStart: (_) {
                  _dragOffset = 0.0;
                  if (!_drawerVisible) {
                    setState(() => _drawerVisible = true);
                    _slideController.value = 0.0;
                  }
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragOffset += details.delta.dx;
                    final total = (_slideController.value * screenWidth) + _dragOffset;
                    final clamped = total.clamp(0.0, screenWidth);
                    _slideController.value = clamped / screenWidth;
                    _dragOffset = 0.0;
                  });
                },
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  final shouldOpen = velocity > 600 || _slideController.value > 0.4;
                  setState(() => _dragOffset = 0.0);
                  if (shouldOpen) {
                    _slideController.forward();
                    setState(() => _drawerVisible = true);
                  } else {
                    _slideController.reverse().then((_) {
                      if (mounted) setState(() => _drawerVisible = false);
                    });
                  }
                },
                onTap: _drawerVisible ? _closeDrawer : null,
                child: _buildChatScaffold(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────
  String _timeNow() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Widget _aiAvatar({double size = 34}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(color: _accent.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: size * 0.52),
    );
  }

  Widget _buildStatusDot() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: isSocketConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isSocketConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                    .withOpacity(0.45),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          isSocketConnected ? "Online" : "Offline",
          style: TextStyle(
            color: isSocketConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildMessage(Map<String, String> msg, bool showAvatar) {
    final bool isUser = msg["sender"] == "user";
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 16,
        right: isUser ? 16 : 60,
        top: 3, bottom: 3,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && showAvatar) ...[_aiAvatar(size: 30), const SizedBox(width: 8)]
          else if (!isUser) ...[const SizedBox(width: 38)],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? _userBubble : _aiBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 5),
                      bottomRight: Radius.circular(isUser ? 5 : 20),
                    ),
                    border: isUser ? null : Border.all(color: _border, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? _accent.withOpacity(0.18)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    msg["text"] ?? "",  // ← fix: text দেখাবে
                    style: TextStyle(
                      color: isUser ? Colors.white : _textPrimary,
                      fontSize: 14.5,
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    msg["time"] ?? _timeNow(),  // ← fix: saved time দেখাবে
                    style: const TextStyle(color: _textSecondary, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 60, top: 3, bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _aiAvatar(size: 30),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: _aiBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: _border, width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = (_typingController.value + i * 0.28) % 1.0;
                    final scale = t < 0.5
                        ? 1.0 + 0.45 * (t / 0.5)
                        : 1.45 - 0.45 * ((t - 0.5) / 0.5);
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      width: 7 * scale,
                      height: 7 * scale,
                      decoration: BoxDecoration(
                        color: _accentLight.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: _accent.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 8))
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 20),
          const Text("AI Assistant",
              style: TextStyle(color: _textPrimary, fontSize: 22,
                  fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          const SizedBox(height: 8),
          const Text("Start a conversation",
              style: TextStyle(color: _textSecondary, fontSize: 13.5)),
        ],
      ),
    );
  }

  Widget _buildChatScaffold() {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [

              // ── History button ──
              IconButton(
                icon: const Icon(Icons.menu_open, color: _textSecondary),
                onPressed: _drawerVisible ? _closeDrawer : _openDrawer,
                tooltip: "Chat History",
              ),

              _aiAvatar(size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("AI Assistant",
                        style: TextStyle(color: _textPrimary,
                            fontWeight: FontWeight.w700, fontSize: 15.5)),
                    const SizedBox(height: 3),
                    _buildStatusDot(),
                  ],
                ),
              ),

              /* IconButton(
                icon: const Icon(Icons.edit_outlined, color: _textSecondary),
                onPressed: _startNewChat,
                tooltip: "New Chat",
              ),*/

            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty && !isAiTyping
                ? _buildEmptyState()
                : ListView.builder(
              physics: const ClampingScrollPhysics(),
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 14),
              itemCount: messages.length + (isAiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isAiTyping) {
                  return _buildTypingIndicator();
                }
                final msg = messages[index];
                final bool showAvatar = msg["sender"] == "ai" &&
                    (index == 0 || messages[index - 1]["sender"] != "ai");
                return buildMessage(msg, showAvatar);
              },
            ),
          ),

          // ── Input bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                // ── Plus icon (বাইরে আসে focus এ) ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: _inputFocused
                      ? GestureDetector(
                    onTap: () {
                      _startNewChat();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _border, width: 1.2),
                      ),
                      child: const Icon(Icons.add, color: _textPrimary, size: 22),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),

                // ── TextField ──
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 130),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border, width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        // ── Plus icon (ভেতরে থাকে unfocused এ) ──
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: !_inputFocused
                              ? GestureDetector(
                            onTap: () {
                              // plus button click listener
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 8),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _border, width: 1.2),
                                ),
                                child: const Icon(Icons.add, color: _textPrimary, size: 20),
                              ),
                            ),
                          )
                              : const SizedBox.shrink(),
                        ),

                        // ── Text input ──
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: _focusNode,
                            enabled: isSocketConnected,
                            style: const TextStyle(color: _textPrimary, fontSize: 14.5),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => sendMessage(),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: "Message...",
                              hintStyle: TextStyle(color: _textSecondary, fontSize: 14.5),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),

                        // ── Send button (ভেতরে, text থাকলে দেখায়) ──
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: controller.text.trim().isNotEmpty
                              ? GestureDetector(
                            onTap: isSocketConnected ? sendMessage : null,
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 6, bottom: 6),
                              decoration: BoxDecoration(
                                gradient: isSocketConnected
                                    ? const LinearGradient(
                                  colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                    : null,
                                color: isSocketConnected ? null : _border,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: isSocketConnected ? Colors.white : _textSecondary,
                                size: 18,
                              ),
                            ),
                          )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}