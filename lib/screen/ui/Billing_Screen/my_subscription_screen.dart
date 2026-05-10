// ─────────────────────────────────────────────────────────────
// lib/screens/my_subscription_screen.dart
// ─────────────────────────────────────────────────────────────
//
// User এর current subscription, usage stats, এবং cancel option।
// Pricing screen এ navigate করার option আছে।

import 'package:flutter/material.dart';
import 'package:ai_interview/models/subscription_models.dart';

import '../../../Service/subscription_service.dart';
import 'Pricing_Screen.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────

class _C {
  static const bg         = Color(0xFFF4F6FF);
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F2FD);
  static const border     = Color(0xFFE2E6F5);
  static const textPri    = Color(0xFF111827);
  static const textSec    = Color(0xFF6B7280);
  static const textMuted  = Color(0xFFB0B7C8);
  static const pro        = Color(0xFF4F5FE8);
  static const free       = Color(0xFF64748B);
  static const green      = Color(0xFF16A34A);
  static const red        = Color(0xFFDC2626);
  static const orange     = Color(0xFFEA580C);
}

// ─────────────────────────────────────────────────────────────

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  bool _loading              = true;
  String? _errorMsg;
  SubscriptionModel? _sub;
  UsageModel? _usage;
  List<PaymentModel> _history = [];
  bool _cancelling           = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final results = await Future.wait([
        SubscriptionService.getMySubscription(),
        SubscriptionService.getUsage(),
        SubscriptionService.getPaymentHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _sub     = results[0] as SubscriptionModel?;
        _usage   = results[1] as UsageModel;
        _history = results[2] as List<PaymentModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMsg = e.toString(); _loading = false; });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Subscription Cancel করবে?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Cancel করলে বর্তমান period শেষে subscription expire হবে।\nআগের মতো free plan এ চলে যাবে।',
          style: TextStyle(color: _C.textSec, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না, থাকুক',
                style: TextStyle(color: _C.textSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('হ্যাঁ, Cancel করো',
                style: TextStyle(color: _C.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _cancelling = true);
    try {
      await SubscriptionService.cancelSubscription();
      await _loadData();
      if (!mounted) return;
      _showSnack('Subscription cancel হয়েছে।');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _goToPricing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PricingScreen(currentSubscription: _sub),
      ),
    ).then((_) => _loadData());
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : _C.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _C.textPri),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Subscription',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                color: _C.textPri)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _C.textSec),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.pro))
          : _errorMsg != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _C.pro,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildPlanCard(),
                      const SizedBox(height: 16),
                      if (_usage != null) _buildUsageCard(),
                      const SizedBox(height: 16),
                      _buildActionsCard(),
                      const SizedBox(height: 16),
                      if (_history.isNotEmpty) _buildHistoryCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: _C.textMuted),
        const SizedBox(height: 16),
        Text(_errorMsg!, textAlign: TextAlign.center,
            style: const TextStyle(color: _C.textSec)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('আবার চেষ্টা করো'),
          style: ElevatedButton.styleFrom(backgroundColor: _C.pro,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    ),
  );

  // ── Plan Card ─────────────────────────────────────────────
  Widget _buildPlanCard() {
    final isFree   = _sub == null || _sub!.plan.isFree;
    final color    = isFree ? _C.free : _C.pro;
    final planName = _sub?.plan.name ?? 'Free';
    final status   = _sub?.status ?? 'active';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFree
              ? [const Color(0xFF64748B), const Color(0xFF475569)]
              : [const Color(0xFF4F5FE8), const Color(0xFF7C3AED)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.35),
              blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(planName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_statusLabel(status),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 20),
        const Icon(Icons.workspace_premium_rounded,
            color: Colors.white, size: 36),
        const SizedBox(height: 12),
        Text('$planName Plan',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 4),
        if (_sub != null) ...[
          Text(
            _sub!.billingCycle == 'yearly' ? 'Yearly billing' : 'Monthly billing',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _InfoChip(
              icon: Icons.calendar_today_rounded,
              label: 'Expires ${_fmt(_sub!.currentPeriodEnd)}',
            ),
            const SizedBox(width: 10),
            _InfoChip(
              icon: Icons.timer_outlined,
              label: '${_sub!.daysLeft} days left',
            ),
          ]),
        ] else ...[
          Text('শুরু করো আজই',
              style: TextStyle(fontSize: 13,
                  color: Colors.white.withOpacity(0.8))),
        ],
      ]),
    );
  }

  Color _statusColor(String s) {
    if (s == 'active') return _C.green;
    if (s == 'cancelled') return _C.orange;
    return _C.red;
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'active': return '● Active';
      case 'cancelled': return '● Cancelled';
      case 'expired': return '● Expired';
      default: return s;
    }
  }

  // ── Usage Card ────────────────────────────────────────────
  Widget _buildUsageCard() {
    final u = _usage!;
    return _Card(
      title: 'এই মাসের Usage',
      icon: Icons.bar_chart_rounded,
      child: Column(children: [
        // interview progress
        _UsageRow(
          label: 'Interviews',
          used: u.interviewsUsed,
          limit: u.interviewLimit,
          isUnlimited: u.isUnlimited,
          color: _C.pro,
          percent: u.usagePercent,
          sublabel: u.usageLabel,
        ),
        const SizedBox(height: 16),
        // voice
        Row(children: [
          _FeatureChip(
            icon: u.hasVoiceAi
                ? Icons.mic_rounded
                : Icons.mic_off_rounded,
            label: 'Voice AI',
            active: u.hasVoiceAi,
          ),
          const SizedBox(width: 10),
          _FeatureChip(
            icon: u.showAds
                ? Icons.ads_click_rounded
                : Icons.block_rounded,
            label: u.showAds ? 'Ads On' : 'Ad-Free',
            active: !u.showAds,
          ),
          const SizedBox(width: 10),
          _FeatureChip(
            icon: Icons.psychology_rounded,
            label: u.planType == 'pro' ? 'Premium AI' : 'Basic AI',
            active: u.planType == 'pro',
          ),
        ]),
      ]),
    );
  }

  // ── Actions Card ──────────────────────────────────────────
  Widget _buildActionsCard() {
    final isFree = _sub == null || _sub!.plan.isFree;
    final isActive = _sub?.isActive ?? false;

    return _Card(
      title: 'Plan Management',
      icon: Icons.settings_rounded,
      child: Column(children: [
        // upgrade button
        if (isFree || !isActive)
          _ActionTile(
            icon: Icons.workspace_premium_rounded,
            iconColor: _C.pro,
            title: 'Pro Plan এ Upgrade করো',
            subtitle: 'Unlimited interviews + Voice AI',
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: _C.pro),
            onTap: _goToPricing,
          ),

        // change plan
        if (!isFree && isActive) ...[
          _ActionTile(
            icon: Icons.swap_horiz_rounded,
            iconColor: _C.pro,
            title: 'Plan Change করো',
            subtitle: 'Monthly ↔ Yearly switch করো',
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: _C.textMuted),
            onTap: _goToPricing,
          ),
          const Divider(color: _C.border, height: 20),
          // cancel
          _ActionTile(
            icon: _cancelling
                ? Icons.hourglass_empty_rounded
                : Icons.cancel_outlined,
            iconColor: _C.red,
            title: 'Subscription Cancel করো',
            subtitle: 'Period শেষে expire হবে',
            trailing: _cancelling
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: _C.red, strokeWidth: 2))
                : const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: _C.red),
            onTap: _cancelling ? null : _cancelSubscription,
          ),
        ],
      ]),
    );
  }

  // ── History Card ──────────────────────────────────────────
  Widget _buildHistoryCard() => _Card(
    title: 'Payment History',
    icon: Icons.receipt_long_rounded,
    child: Column(
      children: _history.take(5).map((p) => _PaymentRow(payment: p)).toList(),
    ),
  );

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: _C.pro),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: _C.textPri)),
      ]),
      const SizedBox(height: 16),
      child,
    ]),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: Colors.white),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.white,
              fontWeight: FontWeight.w500)),
    ]),
  );
}

