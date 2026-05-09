import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interview Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const PricingPage(),
    );
  }
}

// ─── Colors ──────────────────────────────────────────────────────────────────

class AppColors {
  static const background   = Color(0xFFF4F6FF);   // soft lavender-white
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceAlt   = Color(0xFFF0F2FD);
  static const border       = Color(0xFFE2E6F5);
  static const textPrimary  = Color(0xFF111827);
  static const textSec      = Color(0xFF6B7280);
  static const textMuted    = Color(0xFFB0B7C8);

  static const accentPro    = Color(0xFF4F5FE8);
  static const accentFree   = Color(0xFF64748B);
  static const accentPrem   = Color(0xFFD4800A);
  static const accentGreen  = Color(0xFF16A34A);
}

// ─── Data Models ─────────────────────────────────────────────────────────────

enum BillingPeriod { monthly, yearly }

class PlanFeature {
  final String text;
  final bool included;
  const PlanFeature(this.text, {this.included = true});
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String monthlyPrice;
  final String yearlyPrice;
  final String yearlyMonthlyEquivalent;
  final String productIdMonthly;
  final String productIdYearly;
  final List<PlanFeature> features;
  final Color accentColor;
  final bool isMostPopular;
  final bool isCurrent;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.yearlyMonthlyEquivalent,
    required this.productIdMonthly,
    required this.productIdYearly,
    required this.features,
    required this.accentColor,
    this.isMostPopular = false,
    this.isCurrent = false,
  });
}

// ─── Plans ────────────────────────────────────────────────────────────────────

