import 'dart:convert';
import 'package:ai_interview/network/Api_URL.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'DrawerScreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  WebSocketChannel? channel;
  final Dio dio = Dio();

  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [];

  final String userId = "11";

  bool isSocketConnected = false;
  bool isAiTyping = false;

  late AnimationController _typingController;

  double _dragOffset = 0.0;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  bool _drawerVisible = false;

  // ── Color palette ──────────────────────────────
  static const Color _bg            = Color(0xFFF5F6FA);
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
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [

          // ── Layer 1: DrawerScreen - full screen এ থাকবে পেছনে ──
          if (_drawerVisible)
            Positioned.fill(
              child: DrawerScreen(
                messages: messages,
                onClose: _closeDrawer,
              ),
            ),

          // ── Layer 2: ChatScreen - সামনে থাকবে, slide হলে সরে যাবে ──
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              // animation value (0.0 → 1.0) * screenWidth + drag offset
              final offset = -(_slideAnimation.value * screenWidth + _dragOffset);
              final clampedOffset = offset.clamp(-screenWidth, 0.0);

              return Transform.translate(
                offset: Offset(clampedOffset, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                _dragOffset = 0.0;

                if (!_drawerVisible) {
                  setState(() {
                    _drawerVisible = true;
                  });

                  // important: animation instantly 0 থেকে start
                  _slideController.value = 0.0;
                }
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  // 1:1 finger follow (no artificial damping here)
                  _dragOffset += details.delta.dx;

                  final total =
                      (_slideController.value * screenWidth) - _dragOffset;

                  final clamped = total.clamp(0.0, screenWidth);

                  // direct mapping = finger exactly matches UI
                  _slideController.value = clamped / screenWidth;

                  // reset offset so it doesn’t accumulate lag
                  _dragOffset = 0.0;
                });
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;

                final shouldOpen =
                    velocity > 600 || _slideController.value > 0.6;

                setState(() => _dragOffset = 0.0);

                if (shouldOpen) {
                  _slideController.forward();
                  _drawerVisible = true;
                } else {
                  _slideController.reverse().then((_) {
                    if (mounted) setState(() => _drawerVisible = false);
                  });
                }
              },
              // drawer open থাকলে chat area tap করলে close হবে
              onTap: _drawerVisible ? _closeDrawer : null,
              child: _buildChatScaffold(),
            ),
          ),
        ],
      ),
    );
  }

  void connectSocket() {
    isSocketConnected = false;

    channel = WebSocketChannel.connect(
      Uri.parse(ApiURL.Chat_URL),
    );

    channel!.stream.listen(
          (data) {
        final decoded = jsonDecode(data);
        if (!mounted) return;
        setState(() {
          isAiTyping = false;
          messages.add({
            "sender": "ai",
            "text": decoded["message"] ?? data.toString(),
          });
        });
        _scrollToBottom();
      },
      onError: (error) {
        print("Socket error: $error");
        setState(() {
          isSocketConnected = false;
          isAiTyping = false;
        });
      },
      onDone: () {
        print("Socket closed");
        setState(() {
          isSocketConnected = false;
          isAiTyping = false;
        });
      },
    );

    channel!.sink.add(jsonEncode({"user_id": userId}));

    setState(() {
      isSocketConnected = true;
    });
  }

  void sendMessage() {
    if (controller.text.isEmpty) return;
    if (!isSocketConnected) return;

    final text = controller.text;

    setState(() {
      messages.add({"sender": "user", "text": text});
      isAiTyping = true;
    });

    channel!.sink.add(jsonEncode({"message": text}));

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

  @override
  void dispose() {
    _typingController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    channel?.sink.close();
    controller.dispose();
    super.dispose();
  }

  void _openDrawer() {
    setState(() => _drawerVisible = true);

    _slideController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _closeDrawer() {
    _slideController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    ).then((_) {
      if (mounted) {
        setState(() => _drawerVisible = false);
      }
    });
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  Widget buildMessage(Map<String, String> msg, bool showAvatar) {
    final bool isUser = msg["sender"] == "user";

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 16,
        right: isUser ? 16 : 60,
        top: 3,
        bottom: 3,
      ),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && showAvatar) ...[
            _aiAvatar(size: 30),
            const SizedBox(width: 8),
          ] else if (!isUser) ...[
            const SizedBox(width: 38),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? _userBubble : _aiBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 5),
                      bottomRight: Radius.circular(isUser ? 5 : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: _border, width: 1.2),
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
                    msg["text"] ?? "",
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
                    _timeNow(),
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 10,
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

  Widget _aiAvatar({double size = 34}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: size * 0.52),
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
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 34),
          ),
          const SizedBox(height: 20),
          const Text(
            "AI Assistant",
            style: TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Start a conversation",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isSocketConnected
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isSocketConnected
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444))
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
            color: isSocketConnected
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _aiAvatar(size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "AI Assistant",
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildStatusDot(),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.menu_open, color: _textSecondary),
                onPressed: _drawerVisible ? _closeDrawer : _openDrawer,
              ),
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
                    (index == 0 ||
                        messages[index - 1]["sender"] != "ai");
                return buildMessage(msg, showAvatar);
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _surface,
              border:
              const Border(top: BorderSide(color: _border, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 130),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border, width: 1.2),
                    ),
                    child: TextField(
                      controller: controller,
                      enabled: isSocketConnected,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14.5,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: const InputDecoration(
                        hintText: "Message...",
                        hintStyle: TextStyle(
                          color: _textSecondary,
                          fontSize: 14.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: isSocketConnected ? sendMessage : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isSocketConnected
                          ? const LinearGradient(
                        colors: [
                          Color(0xFF4F46E5),
                          Color(0xFF818CF8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSocketConnected ? null : _border,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSocketConnected
                          ? [
                        BoxShadow(
                          color: _accent.withOpacity(0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                          : null,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: isSocketConnected
                          ? Colors.white
                          : _textSecondary,
                      size: 20,
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