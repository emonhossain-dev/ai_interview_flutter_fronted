// ─────────────────────────────────────────────────────────────
// lib/services/subscription_service.dart
// ─────────────────────────────────────────────────────────────
//
// তোমার existing NetworkCaller use করে লেখা।
// Api_URL.dart এ নিচের constants যোগ করো:
//
//   static const String Plans         = '$baseUrl/subscription/plans';
//   static const String MySubscription= '$baseUrl/subscription/my';
//   static const String Subscribe      = '$baseUrl/subscription/subscribe';
//   static const String CancelSub      = '$baseUrl/subscription/cancel';
//   static const String PaymentConfirm = '$baseUrl/subscription/payment/confirm';
//   static const String PaymentHistory = '$baseUrl/subscription/payment/history';
//   static const String Usage          = '$baseUrl/subscription/usage';

import 'package:ai_interview/network/Api_URL.dart';
import 'package:ai_interview/models/subscription_models.dart';

import '../network/network_called.dart';

class SubscriptionService {
  // ── Plans (auth লাগে না) ──────────────────────────────────
  static Future<List<PlanModel>> getPlans() async {
    final res = await NetworkCaller.getRequest(ApiURL.Plans);
    if (!res.isSuccess) throw res.errorMessage ?? 'Plan load হয়নি';
    final list = res.responseData as List;
    return list.map((e) => PlanModel.fromJson(e)).toList();
  }

  // ── My Subscription ───────────────────────────────────────
  static Future<SubscriptionModel?> getMySubscription() async {
    final res = await NetworkCaller.getRequest(ApiURL.MySubscription);
    if (!res.isSuccess) throw res.errorMessage ?? 'Subscription load হয়নি';
    if (res.responseData == null) return null;
    return SubscriptionModel.fromJson(res.responseData);
  }

  // ── Subscribe ─────────────────────────────────────────────
  static Future<SubscriptionModel> subscribe({
    required String planId,
    required String billingCycle, // "monthly" | "yearly"
  }) async {
    final res = await NetworkCaller.postJson(
      ApiURL.Subscribe,
      {'plan_id': planId, 'billing_cycle': billingCycle},
    );
    if (!res.isSuccess) {
      throw res.responseData?['detail'] ?? res.errorMessage ?? 'Subscribe failed';
    }
    return SubscriptionModel.fromJson(res.responseData);
  }

  // ── Payment Confirm ───────────────────────────────────────
  static Future<void> confirmPayment({
    required String subscriptionId,
    required String gateway,
    required String gatewayTxnId,
  }) async {
    final res = await NetworkCaller.postJson(
      ApiURL.PaymentConfirm,
      {
        'subscription_id': subscriptionId,
        'gateway': gateway,
        'gateway_txn_id': gatewayTxnId,
        'status': 'success',
      },
    );
    if (!res.isSuccess) {
      throw res.responseData?['detail'] ?? res.errorMessage ?? 'Payment confirm failed';
    }
  }

  // ── Cancel ────────────────────────────────────────────────
  static Future<void> cancelSubscription() async {
    final res = await NetworkCaller.postJson(ApiURL.CancelSub, {});
    if (!res.isSuccess) {
      throw res.responseData?['detail'] ?? res.errorMessage ?? 'Cancel failed';
    }
  }

  // ── Payment History ───────────────────────────────────────
  static Future<List<PaymentModel>> getPaymentHistory() async {
    final res = await NetworkCaller.getRequest(ApiURL.PaymentHistory);
    if (!res.isSuccess) throw res.errorMessage ?? 'History load হয়নি';
    final list = res.responseData as List;
    return list.map((e) => PaymentModel.fromJson(e)).toList();
  }

  // ── Usage ─────────────────────────────────────────────────
  static Future<UsageModel> getUsage() async {
    final res = await NetworkCaller.getRequest(ApiURL.Usage);
    if (!res.isSuccess) throw res.errorMessage ?? 'Usage load হয়নি';
    return UsageModel.fromJson(res.responseData);
  }
}