final List<SubscriptionPlan> _plans = [
  SubscriptionPlan(
    id: 'free',
    name: 'Free',
    monthlyPrice: '\$0',
    yearlyPrice: '\$0',
    yearlyMonthlyEquivalent: '\$0',
    productIdMonthly: '',
    productIdYearly: '',
    accentColor: AppColors.accentFree,
    isCurrent: true,
    features: const [
      PlanFeature('3 AI interviews per month'),
      PlanFeature('Basic text feedback'),
      PlanFeature('Access to 50+ sample questions'),
      PlanFeature('Unlimited AI interviews', included: false),
      PlanFeature('AI Resume analysis', included: false),
      PlanFeature('Personalised AI coaching', included: false),
    ],
  ),
  SubscriptionPlan(
    id: 'pro',
    name: 'Pro',
    monthlyPrice: '\$12',
    yearlyPrice: '\$86',
    yearlyMonthlyEquivalent: '\$7.2',
    productIdMonthly: 'interview_pro_monthly',
    productIdYearly: 'interview_pro_yearly',
    accentColor: AppColors.accentPro,
    isMostPopular: true,
    features: const [
      PlanFeature('Unlimited AI interviews'),
      PlanFeature('Advanced voice & text feedback'),
      PlanFeature('AI Resume analysis'),
      PlanFeature('Priority email support'),
      PlanFeature('Personalised AI coaching', included: false),
      PlanFeature('Interview performance analytics', included: false),
    ],
  ),
  SubscriptionPlan(
    id: 'premium',
    name: 'Premium',
    monthlyPrice: '\$29',
    yearlyPrice: '\$209',
    yearlyMonthlyEquivalent: '\$17.4',
    productIdMonthly: 'interview_premium_monthly',
    productIdYearly: 'interview_premium_yearly',
    accentColor: AppColors.accentPrem,
    features: const [
      PlanFeature('Everything in Pro'),
      PlanFeature('Personalised AI coaching'),
      PlanFeature('Interview performance analytics'),
      PlanFeature('Career roadmap suggestions'),
      PlanFeature('1-on-1 Expert mock interview'),
      PlanFeature('Resume review by HR expert'),
    ],
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage>
    with TickerProviderStateMixin {
  BillingPeriod _billing = BillingPeriod.monthly;
  String? _selectedPlanId;
  bool _isPurchasing = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

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
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase(SubscriptionPlan plan) async {
    if (plan.id == 'free') return;
    setState(() {
      _selectedPlanId = plan.id;
      _isPurchasing = true;
    });

    // TODO: Replace with real Google Play IAP:
    //
    //   final InAppPurchase iap = InAppPurchase.instance;
    //   final productId = _billing == BillingPeriod.monthly
    //       ? plan.productIdMonthly : plan.productIdYearly;
    //   final ProductDetailsResponse r = await iap.queryProductDetails({productId});
    //   if (r.productDetails.isNotEmpty) {
    //     await iap.buyNonConsumable(
    //       purchaseParam: PurchaseParam(productDetails: r.productDetails.first));
    //   }

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _isPurchasing = false;
      _selectedPlanId = null;
    });
    _showSuccessSheet(plan);
  }

  void _showSuccessSheet(SubscriptionPlan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SuccessSheet(plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
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
                        (context, i) => _PlanCard(
                      plan: _plans[i],
                      billing: _billing,
                      isSelected: _selectedPlanId == _plans[i].id,
                      isPurchasing:
                      _isPurchasing && _selectedPlanId == _plans[i].id,
                      onTap: () => _handlePurchase(_plans[i]),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App bar row
          Row(
            children: [
              const _AppIcon(),
              const SizedBox(width: 10),
              const Text(
                'Interview Pro',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSec,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSec),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose Your Plan',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade your interview preparation\nand land your dream job.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSec,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
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
            _ToggleTab(
              label: 'Monthly',
              isActive: _billing == BillingPeriod.monthly,
              onTap: () => setState(() => _billing = BillingPeriod.monthly),
            ),
            _ToggleTab(
              label: 'Yearly',
              isActive: _billing == BillingPeriod.yearly,
              badge: 'SAVE 40%',
              onTap: () => setState(() => _billing = BillingPeriod.yearly),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        children: [
          // Trust badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _TrustBadge(icon: Icons.lock_outline_rounded, label: 'Secure Payment'),
              SizedBox(width: 24),
              _TrustBadge(icon: Icons.cancel_outlined, label: 'Cancel Anytime'),
            ],
          ),
          const SizedBox(height: 20),

          // User avatars + trust count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AvatarStack(),
              const SizedBox(width: 10),
              const Text(
                '10,000+ users trust us',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSec,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Subscriptions are billed through Google Play.\nCancellation takes effect at end of current billing period.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _linkText('Terms'),
              Text(' · ', style: TextStyle(color: AppColors.textMuted)),
              _linkText('Privacy'),
              Text(' · ', style: TextStyle(color: AppColors.textMuted)),
              _linkText('Restore Purchase'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linkText(String label) => GestureDetector(
    onTap: () {},
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.accentPro,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

// ─── Toggle Tab ───────────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentPro : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: AppColors.accentPro.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textSec,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.accentGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Plan Card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final BillingPeriod billing;
  final bool isSelected;
  final bool isPurchasing;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.billing,
    required this.isSelected,
    required this.isPurchasing,
    required this.onTap,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween(begin: 1.0, end: 0.975)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  String get _price {
    if (widget.plan.id == 'free') return widget.plan.monthlyPrice;
    return widget.billing == BillingPeriod.monthly
        ? widget.plan.monthlyPrice
        : widget.plan.yearlyMonthlyEquivalent;
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isPopular = plan.isMostPopular;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? plan.accentColor
                  : isPopular
                  ? plan.accentColor.withOpacity(0.4)
                  : AppColors.border,
              width: widget.isSelected || isPopular ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isPopular
                    ? plan.accentColor.withOpacity(0.12)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isPopular ? 24 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular) _buildPopularBadge(plan.accentColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(plan),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 16),
                    ...plan.features
                        .map((f) => _FeatureRow(feature: f, accent: plan.accentColor)),
                    const SizedBox(height: 18),
                    _buildButton(plan),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularBadge(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
      ),
      child: const Text(
        '⭐  MOST POPULAR',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildHeader(SubscriptionPlan plan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero)
                              .animate(anim),
                          child: child,
                        )),
                    child: Text(
                      _price,
                      key: ValueKey(_price),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: plan.id == 'free'
                            ? AppColors.textPrimary
                            : plan.accentColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    plan.id == 'free' ? '/ forever' : '/month',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
              if (plan.id != 'free' &&
                  widget.billing == BillingPeriod.yearly) ...[
                const SizedBox(height: 3),
                Text(
                  'Billed ${plan.yearlyPrice}/year',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        // Plan icon
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: plan.accentColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            plan.id == 'free'
                ? Icons.bolt_rounded
                : plan.id == 'pro'
                ? Icons.workspace_premium_rounded
                : Icons.diamond_rounded,
            color: plan.accentColor,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(SubscriptionPlan plan) {
    // Free / current plan — ghost button
    if (plan.id == 'free' && plan.isCurrent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Current Plan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.isPurchasing ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [plan.accentColor, plan.accentColor.withOpacity(0.80)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: plan.accentColor.withOpacity(0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: widget.isPurchasing
            ? const SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              plan.id == 'premium'
                  ? 'Go Premium'
                  : 'Upgrade to ${plan.name}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 17),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Row ──────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final PlanFeature feature;
  final Color accent;
  const _FeatureRow({required this.feature, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: feature.included
                  ? accent.withOpacity(0.10)
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              feature.included ? Icons.check_rounded : Icons.close_rounded,
              size: 13,
              color: feature.included ? accent : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              feature.text,
              style: TextStyle(
                fontSize: 13.5,
                color: feature.included
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontWeight:
                feature.included ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trust Badge ──────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSec),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSec,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Avatar Stack ─────────────────────────────────────────────────────────────

class _AvatarStack extends StatelessWidget {
  final List<Color> _colors = const [
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 28,
      child: Stack(
        children: List.generate(
          _colors.length,
              (i) => Positioned(
            left: i * 14.0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _colors[i],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(0x1F600 + i),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── App Icon ─────────────────────────────────────────────────────────────────

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F5FE8), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F5FE8).withOpacity(0.35),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 17),
    );
  }
}

// ─── Success Sheet ────────────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final SubscriptionPlan plan;
  const _SuccessSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: plan.accentColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded,
                color: plan.accentColor, size: 38),
          ),
          const SizedBox(height: 16),
          Text(
            '${plan.name} Activated! 🎉',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your subscription is now active.\nStart acing your interviews!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSec,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: plan.accentColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: plan.accentColor.withOpacity(0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Text(
                'Start Practicing →',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}