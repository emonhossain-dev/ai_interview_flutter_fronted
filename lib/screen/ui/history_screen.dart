import 'package:ai_interview/screen/ui/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:ai_interview/network/Api_URL.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/HistoryResponse.dart';
import '../../network/network_called.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // ── Colors ──────────────────────────────────────────────────────────────
  static const Color _bg            = Color(0xFFF0F1F5);
  static const Color _surface       = Colors.white;
  static const Color _textPrimary   = Color(0xFF0F0F1A);
  static const Color _textSecondary = Color(0xFF9CA3AF);
  static const Color _border        = Color(0xFFE8EAF0);
  static const Color _accent        = Color(0xFF4F46E5);

  // ── State ────────────────────────────────────────────────────────────────
  String _selectedFilter = "All Time";
  final List<String> _filters = ["All Time", "This Month", "Last Month", "Older"];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading      = false;
  bool _hasError       = false;
  String _errorMessage = '';

  int  _currentPage  = 1;
  static const int _limit = 20;
  bool _hasMore      = true;
  bool _isLoadingMore = false;

  final Map<String, List<HistoryItem>> _groupedItems = {};
  final List<String> _monthOrder = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory(reset: true);

    _searchController.addListener(() {
      final q = _searchController.text.trim();
      if (q != _searchQuery) {
        _searchQuery = q;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_searchController.text.trim() == _searchQuery) {
            _fetchHistory(reset: true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filter → API param ───────────────────────────────────────────────────
  String get _filterParam {
    switch (_selectedFilter) {
      case "This Month":  return "this_month";
      case "Last Month":  return "last_month";
      case "Older":       return "older";
      default:            return "all";
    }
  }

  // ── Fetch ────────────────────────────────────────────────────────────────
  Future<void> _fetchHistory({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading   = true;
        _hasError    = false;
        _currentPage = 1;
        _hasMore     = true;
        _groupedItems.clear();
        _monthOrder.clear();
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    final url =
        '${ApiURL.baseURL}history/?page=$_currentPage&limit=$_limit'
        '&filter=$_filterParam&search=${Uri.encodeComponent(_searchQuery)}';

    final response = await NetworkCaller.getRequest(url);

    if (!mounted) return;

    if (response.isSuccess && response.responseData != null) {
      try {
        final parsed = HistoryResponse.fromJson(
          response.responseData as Map<String, dynamic>,
        );
        setState(() {
          _groupItems(parsed.sessions);
          _currentPage++;
          _hasMore     = parsed.pagination.hasNext;
          _isLoading   = false;
          _isLoadingMore = false;
        });
      } catch (e) {
        setState(() {
          _hasError      = true;
          _errorMessage  = 'Failed to parse data. Please try again.';
          _isLoading     = false;
          _isLoadingMore = false;
        });
      }
    } else {
      setState(() {
        _hasError     = true;
        _errorMessage = response.errorMessage.isNotEmpty
            ? response.errorMessage
            : 'Something went wrong. Please try again.';
        _isLoading     = false;
        _isLoadingMore = false;
      });
    }
  }

  // ── Group by month ───────────────────────────────────────────────────────
  void _groupItems(List<HistoryItem> items) {
    for (final item in items) {
      final label = _monthLabel(item.date);
      if (!_groupedItems.containsKey(label)) {
        _groupedItems[label] = [];
        _monthOrder.add(label);
      }
      _groupedItems[label]!.add(item);
    }
  }

  String _monthLabel(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        '', 'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
        'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
      ];
      return '${months[dt.month]} ${dt.year}';
    } catch (_) {
      return 'UNKNOWN';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${months[dt.month]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  // ── Score helpers ────────────────────────────────────────────────────────
  Color _scoreColor(int? score) {
    if (score == null) return _textSecondary;
    if (score >= 80)   return const Color(0xFF22C55E);
    if (score >= 60)   return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // ── Mode helpers ─────────────────────────────────────────────────────────
  IconData _modeIcon(String mode) {
    final m = mode.toLowerCase();
    if (m.contains('video'))  return Icons.videocam_rounded;
    if (m.contains('phone') || m.contains('screen')) return Icons.phone_rounded;
    return Icons.business_rounded;
  }

  Color _modeColor(String mode) {
    if (mode.toLowerCase().contains('video')) return const Color(0xFF3B82F6);
    if (mode.toLowerCase().contains('phone') || mode.toLowerCase().contains('screen'))
      return const Color(0xFF8B5CF6);
    return const Color(0xFF6B7280);
  }

  // ── Difficulty color ─────────────────────────────────────────────────────
  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':   return const Color(0xFF22C55E);
      case 'hard':   return const Color(0xFFEF4444);
      default:       return const Color(0xFFF59E0B);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildSearchBar(),
            const SizedBox(height: 14),
            _buildFilterChips(),
            const SizedBox(height: 18),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "History",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Past interviews and evaluations",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            hintText: "Search by category or topic...",
            hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: _textSecondary, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Filter chips ─────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f        = _filters[index];
          final selected = _selectedFilter == f;
          return GestureDetector(
            onTap: () {
              if (_selectedFilter != f) {
                setState(() => _selectedFilter = f);
                _fetchHistory(reset: true);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? _accent : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _accent : _border,
                  width: 1.2,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: _accent.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: selected ? Colors.white : _textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    // ✅ নতুন
    if (_isLoading) {
      return _buildShimmer();
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: _textSecondary),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _fetchHistory(reset: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Retry",
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_monthOrder.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.history_rounded, size: 48, color: _textSecondary),
            SizedBox(height: 12),
            Text(
              "No interviews found",
              style: TextStyle(color: _textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: () => _fetchHistory(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        itemCount: _monthOrder.length + 1,
        itemBuilder: (context, index) {
          // Load more / end
          if (index == _monthOrder.length) {
            // ✅ নতুন
            if (_isLoading) {
              return _buildShimmer();
            }
            if (!_hasMore) return const SizedBox(height: 8);
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => _fetchHistory(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border, width: 1.2),
                  ),
                  child: const Center(
                    child: Text(
                      "Load More",
                      style: TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            );
          }

          final month = _monthOrder[index];
          final items = _groupedItems[month]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  month,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...items.map((item) => _buildCard(item)),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard(HistoryItem item) {
    final scoreColor = _scoreColor(item.score);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: scoreColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date + Score
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 11, color: _textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          _formatDate(item.date),
                          style: const TextStyle(color: _textSecondary, fontSize: 11.5),
                        ),
                        const Spacer(),
                        // Score badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: item.score != null
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "${item.score}",
                                style: TextStyle(
                                  color: scoreColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                " /100",
                                style: TextStyle(
                                  color: scoreColor.withOpacity(0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                              : Text(
                            "No Score",
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Candidate name
                    Text(
                      item.candidateName,
                      style: const TextStyle(color: _textSecondary, fontSize: 13),
                    ),

                    const SizedBox(height: 6),

                    // Topics
                    Text(
                      item.topics.join(' · '),
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 12),
                    Container(height: 1, color: _border),
                    const SizedBox(height: 12),

                    // Tags row
                    Row(
                      children: [
                        _tag(
                          icon: Icons.access_time_rounded,
                          label: item.duration,
                          iconColor: _textSecondary,
                        ),
                        const SizedBox(width: 10),
                        _tag(
                          icon: _modeIcon(item.mode),
                          label: item.mode,
                          iconColor: _modeColor(item.mode),
                        ),
                        const SizedBox(width: 10),
                        _tag(
                          icon: Icons.bar_chart_rounded,
                          label: item.difficulty,
                          iconColor: _difficultyColor(item.difficulty),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // View Report button
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportScreen(
                                sessionId:    item.id,
                                sessionTitle: item.title,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "View Report",
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 13, color: _accent),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EAF0),
      highlightColor: const Color(0xFFF5F5F5),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left color bar
                  Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date + Score row
                          Row(
                            children: [
                              Container(
                                width: 120,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 60,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Title
                          Container(
                            width: 180,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Candidate name
                          Container(
                            width: 120,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Topics
                          Container(
                            width: 200,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Divider
                          Container(height: 1, color: Colors.white),

                          const SizedBox(height: 14),

                          // Tags row
                          Row(
                            children: [
                              Container(
                                width: 70,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 70,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 50,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // View Report button
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 90,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // ── Tag widget ───────────────────────────────────────────────────────────
  Widget _tag({required IconData icon, required String label, required Color iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _textSecondary, fontSize: 12)),
      ],
    );
  }
}