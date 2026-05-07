import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ChatHistoreDrawerScreen extends StatefulWidget {
  final VoidCallback onClose;
  final String userId;
  final Function(String chatId, List<Map<String, String>> messages) onChatSelected;

  const ChatHistoreDrawerScreen({
    super.key,
    required this.onClose,
    required this.userId,
    required this.onChatSelected,
  });

  @override
  State<ChatHistoreDrawerScreen> createState() => _ChatHistoreDrawerScreenState();
}

class _ChatHistoreDrawerScreenState extends State<ChatHistoreDrawerScreen> {
  static const Color _bg           = Color(0xFFF5F6FA);
  static const Color _surface      = Colors.white;
  static const Color _accent       = Color(0xFF4F46E5);
  static const Color _textPrimary  = Color(0xFF1E1B4B);
  static const Color _textSecondary = Color(0xFF9CA3AF);
  static const Color _border       = Color(0xFFE5E7EB);

  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://2466-103-99-181-58.ngrok-free.app'));

  bool _isClosing = false;
  List<Map<String, dynamic>> _chatList = [];
  bool _loading = true;
  String _searchQuery = '';


  // State variables add করো
  int _currentPage = 1;
  static const int _limit = 20;
  bool _hasMore = true;
  bool _loadingMore = false;
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChatList();

    _listScrollController.addListener(() {
      // নিচে scroll করলে আরো load করবে
      if (_listScrollController.position.pixels >=
          _listScrollController.position.maxScrollExtent - 100) {
        if (_hasMore && !_loadingMore) _loadMoreChats();
      }
    });

  }



  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }


  // ── Time formatter ─────────────────────────────
  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  // _loadChatList() replace করো
  Future<void> _loadChatList() async {
    try {
      final res = await _dio.get(
        '/api/chats/${widget.userId}',
        queryParameters: {"page": 1, "limit": _limit},
      );
      if (!mounted) return;
      final data = res.data;
      final List chats = data["chats"];
      setState(() {
        _chatList = chats.map<Map<String, dynamic>>((c) => {
          "chat_id": c["chat_id"].toString(),
          "title": c["title"] ?? "Untitled",
        }).toList();
        _hasMore = data["has_more"] ?? false;
        _currentPage = 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

// নতুন method — পরের page load করবে
  Future<void> _loadMoreChats() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _dio.get(
        '/api/chats/${widget.userId}',
        queryParameters: {"page": _currentPage + 1, "limit": _limit},
      );
      if (!mounted) return;
      final data = res.data;
      final List chats = data["chats"];
      setState(() {
        _chatList.addAll(chats.map<Map<String, dynamic>>((c) => {
          "chat_id": c["chat_id"].toString(),
          "title": c["title"] ?? "Untitled",
        }));
        _hasMore = data["has_more"] ?? false;
        _currentPage += 1;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadMessages(String chatId, String title) async {
    if (!mounted) return;
    try {
      final res = await _dio.get('/api/chats/${widget.userId}/$chatId/messages');
      if (!mounted) return;
      final List data = res.data;
      final msgs = data.map<Map<String, String>>((m) => {
        "sender": m["role"] == "user" ? "user" : "ai",
        "text": m["content"].toString(),
        "time": _formatTime(m["created_at"]?.toString() ?? ""),
      }).toList();
      if (!mounted) return;
      widget.onChatSelected(chatId, msgs);
    } catch (e) {
      if (!mounted) return;
    }
  }

  void _closeIfNeeded() {
    if (!_isClosing) {
      _isClosing = true;
      widget.onClose();
    }
  }

  List<Map<String, dynamic>> get _filteredChats {
    if (_searchQuery.isEmpty) return _chatList;
    return _chatList.where((c) =>
        (c["title"] as String).toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) {
        if (_isClosing) return;
        if ((d.primaryDelta ?? 0) < -50) _closeIfNeeded();
      },
      onHorizontalDragEnd: (d) {
        if (!_isClosing && (d.primaryVelocity ?? 0) < -100) _closeIfNeeded();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Top bar ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                    child: Row(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 17),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "AI Assistant",
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),

                  // ── Divider ──
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: _border, height: 1),
                  ),

                  const SizedBox(height: 12),

                  // ── Recents label ──
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      "Recents",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // ── Chat list ──
                  Expanded(child: _buildChatList()),
                ],
              ),


              // ── Bottom bar ──
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  color: _bg,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 2),
                              Text(
                                "Chat",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: _textPrimary, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (_loading) return _buildShimmerList();
    if (_filteredChats.isEmpty) return _buildEmpty();

    return ListView.builder(
      controller: _listScrollController, // ← এইটা missing ছিল
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredChats.length + (_loadingMore ? 1 : 0), // ← loading indicator
      itemBuilder: (context, index) {
        if (index == _filteredChats.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: _accent),
            ),
          );
        }
        return _buildChatTile(_filteredChats[index]);
      },
    );
  }

  Widget _buildShimmerList() {
    const widthFactors = [0.72, 0.45, 0.60, 0.78, 0.50, 0.65];
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: widthFactors.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: _ShimmerBox(
              width: MediaQuery.of(context).size.width * widthFactors[index],
              height: 18,
              borderRadius: 6,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    return InkWell(
      onTap: () => _loadMessages(chat["chat_id"], chat["title"]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chat["title"] ?? "Untitled",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDFE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.history_rounded, color: _accent, size: 26),
          ),
          const SizedBox(height: 14),
          const Text("No history yet",
              style: TextStyle(color: _textPrimary,
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text("Your chats will appear here",
              style: TextStyle(color: _textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Shimmer box widget ────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 6,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFFEBEBEB),
                Color(0xFFF5F5F5),
                Color(0xFFEBEBEB),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}