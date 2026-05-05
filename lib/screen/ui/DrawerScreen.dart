import 'package:flutter/material.dart';

class DrawerScreen extends StatefulWidget {
  final List<Map<String, String>> messages;
  final VoidCallback onClose;

  const DrawerScreen({
    super.key,
    required this.messages,
    required this.onClose,
  });

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  static const Color _bg           = Color(0xFFE5E5E5);
  static const Color _surface      = Colors.white;
  static const Color _accent       = Color(0xFF4F46E5);
  static const Color _textPrimary  = Color(0xFF1E1B4B);
  static const Color _textSecondary= Color(0xFF9CA3AF);
  static const Color _border       = Color(0xFFE5E7EB);
  static const Color _userBubble   = Color(0xFF4F46E5);

  bool _isClosing = false;
  double? _dragStartX;

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

  void _closeIfNeeded() {
    if (!_isClosing) {
      _isClosing = true;
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userMessages = widget.messages
        .where((m) => m["sender"] == "user")
        .toList()
        .reversed
        .toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        // Remember where the swipe started (x coordinate)
        _dragStartX = details.localPosition.dx;
      },
      onHorizontalDragUpdate: (details) {
        if (_isClosing) return;
        // Only react if swipe started from left edge (first 50 pixels)
        if (_dragStartX != null && _dragStartX! < 30) {
          final delta = details.primaryDelta ?? 0;
          // Rightward swipe with enough distance (>80px)
          if (delta > 50) {
            _closeIfNeeded();
          }
        }
      },
      onHorizontalDragEnd: (details) {
        if (_isClosing) return;
        if (_dragStartX != null && _dragStartX! < 40) {
          final velocity = details.primaryVelocity ?? 0;
          // Rightward flick with enough speed (>800 dps)
          if (velocity > 100) {
            _closeIfNeeded();
          }
        }
        // Reset for next gesture
        _dragStartX = null;
      },
      child: Scaffold(
        backgroundColor: _bg,
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Chat History",
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            userMessages.isEmpty
                ? _buildEmpty()
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: userMessages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final msg = userMessages[index];
                return _buildHistoryTile(context, msg, index);
              },
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingChatButton(onClose: widget.onClose),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(BuildContext context, Map<String, String> msg, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg["text"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "You",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDFE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFF4F46E5),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No history yet",
            style: TextStyle(
              color: Color(0xFF1E1B4B),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Your messages will appear here",
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingChatButton extends StatelessWidget {
  final VoidCallback onClose;

  const FloatingChatButton({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}