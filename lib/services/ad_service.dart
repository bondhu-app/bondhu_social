import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // ============================================================
  // ADMOB AD UNIT IDs
  // ============================================================

  static const String bannerAdUnitId =
      'ca-app-pub-9879411172250653/9787792421';

  static const String appOpenAdUnitId =
      'ca-app-pub-9879411172250653/2660111440';

  static const String interstitialAdUnitId =
      'ca-app-pub-9879411172250653/2152166362';

  static const String rewardedAdUnitId =
      'ca-app-pub-9879411172250653/1960594674';

  static const String rewardedAdUnitId2 =
      'ca-app-pub-9879411172250653/1769022980';

  static const String nativeAdUnitId =
      'ca-app-pub-9879411172250653/6507128160';

  // ============================================================
  // AD OBJECTS
  // ============================================================

  BannerAd? _bannerAd;
  NativeAd? _nativeAd;

  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;

  RewardedAd? _rewardedAd;
  RewardedAd? _rewardedAd2;

  // ============================================================
  // LOADING FLAGS
  // ============================================================

  bool _loadingBanner = false;
  bool _loadingNative = false;
  bool _loadingAppOpen = false;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  bool _loadingRewarded2 = false;

  // ============================================================
  // READY GETTERS
  // ============================================================

  bool get isBannerReady => _bannerAd != null;

  bool get isNativeReady => _nativeAd != null;

  bool get isAppOpenReady => _appOpenAd != null;

  bool get isInterstitialReady =>
      _interstitialAd != null;

  bool get isRewardedReady =>
      _rewardedAd != null;

  bool get isRewarded2Ready =>
      _rewardedAd2 != null;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    await MobileAds.instance.initialize();

    preloadAds();
  }

  // ============================================================
  // PRELOAD ALL ADS
  // ============================================================

  void preloadAds() {
    loadBannerAd();
    loadNativeAd();
    loadAppOpenAd();
    loadInterstitialAd();
    loadRewardedAd();
    loadRewardedAd2();
  }

  // ============================================================
  // BANNER AD
  // ============================================================

  void loadBannerAd({
    VoidCallback? onLoaded,
    VoidCallback? onFailed,
  }) {
    if (_loadingBanner || _bannerAd != null) {
      return;
    }

    _loadingBanner = true;

    final ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _loadingBanner = false;
          _bannerAd = ad as BannerAd;

          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          _loadingBanner = false;

          ad.dispose();

          _bannerAd = null;

          onFailed?.call();
        },
      ),
    );

    ad.load();
  }

  BannerAd? get bannerAd => _bannerAd;

  Widget bannerAdWidget() {
    final ad = _bannerAd;

    if (ad == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }

  // ============================================================
  // NATIVE ADVANCED AD
  // ============================================================

  void loadNativeAd({
    VoidCallback? onLoaded,
    VoidCallback? onFailed,
  }) {
    if (_loadingNative || _nativeAd != null) {
      return;
    }

    _loadingNative = true;

    final ad = NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      factoryId: 'listTile',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _loadingNative = false;
          _nativeAd = ad as NativeAd;

          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          _loadingNative = false;

          ad.dispose();

          _nativeAd = null;

          onFailed?.call();
        },
      ),
    );

    _nativeAd = ad;

    ad.load();
  }

  NativeAd? get nativeAd => _nativeAd;

  Widget nativeAdWidget() {
    final ad = _nativeAd;

    if (ad == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 120,
      child: AdWidget(ad: ad),
    );
  }

  // ============================================================
  // APP OPEN AD
  // ============================================================

  void loadAppOpenAd() {
    if (_loadingAppOpen || _appOpenAd != null) {
      return;
    }

    _loadingAppOpen = true;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingAppOpen = false;
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingAppOpen = false;
          _appOpenAd = null;
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    final ad = _appOpenAd;

    if (ad == null) {
      loadAppOpenAd();
      return;
    }

    _appOpenAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();
        loadAppOpenAd();
      },
    );

    ad.show();
  }

  // ============================================================
  // INTERSTITIAL AD
  // ============================================================

  void loadInterstitialAd() {
    if (_loadingInterstitial ||
        _interstitialAd != null) {
      return;
    }

    _loadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback:
          InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd({
    VoidCallback? onFinished,
  }) {
    final ad = _interstitialAd;

    if (ad == null) {
      loadInterstitialAd();
      onFinished?.call();
      return;
    }

    _interstitialAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd();
        onFinished?.call();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();
        loadInterstitialAd();
        onFinished?.call();
      },
    );

    ad.show();
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  void loadRewardedAd() {
    if (_loadingRewarded ||
        _rewardedAd != null) {
      return;
    }

    _loadingRewarded = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  void showRewardedAd({
    VoidCallback? onReward,
    VoidCallback? onFinished,
  }) {
    final ad = _rewardedAd;

    if (ad == null) {
      loadRewardedAd();
      onFinished?.call();
      return;
    }

    _rewardedAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
        onFinished?.call();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();
        loadRewardedAd();
        onFinished?.call();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        onReward?.call();
      },
    );
  }

  // ============================================================
  // REWARDED AD 2
  // ============================================================

  void loadRewardedAd2() {
    if (_loadingRewarded2 ||
        _rewardedAd2 != null) {
      return;
    }

    _loadingRewarded2 = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId2,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded2 = false;
          _rewardedAd2 = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded2 = false;
          _rewardedAd2 = null;
        },
      ),
    );
  }

  void showRewardedAd2({
    VoidCallback? onReward,
    VoidCallback? onFinished,
  }) {
    final ad = _rewardedAd2;

    if (ad == null) {
      loadRewardedAd2();
      onFinished?.call();
      return;
    }

    _rewardedAd2 = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd2();
        onFinished?.call();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();
        loadRewardedAd2();
        onFinished?.call();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        onReward?.call();
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedAd2?.dispose();

    _bannerAd = null;
    _nativeAd = null;
    _appOpenAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _rewardedAd2 = null;
  }
}
