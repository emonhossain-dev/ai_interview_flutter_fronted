// ─────────────────────────────────────────────
// lib/models/subscription_models.dart
// ─────────────────────────────────────────────

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
  final String aiModelTier;

  PlanModel({
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

  bool get isFree => type == 'free';
  bool get isPro => type == 'pro';
  bool get isUnlimited => interviewLimit == null;

  factory PlanModel.fromJson(Map<String, dynamic> j) => PlanModel(
    id: j['id'],
    name: j['name'],
    type: j['type'],
    monthlyPrice: (j['monthly_price'] as num).toDouble(),
    yearlyPrice: (j['yearly_price'] as num).toDouble(),
    interviewLimit: j['interview_limit'],
    hasVoiceAi: j['has_voice_ai'] ?? false,
    hasAdvancedReport: j['has_advanced_report'] ?? false,
    showAds: j['show_ads'] ?? true,
    aiModelTier: j['ai_model_tier'] ?? 'basic',
  );
}

class SubscriptionModel {
  final String id;
  final String billingCycle; // "monthly" | "yearly"
  final String status; // "active" | "cancelled" | "expired"
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? cancelledAt;
  final PlanModel plan;

  SubscriptionModel({
    required this.id,
    required this.billingCycle,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.cancelledAt,
    required this.plan,
  });

  bool get isActive => status == 'active';

  /// Renewal বা expiry date দেখানোর জন্য
  String get periodEndFormatted {
    final d = currentPeriodEnd;
    return '${d.day}/${d.month}/${d.year}';
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> j) =>
      SubscriptionModel(
        id: j['id'],
        billingCycle: j['billing_cycle'],
        status: j['status'],
        currentPeriodStart: DateTime.parse(j['current_period_start']),
        currentPeriodEnd: DateTime.parse(j['current_period_end']),
        cancelledAt: j['cancelled_at'] != null
            ? DateTime.parse(j['cancelled_at'])
            : null,
        plan: PlanModel.fromJson(j['plan']),
      );
}

class PaymentModel {
  final String id;
  final double amount;
  final String currency;
  final String status; // "success" | "failed" | "pending"
  final String? gateway;
  final String? gatewayTxnId;
  final DateTime? paidAt;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.gateway,
    this.gatewayTxnId,
    this.paidAt,
    required this.createdAt,
  });

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';

  String get formattedDate {
    final d = paidAt ?? createdAt;
    return '${d.day}/${d.month}/${d.year}';
  }

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
    id: j['id'],
    amount: (j['amount'] as num).toDouble(),
    currency: j['currency'] ?? 'BDT',
    status: j['status'],
    gateway: j['gateway'],
    gatewayTxnId: j['gateway_txn_id'],
    paidAt: j['paid_at'] != null ? DateTime.parse(j['paid_at']) : null,
    createdAt: DateTime.parse(j['created_at']),
  );
}

class UsageModel {
  final int interviewsUsed;
  final int? interviewLimit; // null = unlimited
  final int voiceMinutesUsed;
  final bool hasVoiceAi;
  final bool showAds;
  final String planName;
  final String planType;

  UsageModel({
    required this.interviewsUsed,
    this.interviewLimit,
    required this.voiceMinutesUsed,
    required this.hasVoiceAi,
    required this.showAds,
    required this.planName,
    required this.planType,
  });

  bool get isUnlimited => interviewLimit == null;
  bool get isPro => planType == 'pro';

  int get remaining =>
      isUnlimited ? 9999 : (interviewLimit! - interviewsUsed).clamp(0, interviewLimit!);

  factory UsageModel.fromJson(Map<String, dynamic> j) => UsageModel(
    interviewsUsed: j['interviews_used'] ?? 0,
    interviewLimit: j['interview_limit'],
    voiceMinutesUsed: j['voice_minutes_used'] ?? 0,
    hasVoiceAi: j['has_voice_ai'] ?? false,
    showAds: j['show_ads'] ?? true,
    planName: j['plan_name'] ?? 'Free',
    planType: j['plan_type'] ?? 'free',
  );
}