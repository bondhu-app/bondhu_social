import 'dart:io';

import 'package:flutter/foundation.dart';
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
  // ADS
  // ============================================================

  BannerAd? _bannerAd;
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedAd? _rewardedAd2;
  NativeAd? _nativeAd;

  bool _isAppOpenLoading = false;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;
  bool _isRewarded2Loading = false;
  bool _isNativeLoading = false;

  bool _isInterstitialShowing = false;
  bool _isRewardedShowing = false;
  bool _isRewarded2Showing = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    await MobileAds.instance.initialize();

    loadAppOpenAd();
    loadInterstitialAd();
    loadRewardedAd();
    loadRewardedAd2();
  }

  // ============================================================
  // BANNER
  // ============================================================

  BannerAd createBannerAd({
    required VoidCallback onLoaded,
    VoidCallback? onFailed,
  }) {
    final banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (onFailed != null) {
            onFailed();
          }
        },
      ),
    );

    _bannerAd = banner;

    banner.load();

    return banner;
  }

  BannerAd? get bannerAd => _bannerAd;

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ============================================================
  // APP OPEN AD
  // ============================================================

  void loadAppOpenAd() {
    if (_isAppOpenLoading || _appOpenAd != null) {
      return;
    }

    _isAppOpenLoading = true;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isAppOpenLoading = false;
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAppOpenLoading = false;
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
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadAppOpenAd();
      },
    );

    ad.show();
  }

  // ============================================================
  // INTERSTITIAL
  // ============================================================

  void loadInterstitialAd() {
    if (_isInterstitialLoading ||
        _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isInterstitialLoading = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialLoading = false;
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
    _isInterstitialShowing = true;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isInterstitialShowing = false;
        ad.dispose();
        loadInterstitialAd();

        onFinished?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isInterstitialShowing = false;
        ad.dispose();
        loadInterstitialAd();

        onFinished?.call();
      },
    );

    ad.show();
  }

  bool get isInterstitialShowing =>
      _isInterstitialShowing;

  // ============================================================
  // REWARDED AD
  // ============================================================

  void loadRewardedAd() {
    if (_isRewardedLoading ||
        _rewardedAd != null) {
      return;
    }

    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewardedLoading = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedLoading = false;
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
    _isRewardedShowing = true;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isRewardedShowing = false;
        ad.dispose();
        loadRewardedAd();

        onFinished?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isRewardedShowing = false;
        ad.dispose();
        loadRewardedAd();

        onFinished?.call();
      },
    );

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) {
        onReward?.call();
      },
    );
  }

  // ============================================================
  // REWARDED AD 2
  // ============================================================

  void loadRewardedAd2() {
    if (_isRewarded2Loading ||
        _rewardedAd2 != null) {
      return;
    }

    _isRewarded2Loading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId2,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewarded2Loading = false;
          _rewardedAd2 = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewarded2Loading = false;
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
    _isRewarded2Showing = true;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isRewarded2Showing = false;
        ad.dispose();
        loadRewardedAd2();

        onFinished?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isRewarded2Showing = false;
        ad.dispose();
        loadRewardedAd2();

        onFinished?.call();
      },
    );

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) {
        onReward?.call();
      },
    );
  }

  // ============================================================
  // NATIVE AD
  // ============================================================

  NativeAd createNativeAd({
    required VoidCallback onLoaded,
    VoidCallback? onFailed,
  }) {
    final native = NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      factoryId: 'listTile',
      adListener: NativeAdListener(
        onAdLoaded: (ad) {
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (onFailed != null) {
            onFailed();
          }
        },
      ),
    );

    _nativeAd = native;

    native.load();

    return native;
  }

  NativeAd? get nativeAd => _nativeAd;

  void disposeNativeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
  }

  // ============================================================
  // PRELOAD
  // ============================================================

  void preloadAds() {
    loadAppOpenAd();
    loadInterstitialAd();
    loadRewardedAd();
    loadRewardedAd2();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _bannerAd?.dispose();
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedAd2?.dispose();
    _nativeAd?.dispose();

    _bannerAd = null;
    _appOpenAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _rewardedAd2 = null;
    _nativeAd = null;
  }
}
