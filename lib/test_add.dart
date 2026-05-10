import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ads/ad_service.dart'; // ← আপনার path অনুযায়ী ঠিক করুন

class TestAdd extends StatefulWidget {
  const TestAdd({super.key});

  @override
  State<TestAdd> createState() => _TestAddState();
}

class _TestAddState extends State<TestAdd> {
  // ── Banner ──
  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  // ── Status ──
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _loadBanner();
    AdService.loadInterstitialAd(); // preload
  }

  // ── Banner Load ──
  void _loadBanner() {
    setState(() => _status = 'Banner loading...');
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _bannerLoaded = true;
            _status = '✅ Banner loaded!';
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() => _status = '❌ Banner failed: ${error.message}');
        },
      ),
    )..load();
  }

  // ── Interstitial Show ──
  Future<void> _showInterstitial() async {
    setState(() => _status = 'Interstitial loading...');
    await AdService.showInterstitialAd(showAds: true);
    if (mounted) setState(() => _status = '✅ Interstitial done!');
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ad Test')),
      body: SafeArea(
        child: Column(
          children: [
            // Status
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Status: $_status',
                style: const TextStyle(fontSize: 13),
              ),
            ),

            // Banner Ad
            if (_bannerLoaded && _bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            else
              Container(
                height: 50,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: Text(
                  _bannerLoaded ? '...' : 'Banner এখনো load হয়নি',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 20),

            // Buttons
            ElevatedButton.icon(
              onPressed: _loadBanner,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Banner'),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _showInterstitial,
              icon: const Icon(Icons.fullscreen),
              label: const Text('Show Interstitial'),
            ),
          ],
        ),
      ),
    );
  }
}