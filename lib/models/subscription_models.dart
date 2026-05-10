// ─────────────────────────────────────────────────────────────
// lib/models/subscription_models.dart
// ─────────────────────────────────────────────────────────────

class PlanModel {
  final String id;
  final String name;
  final String type; // "free" | "pro"
  final double monthlyPrice;
  final double yearlyPrice;
  final int? interviewLimit; // null = unlimited
  final bool hasVoiceAi;
  final bool hasAdvancedReport;
  final bool showAds;
  final String aiModelTier; // "basic" | "premium"

  const PlanModel({
    required this.id,
    required this.name,
    required this.type,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.interviewLimit,
    required this.hasVoiceAi,
    required this.hasAdvancedReport,
    required this.showAds,
    required this.aiModelTier,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) => PlanModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        monthlyPrice: (json['monthly_price'] as num).toDouble(),
        yearlyPrice: (json['yearly_price'] as num).toDouble(),
        interviewLimit: json['interview_limit'] as int?,
        hasVoiceAi: json['has_voice_ai'] as bool,
        hasAdvancedReport: json['has_advanced_report'] as bool,
        showAds: json['show_ads'] as bool,
        aiModelTier: json['ai_model_tier'] as String,
      );

  bool get isFree => type == 'free';
  bool get isPro => type == 'pro';

  String priceLabel(String billingCycle) {
    if (isFree) return '৳0';
    final price = billingCycle == 'yearly' ? yearlyPrice : monthlyPrice;
    return '৳${price.toStringAsFixed(0)}';
  }

  String get monthlyEquivalentYearly =>
      '৳${(yearlyPrice / 12).toStringAsFixed(0)}/মাস';
}

// ─────────────────────────────────────────────────────────────

class SubscriptionModel {
  final String id;
  final String planId;
  final String billingCycle;
  final String status; // active | cancelled | expired | trialing
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final PlanModel plan;

  const SubscriptionModel({
    required this.id,
    required this.planId,
    required this.billingCycle,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.cancelledAt,
    required this.createdAt,
    required this.plan,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionModel(
        id: json['id'] as String,
        planId: json['plan_id'] as String,
        billingCycle: json['billing_cycle'] as String,
        status: json['status'] as String,
        currentPeriodStart: DateTime.parse(json['current_period_start']),
        currentPeriodEnd: DateTime.parse(json['current_period_end']),
        cancelledAt: json['cancelled_at'] != null
            ? DateTime.parse(json['cancelled_at'])
            : null,
        createdAt: DateTime.parse(json['created_at']),
        plan: PlanModel.fromJson(json['plan'] as Map<String, dynamic>),
      );

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';

  int get daysLeft =>
      currentPeriodEnd.difference(DateTime.now()).inDays.clamp(0, 999);
}

// ─────────────────────────────────────────────────────────────

class PaymentModel {
  final String id;
  final double amount;
  final String currency;
  final String status; // pending | success | failed | refunded
  final String? gateway;
  final String? gatewayTxnId;
  final DateTime? paidAt;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.gateway,
    this.gatewayTxnId,
    this.paidAt,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        status: json['status'] as String,
        gateway: json['gateway'] as String?,
        gatewayTxnId: json['gateway_txn_id'] as String?,
        paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
        createdAt: DateTime.parse(json['created_at']),
      );
}

// ─────────────────────────────────────────────────────────────

class UsageModel {
  final int interviewsUsed;
  final int? interviewLimit; // null = unlimited
  final int voiceMinutesUsed;
  final bool hasVoiceAi;
  final bool showAds;
  final String planName;
  final String planType;

  const UsageModel({
    required this.interviewsUsed,
    this.interviewLimit,
    required this.voiceMinutesUsed,
    required this.hasVoiceAi,
    required this.showAds,
    required this.planName,
    required this.planType,
  });

  factory UsageModel.fromJson(Map<String, dynamic> json) => UsageModel(
        interviewsUsed: json['interviews_used'] as int,
        interviewLimit: json['interview_limit'] as int?,
        voiceMinutesUsed: json['voice_minutes_used'] as int,
        hasVoiceAi: json['has_voice_ai'] as bool,
        showAds: json['show_ads'] as bool,
        planName: json['plan_name'] as String,
        planType: json['plan_type'] as String,
      );

  bool get isUnlimited => interviewLimit == null;

  double get usagePercent {
    if (isUnlimited || interviewLimit == 0) return 0;
    return (interviewsUsed / interviewLimit!).clamp(0.0, 1.0);
  }

  String get usageLabel {
    if (isUnlimited) return '$interviewsUsed / Unlimited';
    return '$interviewsUsed / $interviewLimit';
  }
}
