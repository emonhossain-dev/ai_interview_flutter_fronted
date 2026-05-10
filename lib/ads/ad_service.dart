// lib/services/ad_service.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // ──────────────────────────────────────────────
  // AD UNIT IDs
  // ──────────────────────────────────────────────

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX' // ← real ID
        : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX' // ← real ID
        : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  }

  // ──────────────────────────────────────────────
  // INITIALIZE — main.dart এ একবার call করো
  // ──────────────────────────────────────────────

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();

    _initialized = true;
    debugPrint('✅ AdMob initialized');
  }

  // ──────────────────────────────────────────────
  // INTERSTITIAL STATE
  // ──────────────────────────────────────────────

  static InterstitialAd? _interstitialAd;
  static bool _isLoaded = false;
  static bool _isLoading = false; // double-load আটকাবে

  // ──────────────────────────────────────────────
  // LOAD
  // ──────────────────────────────────────────────

  static Future<void> loadInterstitialAd() async {
    if (_isLoaded || _isLoading) return; // ইতোমধ্যে ready বা loading
    _isLoading = true;

    final completer = Completer<void>();

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;
          _isLoading = false;
          debugPrint('✅ Interstitial loaded');
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          _isLoaded = false;
          _isLoading = false;
          debugPrint('❌ Interstitial load failed: $error');
          completer.complete(); // error হলেও complete করো যাতে await আটকে না থাকে
        },
      ),
    );

    return completer.future;
  }

  // ──────────────────────────────────────────────
  // SHOW — dismiss হওয়া পর্যন্ত await করে
  // showAds = false হলে (Pro plan) skip করবে
  // ──────────────────────────────────────────────

  static Future<void> showInterstitialAd({required bool showAds}) async {
    if (!showAds) {
      debugPrint('ℹ️ Pro plan — ad skipped');
      return;
    }

    // Load না হলে এখন load করো এবং wait করো
    if (!_isLoaded || _interstitialAd == null) {
      debugPrint('ℹ️ Ad not ready — loading now...');
      await loadInterstitialAd();
    }

    // তারপরেও ready না হলে skip
    if (!_isLoaded || _interstitialAd == null) {
      debugPrint('ℹ️ Ad still not ready — skipping');
      return;
    }

    // ✅ Dismiss হওয়া পর্যন্ত await করার জন্য Completer
    final completer = Completer<void>();

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('✅ Interstitial dismissed');
        ad.dispose();
        _interstitialAd = null;
        _isLoaded = false;
        loadInterstitialAd(); // পরের জন্য preload
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Interstitial show failed: $error');
        ad.dispose();
        _interstitialAd = null;
        _isLoaded = false;
        if (!completer.isCompleted) completer.complete();
      },
      onAdShowedFullScreenContent: (ad) {
        debugPrint('✅ Interstitial showing');
      },
    );

    await _interstitialAd!.show();
    await completer.future; // dismiss না হওয়া পর্যন্ত এখানে থামবে
  }

  // ──────────────────────────────────────────────
  // DISPOSE
  // ──────────────────────────────────────────────

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
    _isLoading = false;
  }
}