// ─────────────────────────────────────────────────────────────
// lib/screens/pricing_screen.dart
// ─────────────────────────────────────────────────────────────
//
// Backend থেকে real plan load করে।
// Subscribe করলে pending payment তৈরি হয়,
// তারপর mock payment confirm হয় (বা real bKash/SSLCommerz দিয়ে replace করো)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_interview/models/subscription_models.dart';

import '../../../Service/subscription_service.dart';

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
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class PricingScreen extends StatefulWidget {
  /// currentSubscription — null মানে user free / কোনো sub নেই।
  final SubscriptionModel? currentSubscription;

  const PricingScreen({super.key, this.currentSubscription});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen>
    with TickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────
  bool _loading          = true;
  String? _errorMsg;
  List<PlanModel> _plans = [];
  String _billing        = 'monthly'; // "monthly" | "yearly"
  String? _purchasingId;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  // ── init ───────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadPlans();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── load plans ─────────────────────────────────────────────
  Future<void> _loadPlans() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final plans = await SubscriptionService.getPlans();
      // free plan সবার আগে
      plans.sort((a, b) => a.isFree ? -1 : 1);
      setState(() { _plans = plans; _loading = false; });
      _fadeCtrl.forward();
    } catch (e) {
      setState(() { _errorMsg = e.toString(); _loading = false; });
    }
  }

  // ── subscribe flow ─────────────────────────────────────────
  Future<void> _handleSubscribe(PlanModel plan) async {
    if (plan.isFree) return; // free plan select করা যাবে না
    // already same plan active থাকলে skip
    if (_isCurrentPlan(plan)) {
      _showSnack('এই plan টি এখন active আছে।');
      return;
    }

    setState(() => _purchasingId = plan.id);
    try {
      // 1️⃣ Create subscription (pending payment)
      final sub = await SubscriptionService.subscribe(
        planId: plan.id,
        billingCycle: _billing,
      );

      // ─────────────────────────────────────────────────────
      // 2️⃣ PAYMENT GATEWAY — এখানে bKash / SSLCommerz SDK call করো।
      //    নিচে mock দেওয়া আছে (testing এর জন্য):
      //
      //   final txnId = await BkashService.pay(
      //     amount: _billing == 'yearly' ? plan.yearlyPrice : plan.monthlyPrice,
      //   );
      // ─────────────────────────────────────────────────────
      await Future.delayed(const Duration(seconds: 2)); // mock gateway delay
      final mockTxnId = 'MOCK_TXN_${DateTime.now()}';

      // 3️⃣ Confirm payment on backend
     /* await SubscriptionService.confirmPayment(
        subscriptionId: sub.id,
        //gateway       : 'bkash', // তোমার gateway
        gatewayTxnId  : mockTxnId,
      );*/

      if (!mounted) return;
      _showSuccessSheet(plan, sub);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _purchasingId = null);
    }
  }

  bool _isCurrentPlan(PlanModel plan) =>
      widget.currentSubscription?.plan.id == plan.id &&
      widget.currentSubscription?.isActive == true;

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : _C.pro,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccessSheet(PlanModel plan, SubscriptionModel sub) {
    showModalBottomSheet(
      context           : context,
      backgroundColor   : Colors.transparent,
      isScrollControlled: true,
      builder           : (_) => _SuccessSheet(plan: plan, sub: sub),
    );
  }

  // ── build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.pro))
          : _errorMsg != null
              ? _buildError()
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SafeArea(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: _buildToggle()),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _PlanCard(
                                plan         : _plans[i],
                                billing      : _billing,
                                isCurrent    : _isCurrentPlan(_plans[i]),
                                isPurchasing : _purchasingId == _plans[i].id,
                                onTap        : () => _handleSubscribe(_plans[i]),
                              ),
                              childCount: _plans.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: _buildFooter()),
                      ],
                    ),
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
          onPressed: _loadPlans,
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

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _AppIcon(),
        const SizedBox(width: 10),
        const Text('Interview Pro',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: _C.textPri)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border),
            ),
            child: const Icon(Icons.close_rounded, size: 18, color: _C.textSec),
          ),
        ),
      ]),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _C.pro.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome_rounded, size: 14,
              color: _C.pro.withOpacity(0.8)),
          const SizedBox(width: 5),
          Text('আজই Upgrade করো',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _C.pro.withOpacity(0.9))),
        ]),
      ),
      const SizedBox(height: 14),
      const Text('তোমার career এর\nজন্য সেরা plan বেছে নাও',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
              color: _C.textPri, height: 1.25)),
      const SizedBox(height: 10),
      const Text('যেকোনো সময় cancel করা যাবে। কোনো hidden charge নেই।',
          style: TextStyle(fontSize: 13.5, color: _C.textSec, height: 1.5)),
      const SizedBox(height: 20),
      Row(children: [
        _AvatarStack(),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('10,000+ চাকরিপ্রার্থী তাদের dream job পেয়েছে',
              style: TextStyle(fontSize: 12, color: _C.textSec,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
      const SizedBox(height: 24),
    ]),
  );

  Widget _buildToggle() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(children: [
        _ToggleBtn(
          label: 'Monthly',
          active: _billing == 'monthly',
          onTap: () => setState(() => _billing = 'monthly'),
        ),
        _ToggleBtn(
          label: 'Yearly',
          badge: 'Save 30%',
          active: _billing == 'yearly',
          onTap: () => setState(() => _billing = 'yearly'),
        ),
      ]),
    ),
  );

  Widget _buildFooter() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
    child: Column(children: [
      const Divider(color: _C.border),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 8,
        children: const [
          _TrustBadge(icon: Icons.lock_outline_rounded, label: 'Secure Payment'),
          _TrustBadge(icon: Icons.cancel_outlined, label: 'Cancel Anytime'),
          _TrustBadge(icon: Icons.verified_user_outlined, label: 'SSL Encrypted'),
        ],
      ),
      const SizedBox(height: 16),
      Text('© 2025 Interview Pro. All rights reserved.',
          style: const TextStyle(fontSize: 11.5, color: _C.textMuted)),
    ]),
  );
}

