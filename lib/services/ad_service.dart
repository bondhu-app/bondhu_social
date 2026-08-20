import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // ============================================================
  // ADMOB AD UNIT IDS
  // ============================================================

  static const String bannerAdUnitId =
      'ca-app-pub-9879411172250653/9787792421';

  static const String appOpenAdUnitId =
      'ca-app-pub-9879411172250653/2660111440';

  static const String interstitialAdUnitId =
      'ca-app-pub-9879411172250653/2152166362';

  static const String rewardedAdUnitId1 =
      'ca-app-pub-9879411172250653/1960594674';

  static const String rewardedAdUnitId2 =
      'ca-app-pub-9879411172250653/1769022980';

  static const String nativeAdUnitId =
      'ca-app-pub-9879411172250653/6507128160';

  // ============================================================
  // ADS
  // ============================================================

  BannerAd? _bannerAd;

  InterstitialAd? _interstitialAd;

  AppOpenAd? _appOpenAd;

  RewardedAd? _rewardedAd1;

  RewardedAd? _rewardedAd2;

  // ============================================================
  // STATUS
  // ============================================================

  bool _bannerLoaded = false;

  bool _interstitialLoaded = false;

  bool _appOpenLoaded = false;

  bool _rewarded1Loaded = false;

  bool _rewarded2Loaded = false;

  bool _isShowingInterstitial = false;

  bool _isShowingAppOpen = false;

  bool _isShowingRewarded1 = false;

  bool _isShowingRewarded2 = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();

      debugPrint('AdMob initialized successfully.');
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
  }

  // ============================================================
  // PRELOAD ALL ADS
  // ============================================================

  void preloadAds() {
    loadBannerAd();
    loadInterstitialAd();
    loadAppOpenAd();
    loadRewardedAd();
    loadRewardedAd2();
  }

  // ============================================================
  // BANNER
  // ============================================================

  void loadBannerAd() {
    _bannerAd?.dispose();

    _bannerAd = null;

    _bannerLoaded = false;

    final ad = BannerAd(
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

    _bannerAd = ad;

    ad.load();
  }

  // ============================================================
  // BANNER WIDGET
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
  // BANNER GETTER
  // ============================================================

  BannerAd? get bannerAd => _bannerAd;

  // ============================================================
  // INTERSTITIAL
  // ============================================================

  void loadInterstitialAd() {
    if (_interstitialLoaded) {
      return;
    }

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
        'Interstitial show error: $e',
      );

      ad.dispose();

      loadInterstitialAd();
    }
  }

  // ============================================================
  // APP OPEN
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
        },
      ),
    );
  }

  // ============================================================
  // SHOW APP OPEN
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
        'App Open show error: $e',
      );

      ad.dispose();

      loadAppOpenAd();
    }
  }

  // ============================================================
  // REWARDED AD 1
  // ============================================================
  ///
  /// পুরোনো HomeScreen-এ যদি:
  ///
  /// _adService.loadRewardedAd();
  ///
  /// থাকে, সেটাও কাজ করবে।
  ///
  // ============================================================

  void loadRewardedAd() {
    if (_rewarded1Loaded) {
      return;
    }

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

              loadRewardedAd();
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

              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd1 = null;

          _rewarded1Loaded = false;

          debugPrint(
            'Rewarded Ad 1 failed: $error',
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW REWARDED AD
  // ============================================================
  ///
  /// HomeScreen-এর:
  ///
  /// _adService.showRewardedAd(...)
  ///
  /// সরাসরি কাজ করবে।
  ///
  // ============================================================

  Future<bool> showRewardedAd({
    required VoidCallback onReward,
  }) async {
    if (_isShowingRewarded1) {
      return false;
    }

    final ad = _rewardedAd1;

    if (ad == null || !_rewarded1Loaded) {
      loadRewardedAd();

      return false;
    }

    _rewardedAd1 = null;

    _rewarded1Loaded = false;

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
        'Rewarded Ad show error: $e',
      );

      ad.dispose();

      loadRewardedAd();

      return false;
    }
  }

  // ============================================================
  // REWARDED AD 2
  // ============================================================

  void loadRewardedAd2() {
    if (_rewarded2Loaded) {
      return;
    }

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
        'Rewarded Ad 2 show error: $e',
      );

      ad.dispose();

      loadRewardedAd2();

      return false;
    }
  }

  // ============================================================
  // STATUS GETTERS
  // ============================================================

  bool get isBannerLoaded => _bannerLoaded;

  bool get isInterstitialLoaded =>
      _interstitialLoaded;

  bool get isAppOpenLoaded =>
      _appOpenLoaded;

  bool get isRewarded1Loaded =>
      _rewarded1Loaded;

  bool get isRewarded2Loaded =>
      _rewarded2Loaded;

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _bannerAd?.dispose();

    _interstitialAd?.dispose();

    _appOpenAd?.dispose();

    _rewardedAd1?.dispose();

    _rewardedAd2?.dispose();

    _bannerAd = null;

    _interstitialAd = null;

    _appOpenAd = null;

    _rewardedAd1 = null;

    _rewardedAd2 = null;

    _bannerLoaded = false;

    _interstitialLoaded = false;

    _appOpenLoaded = false;

    _rewarded1Loaded = false;

    _rewarded2Loaded = false;

    _isShowingInterstitial = false;

    _isShowingAppOpen = false;

    _isShowingRewarded1 = false;

    _isShowingRewarded2 = false;
  }
}