class _UsageRow extends StatelessWidget {
  final String label;
  final int used;
  final int? limit;
  final bool isUnlimited;
  final Color color;
  final double percent;
  final String sublabel;

  const _UsageRow({
    required this.label, required this.used, this.limit,
    required this.isUnlimited, required this.color,
    required this.percent, required this.sublabel,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: _C.textPri)),
        const Spacer(),
        Text(sublabel,
            style: const TextStyle(fontSize: 12, color: _C.textSec)),
      ]),
      const SizedBox(height: 8),
      if (!isUnlimited) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.10),
            valueColor: AlwaysStoppedAnimation(
              percent >= 0.9 ? _C.red : color),
          ),
        ),
        const SizedBox(height: 4),
        if (percent >= 0.9)
          const Text('Daily limit প্রায় শেষ!',
              style: TextStyle(fontSize: 11, color: _C.red,
                  fontWeight: FontWeight.w500)),
      ] else
        Row(children: [
          Icon(Icons.all_inclusive_rounded, size: 14, color: color),
          const SizedBox(width: 5),
          const Text('Unlimited',
              style: TextStyle(fontSize: 12, color: _C.green,
                  fontWeight: FontWeight.w500)),
        ]),
    ],
  );
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _FeatureChip({required this.icon, required this.label,
      required this.active});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: active
          ? const Color(0xFF4F5FE8).withOpacity(0.08)
          : _C.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: active
            ? const Color(0xFF4F5FE8).withOpacity(0.2)
            : _C.border),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13,
          color: active ? _C.pro : _C.textMuted),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
              color: active ? _C.pro : _C.textMuted)),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon, required this.iconColor, required this.title,
    required this.subtitle, required this.trailing, this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: _C.textPri)),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: _C.textSec)),
        ],
      )),
      trailing,
    ]),
  );
}

class _PaymentRow extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final success = payment.status == 'success';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: success
                ? _C.green.withOpacity(0.08)
                : _C.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            success ? Icons.check_rounded : Icons.close_rounded,
            size: 18, color: success ? _C.green : _C.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(payment.gateway?.toUpperCase() ?? 'Payment',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _C.textPri)),
          Text(_fmt(payment.createdAt),
              style: const TextStyle(fontSize: 11, color: _C.textSec)),
        ])),
        Text(
          '৳${payment.amount.toStringAsFixed(0)} ${payment.currency}',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: success ? _C.green : _C.red),
        ),
      ]),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