// ─── Toggle Button ────────────────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final String label;
  final String? badge;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.active,
      required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? _C.pro : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: active ? Colors.white : _C.textSec)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.25)
                    : _C.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge!,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _C.green)),
            ),
          ],
        ]),
      ),
    ),
  );
}

// ─── Plan Card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PlanModel plan;
  final String billing;
  final bool isCurrent;
  final bool isPurchasing;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.billing,
    required this.isCurrent,
    required this.isPurchasing,
    required this.onTap,
  });

  Color get accent => plan.isFree ? _C.free : _C.pro;

  @override
  Widget build(BuildContext context) {
    final showYearlyBadge = !plan.isFree && billing == 'yearly';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? _C.green
              : !plan.isFree
                  ? accent.withOpacity(0.3)
                  : _C.border,
          width: isCurrent ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (!plan.isFree ? accent : Colors.black).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        // ── header ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                plan.isFree
                    ? Icons.card_giftcard_rounded
                    : Icons.workspace_premium_rounded,
                color: accent, size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(plan.name,
                      style: const TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w700, color: _C.textPri)),
                  const SizedBox(width: 8),
                  if (isCurrent)
                    _Badge('Current', _C.green),
                  if (!plan.isFree && !isCurrent)
                    _Badge('Most Popular', accent),
                ]),
                const SizedBox(height: 2),
                Text(
                  plan.isFree
                      ? 'শুরু করার জন্য perfect'
                      : plan.isPro
                          ? 'Serious প্রার্থীদের জন্য'
                          : 'সব feature একসাথে',
                  style: const TextStyle(fontSize: 12, color: _C.textSec),
                ),
              ]),
            ),
          ]),
        ),

        // ── price ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              plan.priceLabel(billing),
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                  color: plan.isFree ? _C.textSec : accent,
                  letterSpacing: -0.5),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                plan.isFree
                    ? '/ forever'
                    : billing == 'yearly'
                        ? '/ year'
                        : '/ month',
                style: const TextStyle(fontSize: 13, color: _C.textSec),
              ),
            ),
            if (showYearlyBadge) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${plan.monthlyEquivalentYearly} equivalent',
                  style: const TextStyle(fontSize: 10.5, color: _C.green,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ]),
        ),

        const SizedBox(height: 16),
        const Divider(indent: 20, endIndent: 20, color: _C.border, height: 1),
        const SizedBox(height: 14),

        // ── features ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            _FeatureRow(
              text: plan.interviewLimit == null
                  ? 'Unlimited AI interviews'
                  : '${plan.interviewLimit} AI interviews per day',
              included: true, accent: accent,
            ),
            _FeatureRow(text: 'Voice AI feedback',
                included: plan.hasVoiceAi, accent: accent),
            _FeatureRow(text: 'Advanced performance report',
                included: plan.hasAdvancedReport, accent: accent),
            _FeatureRow(text: 'Ad-free experience',
                included: !plan.showAds, accent: accent),
            _FeatureRow(
              text: plan.aiModelTier == 'premium'
                  ? 'Premium AI model'
                  : 'Basic AI model',
              included: plan.aiModelTier == 'premium',
              accent: accent,
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── button ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _ActionButton(
            plan        : plan,
            isCurrent   : isCurrent,
            isPurchasing: isPurchasing,
            accent      : accent,
            billing     : billing,
            onTap       : onTap,
          ),
        ),
      ]),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: color)),
  );
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final PlanModel plan;
  final bool isCurrent;
  final bool isPurchasing;
  final Color accent;
  final String billing;
  final VoidCallback onTap;

  const _ActionButton({
    required this.plan,
    required this.isCurrent,
    required this.isPurchasing,
    required this.accent,
    required this.billing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.isFree) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _C.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: const Text('Current Free Plan',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: _C.textSec)),
      );
    }

    if (isCurrent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _C.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.green.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: _C.green, size: 17),
          const SizedBox(width: 6),
          const Text('Active Plan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: _C.green)),
        ]),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withOpacity(0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isPurchasing
            ? const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
              )
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  'Upgrade to ${plan.name}',
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700, color: Colors.white,
                      letterSpacing: 0.2),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 17),
              ]),
      ),
    );
  }
}

