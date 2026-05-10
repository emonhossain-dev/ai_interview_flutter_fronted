// lib/widgets/banner_ad_widget.dart
//
// Usage:
//   BannerAdWidget(showAds: _usage?.showAds ?? true)
//
// showAds = true  → ad দেখাবে   (Free plan)
// showAds = false → SizedBox()  (Pro plan — কোনো space নেই)

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final bool showAds;

  const BannerAdWidget({super.key, required this.showAds});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.showAds) _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
          debugPrint('✅ Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('❌ Banner ad failed: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pro plan বা ad load হয়নি → কোনো space নেই
    if (!widget.showAds || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
