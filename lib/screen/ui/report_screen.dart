import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/HistoryDetailResponse.dart';
import '../../network/network_called.dart';
import 'package:ai_interview/network/Api_URL.dart';

class ReportScreen extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;

  const ReportScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bg            = Color(0xFFF0F1F5);
  static const Color _surface       = Colors.white;
  static const Color _textPrimary   = Color(0xFF0F0F1A);
  static const Color _textSecondary = Color(0xFF9CA3AF);
  static const Color _border        = Color(0xFFE8EAF0);
  static const Color _accent        = Color(0xFF4F46E5);
  static const Color _green         = Color(0xFF22C55E);
  static const Color _yellow        = Color(0xFFF59E0B);
  static const Color _red           = Color(0xFFEF4444);

  bool _isLoading      = true;
  bool _hasError       = false;
  String _errorMessage = '';
  HistoryDetailResponse? _data;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchReport() async {
    setState(() { _isLoading = true; _hasError = false; });
    final url = '${ApiURL.baseURL}history/${widget.sessionId}/analysis';
    final response = await NetworkCaller.getRequest(url);
    if (!mounted) return;
    if (response.isSuccess && response.responseData != null) {
      try {
        setState(() {
          _data      = HistoryDetailResponse.fromJson(response.responseData as Map<String, dynamic>);
          _isLoading = false;
        });
      } catch (e) {
        setState(() { _hasError = true; _errorMessage = 'Failed to parse report.'; _isLoading = false; });
      }
    } else {
      setState(() {
        _hasError     = true;
        _errorMessage = response.errorMessage.isNotEmpty ? response.errorMessage : 'Something went wrong.';
        _isLoading    = false;
      });
    }
  }

  Color _scoreColor(int? score) {
    if (score == null) return _textSecondary;
    if (score >= 80)   return const Color(0xFF6C63FF);
    if (score >= 60)   return _yellow;
    return _red;
  }

  Color _verdictColor(String v) {
    switch (v.toLowerCase()) {
      case 'strong hire': return _green;
      case 'hire':        return const Color(0xFF3B82F6);
      case 'maybe':       return _yellow;
      default:            return _red;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) { return dateStr; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: _textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.sessionTitle,
              style: const TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: _textSecondary),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _fetchReport,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(12)),
                  child: const Text("Retry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAnalysisTab(_data!.session, _data!.analysis),
              _buildSummaryTab(_data!.session, _data!.analysis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(10)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: _textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [Tab(text: "Analysis"), Tab(text: "Summary")],
      ),
    );
  }

  // ── Analysis Tab ─────────────────────────────────────────────────────────
  Widget _buildAnalysisTab(HistoryDetailSession session, AnalysisResult analysis) {
    final scoreColor = _scoreColor(session.score);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [

        // ── Hero Score Card (Image 2 style) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Text(
                analysis.headline,
                style: const TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text("Here is your performance summary.", style: TextStyle(color: _textSecondary, fontSize: 13)),
              const SizedBox(height: 24),

              // Score gauge
              _buildScoreGauge(session.score, scoreColor),

              const SizedBox(height: 28),

              // Performance breakdown
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "PERFORMANCE BREAKDOWN",
                  style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 16),
              _buildBreakdownBar("Communication",    Icons.chat_bubble_outline_rounded, analysis.performance.communication,    const Color(0xFF3B82F6)),
              _buildBreakdownBar("Technical Accuracy", Icons.code_rounded,              analysis.performance.technicalAccuracy, const Color(0xFFEC4899)),
              _buildBreakdownBar("Confidence",       Icons.bolt_rounded,                analysis.performance.confidence,        const Color(0xFFF59E0B)),
              _buildBreakdownBar("Structure",        Icons.layers_rounded,              analysis.performance.structure,         const Color(0xFF22C55E)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Verdict ──
        _verdictCard(analysis.verdict),
        const SizedBox(height: 16),

        // ── Overall summary ──
        _sectionTitle("Overall Performance"),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Text(analysis.overallSummary,
              style: const TextStyle(color: _textPrimary, fontSize: 14, height: 1.6)),
        ),
        const SizedBox(height: 16),

        // ── Strengths (Image 1 style cards) ──
        _sectionTitle("Strengths"),
        const SizedBox(height: 8),
        ...analysis.strengths.map((s) => _feedbackCard(s, _green, Icons.thumb_up_alt_rounded)),

        const SizedBox(height: 8),
        _sectionTitle("Areas to Improve"),
        const SizedBox(height: 8),
        ...analysis.weaknesses.map((s) => _feedbackCard(s, const Color(0xFFEC4899), Icons.trending_up_rounded)),

        const SizedBox(height: 8),
        _sectionTitle("Tips"),
        const SizedBox(height: 8),
        ...analysis.suggestions.map((s) => _feedbackCard(s, _accent, Icons.lightbulb_rounded)),
      ],
    );
  }

  // Score gauge like Image 2
  Widget _buildScoreGauge(int? score, Color color) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arc background
          CustomPaint(
            size: const Size(160, 100),
            painter: _GaugePainter(
              value: score != null ? score / 100.0 : 0,
              color: color,
            ),
          ),
          // Score text
          Positioned(
            bottom: 8,
            child: Column(
              children: [
                Text(
                  score != null ? "$score" : "N/A",
                  style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900),
                ),
                Text("SCORE", style: TextStyle(color: _textSecondary, fontSize: 11, letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownBar(String label, IconData icon, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text("$value%", style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / 100.0,
              minHeight: 7,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verdictCard(String verdict) {
    final color = _verdictColor(verdict);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text("VERDICT", style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 3),
          Text(verdict, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // Image 1 style card
  Widget _feedbackCard(AnalysisPoint point, Color color, IconData icon) {
    final tag = point.tag.toUpperCase();
    final tagColor = tag == 'TIP' ? const Color(0xFF3B82F6)
        : tag == 'IMPROVEMENT' ? const Color(0xFFEC4899)
        : _green;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent bar
          Container(
            width: 3,
            height: 60,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          // Icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(point.title,
                          style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tag,
                          style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(point.detail,
                    style: const TextStyle(color: _textSecondary, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w700));
  }



  // ── Summary Tab ──────────────────────────────────────────────────────────
  Widget _buildSummaryTab(HistoryDetailSession session, AnalysisResult analysis) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _summaryRow("Category",   session.category),
        _summaryRow("Topics",     session.topics.join(', ')),
        _summaryRow("Difficulty", session.difficulty),
        _summaryRow("Mode",       session.mode),
        _summaryRow("Duration",   session.duration),
        _summaryRow("Questions",  "${session.questionCount}"),
        _summaryRow("Score",      session.score != null ? "${session.score}/100" : "N/A"),
        _summaryRow("Date",       _formatDate(session.date)),
        _summaryRow("Candidate",  session.candidateName),
        _summaryRow("Verdict",    analysis.verdict),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: _textSecondary, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Shimmer ──────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EAF0),
      highlightColor: const Color(0xFFF5F5F5),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 16),
          Container(height: 320, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 12),
          Container(height: 60,  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
          const SizedBox(height: 12),
          ...List.generate(4, (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 90,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          )),
        ],
      ),
    );
  }
}

// ── Gauge Painter ────────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.85;
    final radius = size.width * 0.48;
    const startAngle = 3.14159; // π  (left)
    const sweepFull  = 3.14159; // π  (half circle)

    // Background arc
    final bgPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle, sweepFull, false, bgPaint,
    );

    // Value arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle, sweepFull * value, false, fgPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value || old.color != color;
}