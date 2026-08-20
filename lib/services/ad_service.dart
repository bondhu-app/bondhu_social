import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// ============================================================
/// BONDHU SOCIAL - ADMOB AD SERVICE
/// ============================================================
///
/// এই Service-এর মধ্যে রাখা হয়েছে:
///
/// 1. Banner Ad
/// 2. App Open Ad
/// 3. Interstitial Ad
/// 4. Rewarded Ad - 1
/// 5. Rewarded Ad - 2
/// 6. Native Advanced Ad
///
/// AdMob থেকে দেওয়া তোমার Ad Unit ID-গুলো এখানে ব্যবহার করা হয়েছে.
///
/// IMPORTANT:
/// Release করার আগে অবশ্যই AdMob Console-এ App ID এবং
/// AndroidManifest.xml-এর App ID ঠিকভাবে দেওয়া থাকতে হবে.
/// ============================================================

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // ============================================================
  // ADMOB AD UNIT IDS
  // ============================================================

  /// Banner
  static const String bannerAdUnitId =
      'ca-app-pub-9879411172250653/9787792421';

  /// App Open
  static const String appOpenAdUnitId =
      'ca-app-pub-9879411172250653/2660111440';

  /// Interstitial
  static const String interstitialAdUnitId =
      'ca-app-pub-9879411172250653/2152166362';

  /// Rewarded 1
  static const String rewardedAdUnitId1 =
      'ca-app-pub-9879411172250653/1960594674';

  /// Rewarded 2
  static const String rewardedAdUnitId2 =
      'ca-app-pub-9879411172250653/1769022980';

  /// Native Advanced
  static const String nativeAdUnitId =
      'ca-app-pub-9879411172250653/6507128160';

  // ============================================================
  // INTERNAL VARIABLES
  // ============================================================

  BannerAd? _bannerAd;

  InterstitialAd? _interstitialAd;

  AppOpenAd? _appOpenAd;

  RewardedAd? _rewardedAd1;

  RewardedAd? _rewardedAd2;

  NativeAd? _nativeAd;

  bool _bannerLoaded = false;

  bool _interstitialLoaded = false;

  bool _appOpenLoaded = false;

  bool _rewarded1Loaded = false;

  bool _rewarded2Loaded = false;

  bool _nativeLoaded = false;

  bool _isShowingAppOpen = false;

  bool _isShowingInterstitial = false;

  bool _isShowingRewarded1 = false;

  bool _isShowingRewarded2 = false;

  // ============================================================
  // INITIALIZE ADMOB
  // ============================================================

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint(
        'AdMob initialization error: $e',
      );
    }
  }

  // ============================================================
  // PRELOAD ALL ADS
  // ============================================================
  ///
  /// main.dart থেকে:
  ///
  /// AdService.instance.preloadAds();
  ///
  /// ব্যবহার করা যাবে।
  ///
  // ============================================================

  void preloadAds() {
    loadBannerAd();
    loadInterstitialAd();
    loadAppOpenAd();
    loadRewardedAd1();
    loadRewardedAd2();
    loadNativeAd();
  }

  // ============================================================
  // BANNER AD
  // ============================================================

  void loadBannerAd() {
    _bannerAd?.dispose();

    _bannerLoaded = false;

    final banner = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerLoaded = true;

          debugPrint(
            'Banner Ad loaded successfully.',
          );
        },
        onAdFailedToLoad: (ad, error) {
          _bannerLoaded = false;

          ad.dispose();

          _bannerAd = null;

          debugPrint(
            'Banner Ad failed: $error',
          );
        },
      ),
    );

    _bannerAd = banner;

    banner.load();
  }

  // ============================================================
  // GET BANNER WIDGET
  // ============================================================

  Widget bannerWidget({
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(
      vertical: 8,
    ),
  }) {
    if (_bannerAd == null || !_bannerLoaded) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(
          ad: _bannerAd!,
        ),
      ),
    );
  }

  // ============================================================
  // GET BANNER AD
  // ============================================================

  BannerAd? get bannerAd {
    return _bannerAd;
  }

  // ============================================================
  // INTERSTITIAL AD
  // ============================================================

  void loadInterstitialAd() {
    _interstitialAd?.dispose();

    _interstitialAd = null;

    _interstitialLoaded = false;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;

          _interstitialLoaded = true;

          debugPrint(
            'Interstitial Ad loaded successfully.',
          );

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingInterstitial = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              _isShowingInterstitial = false;

              ad.dispose();

              _interstitialAd = null;

              _interstitialLoaded = false;

              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              _isShowingInterstitial = false;

              ad.dispose();

              _interstitialAd = null;

              _interstitialLoaded = false;

              debugPrint(
                'Interstitial show error: $error',
              );

              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;

          _interstitialLoaded = false;

          debugPrint(
            'Interstitial Ad failed: $error',
          );

          Future.delayed(
            const Duration(seconds: 10),
            () {
              loadInterstitialAd();
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW INTERSTITIAL
  // ============================================================

  Future<void> showInterstitialAd() async {
    if (_isShowingInterstitial) {
      return;
    }

    final ad = _interstitialAd;

    if (ad == null || !_interstitialLoaded) {
      loadInterstitialAd();
      return;
    }

    _interstitialAd = null;

    _interstitialLoaded = false;

    try {
      await ad.show();
    } catch (e) {
      debugPrint(
        'Interstitial show exception: $e',
      );

      ad.dispose();

      loadInterstitialAd();
    }
  }

  // ============================================================
  // APP OPEN AD
  // ============================================================

  void loadAppOpenAd() {
    if (_appOpenLoaded) {
      return;
    }

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;

          _appOpenLoaded = true;

          debugPrint(
            'App Open Ad loaded successfully.',
          );

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingAppOpen = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              _isShowingAppOpen = false;

              ad.dispose();

              _appOpenAd = null;

              _appOpenLoaded = false;

              loadAppOpenAd();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              _isShowingAppOpen = false;

              ad.dispose();

              _appOpenAd = null;

              _appOpenLoaded = false;

              debugPrint(
                'App Open show error: $error',
              );

              loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;

          _appOpenLoaded = false;

          debugPrint(
            'App Open Ad failed: $error',
          );

          Future.delayed(
            const Duration(seconds: 10),
            () {
              loadAppOpenAd();
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW APP OPEN AD
  // ============================================================

  Future<void> showAppOpenAd() async {
    if (_isShowingAppOpen) {
      return;
    }

    final ad = _appOpenAd;

    if (ad == null || !_appOpenLoaded) {
      loadAppOpenAd();
      return;
    }

    _appOpenAd = null;

    _appOpenLoaded = false;

    try {
      await ad.show();
    } catch (e) {
      debugPrint(
        'App Open show exception: $e',
      );

      ad.dispose();

      loadAppOpenAd();
    }
  }

  // ============================================================
  // REWARDED AD 1
  // ============================================================

  void loadRewardedAd1() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId1,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd1 = ad;

          _rewarded1Loaded = true;

          debugPrint(
            'Rewarded Ad 1 loaded successfully.',
          );

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingRewarded1 = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              _isShowingRewarded1 = false;

              ad.dispose();

              _rewardedAd1 = null;

              _rewarded1Loaded = false;

              loadRewardedAd1();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              _isShowingRewarded1 = false;

              ad.dispose();

              _rewardedAd1 = null;

              _rewarded1Loaded = false;

              debugPrint(
                'Rewarded Ad 1 show error: $error',
              );

              loadRewardedAd1();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd1 = null;

          _rewarded1Loaded = false;

          debugPrint(
            'Rewarded Ad 1 failed: $error',
          );

          Future.delayed(
            const Duration(seconds: 10),
            () {
              loadRewardedAd1();
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW REWARDED AD 1
  // ============================================================

  Future<bool> showRewardedAd1({
    required VoidCallback onReward,
  }) async {
    if (_isShowingRewarded1) {
      return false;
    }

    final ad = _rewardedAd1;

    if (ad == null || !_rewarded1Loaded) {
      loadRewardedAd1();

      return false;
    }

    _rewardedAd1 = null;

    _rewarded1Loaded = false;

    bool rewardReceived = false;

    try {
      ad.show(
        onUserEarnedReward: (
          AdWithoutView ad,
          RewardItem reward,
        ) {
          rewardReceived = true;

          onReward();
        },
      );

      return true;
    } catch (e) {
      debugPrint(
        'Rewarded Ad 1 exception: $e',
      );

      ad.dispose();

      loadRewardedAd1();

      return false;
    }
  }

  // ============================================================
  // REWARDED AD 2
  // ============================================================

  void loadRewardedAd2() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId2,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd2 = ad;

          _rewarded2Loaded = true;

          debugPrint(
            'Rewarded Ad 2 loaded successfully.',
          );

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingRewarded2 = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              _isShowingRewarded2 = false;

              ad.dispose();

              _rewardedAd2 = null;

              _rewarded2Loaded = false;

              loadRewardedAd2();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              _isShowingRewarded2 = false;

              ad.dispose();

              _rewardedAd2 = null;

              _rewarded2Loaded = false;

              debugPrint(
                'Rewarded Ad 2 show error: $error',
              );

              loadRewardedAd2();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd2 = null;

          _rewarded2Loaded = false;

          debugPrint(
            'Rewarded Ad 2 failed: $error',
          );

          Future.delayed(
            const Duration(seconds: 10),
            () {
              loadRewardedAd2();
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW REWARDED AD 2
  // ============================================================

  Future<bool> showRewardedAd2({
    required VoidCallback onReward,
  }) async {
    if (_isShowingRewarded2) {
      return false;
    }

    final ad = _rewardedAd2;

    if (ad == null || !_rewarded2Loaded) {
      loadRewardedAd2();

      return false;
    }

    _rewardedAd2 = null;

    _rewarded2Loaded = false;

    try {
      ad.show(
        onUserEarnedReward: (
          AdWithoutView ad,
          RewardItem reward,
        ) {
          onReward();
        },
      );

      return true;
    } catch (e) {
      debugPrint(
        'Rewarded Ad 2 exception: $e',
      );

      ad.dispose();

      loadRewardedAd2();

      return false;
    }
  }

  // ============================================================
  // NATIVE ADVANCED AD
  // ============================================================

  void loadNativeAd() {
    _nativeAd?.dispose();

    _nativeAd = null;

    _nativeLoaded = false;

    final nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeLoaded = true;

          debugPrint(
            'Native Ad loaded successfully.',
          );
        },
        onAdFailedToLoad: (ad, error) {
          _nativeLoaded = false;

          ad.dispose();

          _nativeAd = null;

          debugPrint(
            'Native Ad failed: $error',
          );

          Future.delayed(
            const Duration(seconds: 10),
            () {
              loadNativeAd();
            },
          );
        },
      ),

      /// এখানে Flutter-এর জন্য কোনো custom native
      /// factory প্রয়োজন না হলে null রাখা হয়েছে।
      ///
      /// Android Native Advanced Ad-এর জন্য যদি custom
      /// NativeAdFactory ব্যবহার করা হয়, তাহলে পরে সেটি
      /// আলাদা Android code দিয়ে সেটআপ করতে হবে।
      factoryId: 'listTile',
    );

    _nativeAd = nativeAd;

    nativeAd.load();
  }

  // ============================================================
  // NATIVE AD WIDGET
  // ============================================================

  Widget nativeAdWidget({
    double height = 120,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(
      vertical: 8,
    ),
  }) {
    if (_nativeAd == null || !_nativeLoaded) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: AdWidget(
          ad: _nativeAd!,
        ),
      ),
    );
  }

  // ============================================================
  // NATIVE AD GETTER
  // ============================================================

  NativeAd? get nativeAd {
    return _nativeAd;
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool get isBannerLoaded {
    return _bannerLoaded;
  }

  bool get isInterstitialLoaded {
    return _interstitialLoaded;
  }

  bool get isAppOpenLoaded {
    return _appOpenLoaded;
  }

  bool get isRewarded1Loaded {
    return _rewarded1Loaded;
  }

  bool get isRewarded2Loaded {
    return _rewarded2Loaded;
  }

  bool get isNativeLoaded {
    return _nativeLoaded;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _bannerAd?.dispose();

    _interstitialAd?.dispose();

    _appOpenAd?.dispose();

    _rewardedAd1?.dispose();

    _rewardedAd2?.dispose();

    _nativeAd?.dispose();

    _bannerAd = null;

    _interstitialAd = null;

    _appOpenAd = null;

    _rewardedAd1 = null;

    _rewardedAd2 = null;

    _nativeAd = null;

    _bannerLoaded = false;

    _interstitialLoaded = false;

    _appOpenLoaded = false;

    _rewarded1Loaded = false;

    _rewarded2Loaded = false;

    _nativeLoaded = false;
  }
}
