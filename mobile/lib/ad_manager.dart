import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager with WidgetsBindingObserver {
  AdManager._();
  static final AdManager instance = AdManager._();

  static const bannerId = 'ca-app-pub-4455023088168031/9834642813';
  static const appOpenId = 'ca-app-pub-4455023088168031/1868347878';
  static const interstitialId = 'ca-app-pub-4455023088168031/1537350393';

  BannerAd? banner;
  final ValueNotifier<int> bannerVersion = ValueNotifier<int>(0);
  AppOpenAd? _appOpen;
  InterstitialAd? _interstitial;
  Timer? _timer;
  bool _showing = false;
  bool _resumed = true;
  bool _started = false;

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await MobileAds.instance.initialize();
    loadBanner();
    _loadAppOpen();
    _loadInterstitial();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_resumed && !_showing) _showInterstitial();
    });
  }

  void loadBanner() {
    banner?.dispose();
    banner = BannerAd(
      adUnitId: bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => bannerVersion.value++,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          banner = null;
          bannerVersion.value++;
          Future.delayed(const Duration(seconds: 30), () {
            if (_started) loadBanner();
          });
        },
      ),
    )..load();
  }

  void _loadAppOpen() {
    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpen = ad,
        onAdFailedToLoad: (_) {
          Future.delayed(const Duration(seconds: 30), () {
            if (_started) _loadAppOpen();
          });
        },
      ),
    );
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) {
          Future.delayed(const Duration(seconds: 30), () {
            if (_started) _loadInterstitial();
          });
        },
      ),
    );
  }

  void _showAppOpen() {
    final ad = _appOpen;
    if (ad == null || _showing || !_resumed) return;
    _appOpen = null;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _showing = false;
        _loadAppOpen();
      },
    );
    ad.show();
  }

  void _showInterstitial() {
    final ad = _interstitial;
    if (ad == null || _showing || !_resumed) return;
    _interstitial = null;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _showing = false;
        _loadInterstitial();
      },
    );
    ad.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumed = true;
      _showAppOpen();
    } else {
      _resumed = false;
    }
  }

  Widget bannerSlot() {
    return ValueListenableBuilder<int>(
      valueListenable: bannerVersion,
      builder: (context, version, child) => SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: banner == null ? 0 : banner!.size.height.toDouble(),
          child: banner == null
              ? const SizedBox.shrink()
              : Center(child: AdWidget(ad: banner!)),
        ),
      ),
    );
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    banner?.dispose();
    _appOpen?.dispose();
    _interstitial?.dispose();
  }
}