// ─── Feature Row ──────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String text;
  final bool included;
  final Color accent;
  const _FeatureRow({required this.text, required this.included,
      required this.accent});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(children: [
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(
          color: included ? accent.withOpacity(0.10) : _C.surfaceAlt,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          included ? Icons.check_rounded : Icons.close_rounded,
          size: 13,
          color: included ? accent : _C.textMuted,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Text(text,
          style: TextStyle(
            fontSize: 13.5,
            color: included ? _C.textPri : _C.textMuted,
            fontWeight: included ? FontWeight.w500 : FontWeight.w400,
          )),
      ),
    ]),
  );
}

// ─── Trust Badge ──────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: _C.textSec),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(fontSize: 12, color: _C.textSec,
              fontWeight: FontWeight.w500)),
    ],
  );
}

// ─── Avatar Stack ─────────────────────────────────────────────────────────────

class _AvatarStack extends StatelessWidget {
  final List<Color> _colors = const [
    Color(0xFF6366F1), Color(0xFFF59E0B),
    Color(0xFF10B981), Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 68, height: 28,
    child: Stack(
      children: List.generate(_colors.length, (i) => Positioned(
        left: i * 14.0,
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: _colors[i], shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(child: Text(
            String.fromCharCode(0x1F600 + i),
            style: const TextStyle(fontSize: 12),
          )),
        ),
      )),
    ),
  );
}

// ─── App Icon ─────────────────────────────────────────────────────────────────

class _AppIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF4F5FE8), Color(0xFF7C3AED)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4F5FE8).withOpacity(0.35), blurRadius: 10),
      ],
    ),
    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 17),
  );
}

// ─── Success Sheet ────────────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final PlanModel plan;
  final SubscriptionModel sub;
  const _SuccessSheet({required this.plan, required this.sub});

  @override
  Widget build(BuildContext context) {
    final color = plan.isFree ? _C.free : _C.pro;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12),
              blurRadius: 30, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10), shape: BoxShape.circle),
          child: Icon(Icons.check_circle_rounded, color: color, size: 38),
        ),
        const SizedBox(height: 16),
        Text('${plan.name} Plan Activated! 🎉',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                color: _C.textPri)),
        const SizedBox(height: 8),
        Text(
          'Valid until: ${_fmt(sub.currentPeriodEnd)}\nএখনই interview শুরু করো!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: _C.textSec, height: 1.6),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            Navigator.pop(context); // sheet বন্ধ
            Navigator.pop(context); // pricing screen বন্ধ
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.30),
                    blurRadius: 14, offset: const Offset(0, 5)),
              ],
            ),
            child: const Text('Start Practicing →',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
