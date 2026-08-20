import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // ============================================================
  // ADMOB AD UNIT IDs
  // ============================================================

  // Banner
  static const String bannerAdUnitId =
      'ca-app-pub-9879411172250653/9787792421';

  // App Open
  static const String appOpenAdUnitId =
      'ca-app-pub-9879411172250653/2660111440';

  // Interstitial
  static const String interstitialAdUnitId =
      'ca-app-pub-9879411172250653/2152166362';

  // Rewarded
  static const String rewardedAdUnitId =
      'ca-app-pub-9879411172250653/1960594674';

  // Rewarded 2
  static const String rewardedAdUnitId2 =
      'ca-app-pub-9879411172250653/1769022980';

  // Native Advanced
  static const String nativeAdUnitId =
      'ca-app-pub-9879411172250653/6507128160';

  // ============================================================
  // STATE
  // ============================================================

  InterstitialAd? _interstitialAd;

  RewardedAd? _rewardedAd;

  AppOpenAd? _appOpenAd;

  bool _isLoadingInterstitial = false;

  bool _isLoadingRewarded = false;

  bool _isLoadingAppOpen = false;

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
    loadInterstitialAd();
    loadRewardedAd();
    loadAppOpenAd();
  }

  // ============================================================
  // INTERSTITIAL
  // ============================================================

  void loadInterstitialAd() {
    if (_isLoadingInterstitial) {
      return;
    }

    if (_interstitialAd != null) {
      return;
    }

    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoadingInterstitial = false;

          _interstitialAd = ad;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();

              _interstitialAd = null;

              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              ad.dispose();

              _interstitialAd = null;

              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoadingInterstitial = false;

          _interstitialAd = null;

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

  Future<void> showInterstitialAd({
    VoidCallback? onAdDismissed,
  }) async {
    final ad = _interstitialAd;

    if (ad == null) {
      loadInterstitialAd();

      onAdDismissed?.call();

      return;
    }

    _interstitialAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();

        loadInterstitialAd();

        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        loadInterstitialAd();

        onAdDismissed?.call();
      },
    );

    await ad.show();
  }

  // ============================================================
  // REWARDED
  // ============================================================

  void loadRewardedAd() {
    if (_isLoadingRewarded) {
      return;
    }

    if (_rewardedAd != null) {
      return;
    }

    _isLoadingRewarded = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _isLoadingRewarded = false;

          _rewardedAd = ad;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent:
                (ad) {
              ad.dispose();

              _rewardedAd = null;

              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              ad.dispose();

              _rewardedAd = null;

              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad:
            (LoadAdError error) {
          _isLoadingRewarded = false;

          _rewardedAd = null;

          debugPrint(
            'Rewarded Ad failed: $error',
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW REWARDED
  // ============================================================

  Future<void> showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onAdUnavailable,
  }) async {
    final ad = _rewardedAd;

    if (ad == null) {
      loadRewardedAd();

      onAdUnavailable?.call();

      return;
    }

    _rewardedAd = null;

    bool rewardEarned = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent:
          (ad) {
        ad.dispose();

        loadRewardedAd();

        if (!rewardEarned) {
          onAdUnavailable?.call();
        }
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        loadRewardedAd();

        onAdUnavailable?.call();
      },
    );

    await ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) {
        rewardEarned = true;

        onRewarded();
      },
    );
  }

  // ============================================================
  // APP OPEN
  // ============================================================

  void loadAppOpenAd() {
    if (_isLoadingAppOpen) {
      return;
    }

    if (_appOpenAd != null) {
      return;
    }

    _isLoadingAppOpen = true;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback:
          AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _isLoadingAppOpen = false;

          _appOpenAd = ad;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent:
                (ad) {
              ad.dispose();

              _appOpenAd = null;

              loadAppOpenAd();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              ad.dispose();

              _appOpenAd = null;

              loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad:
            (LoadAdError error) {
          _isLoadingAppOpen = false;

          _appOpenAd = null;

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
    final ad = _appOpenAd;

    if (ad == null) {
      loadAppOpenAd();

      return;
    }

    _appOpenAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent:
          (ad) {
        ad.dispose();

        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        loadAppOpenAd();
      },
    );

    await ad.show();
  }

  // ============================================================
  // BANNER
  // ============================================================

  BannerAd createBannerAd({
    required VoidCallback onLoaded,
    required Function(LoadAdError error)
        onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          onFailed(error);
        },
      ),
    );
  }

  // ============================================================
  // NATIVE ADVANCED
  // ============================================================

  NativeAd createNativeAd({
    required String factoryId,
    required VoidCallback onLoaded,
    required Function(LoadAdError error)
        onFailed,
  }) {
    final nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          onFailed(error);
        },
      ),
    );

    nativeAd.load();

    return nativeAd;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _interstitialAd?.dispose();

    _rewardedAd?.dispose();

    _appOpenAd?.dispose();

    _interstitialAd = null;

    _rewardedAd = null;

    _appOpenAd = null;
  }

  // ============================================================
  // DEBUG INFORMATION
  // ============================================================

  bool get isInterstitialReady =>
      _interstitialAd != null;

  bool get isRewardedReady =>
      _rewardedAd != null;

  bool get isAppOpenReady =>
      _appOpenAd != null;

  // ============================================================
  // PLATFORM CHECK
  // ============================================================

  bool get isAndroid =>
      !kIsWeb && Platform.isAndroid;

  bool get isIOS =>
      !kIsWeb && Platform.isIOS;
}
