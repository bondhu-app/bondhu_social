import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // ============================================================
  // ADMOB IDs
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

  InterstitialAd? _interstitialAd;

  RewardedAd? _rewardedAd;

  RewardedAd? _rewardedAd2;

  AppOpenAd? _appOpenAd;

  bool _loadingInterstitial = false;

  bool _loadingRewarded = false;

  bool _loadingRewarded2 = false;

  bool _loadingAppOpen = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    await MobileAds.instance.initialize();

    preloadAds();
  }

  // ============================================================
  // PRELOAD
  // ============================================================

  void preloadAds() {
    loadInterstitialAd();
    loadRewardedAd();
    loadRewardedAd2();
    loadAppOpenAd();
  }

  // ============================================================
  // INTERSTITIAL
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

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent:
                (ad) {
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
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;

          _interstitialAd = null;

          debugPrint(
            'Interstitial failed: $error',
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
      onAdDismissedFullScreenContent:
          (ad) {
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
  // REWARDED AD 1
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
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;

          _rewardedAd = null;

          debugPrint(
            'Rewarded 1 failed: $error',
          );
        },
      ),
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

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent:
                (ad) {
              ad.dispose();

              _rewardedAd2 = null;

              loadRewardedAd2();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              ad.dispose();

              _rewardedAd2 = null;

              loadRewardedAd2();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded2 = false;

          _rewardedAd2 = null;

          debugPrint(
            'Rewarded 2 failed: $error',
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW REWARDED
  // ============================================================

  Future<void> showRewardedAd({
    VoidCallback? onReward,
    VoidCallback? onAdUnavailable,
  }) async {
    final ad = _rewardedAd;

    if (ad == null) {
      loadRewardedAd();

      onAdUnavailable?.call();

      return;
    }

    _rewardedAd = null;

    bool earned = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent:
          (ad) {
        ad.dispose();

        loadRewardedAd();

        if (!earned) {
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
          (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        earned = true;

        onReward?.call();
      },
    );
  }

  // ============================================================
  // SHOW REWARDED AD 2
  // ============================================================

  Future<void> showRewardedAd2({
    VoidCallback? onReward,
    VoidCallback? onAdUnavailable,
  }) async {
    final ad = _rewardedAd2;

    if (ad == null) {
      loadRewardedAd2();

      onAdUnavailable?.call();

      return;
    }

    _rewardedAd2 = null;

    bool earned = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent:
          (ad) {
        ad.dispose();

        loadRewardedAd2();

        if (!earned) {
          onAdUnavailable?.call();
        }
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        loadRewardedAd2();

        onAdUnavailable?.call();
      },
    );

    await ad.show(
      onUserEarnedReward:
          (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        earned = true;

        onReward?.call();
      },
    );
  }

  // ============================================================
  // APP OPEN AD
  // ============================================================

  void loadAppOpenAd() {
    if (_loadingAppOpen ||
        _appOpenAd != null) {
      return;
    }

    _loadingAppOpen = true;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback:
          AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingAppOpen = false;

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
        onAdFailedToLoad: (error) {
          _loadingAppOpen = false;

          _appOpenAd = null;

          debugPrint(
            'App Open failed: $error',
          );
        },
      ),
    );
  }

  // ============================================================
  // APP OPEN - COMPATIBLE METHOD
  // ============================================================

  Future<void> showAppOpenAdIfAvailable() async {
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
  // NATIVE AD
  //
  // IMPORTANT:
  // google_mobile_ads 7.x NativeAd does not
  // use the old constructor style.
  // ============================================================

  NativeAd createNativeAd({
    required String factoryId,
    required VoidCallback onLoaded,
    required Function(LoadAdError error)
        onFailed,
  }) {
    final ad = NativeAd(
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

    ad.load();

    return ad;
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool get isInterstitialReady =>
      _interstitialAd != null;

  bool get isRewardedReady =>
      _rewardedAd != null;

  bool get isRewarded2Ready =>
      _rewardedAd2 != null;

  bool get isAppOpenReady =>
      _appOpenAd != null;

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _interstitialAd?.dispose();

    _rewardedAd?.dispose();

    _rewardedAd2?.dispose();

    _appOpenAd?.dispose();

    _interstitialAd = null;

    _rewardedAd = null;

    _rewardedAd2 = null;

    _appOpenAd = null;
  }
}
