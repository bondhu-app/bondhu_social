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

  static const String rewardedAdUnitId1 =
      'ca-app-pub-9879411172250653/1960594674';

  static const String rewardedAdUnitId2 =
      'ca-app-pub-9879411172250653/1769022980';

  static const String nativeAdUnitId =
      'ca-app-pub-9879411172250653/6507128160';

  // ============================================================
  // INITIALIZE
  // ============================================================

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await MobileAds.instance.initialize();

      _initialized = true;

      if (kDebugMode) {
        debugPrint('Google Mobile Ads initialized.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Google Mobile Ads initialization error: $e',
        );
      }
    }
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
  // BANNER AD
  // ============================================================

  BannerAd createBannerAd({
    VoidCallback? onLoaded,
    VoidCallback? onFailed,
  }) {
    late final BannerAd bannerAd;

    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            debugPrint('Banner Ad loaded.');
          }

          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (kDebugMode) {
            debugPrint(
              'Banner Ad failed: ${error.message}',
            );
          }

          onFailed?.call();
        },
      ),
    );

    bannerAd.load();

    return bannerAd;
  }

  // ============================================================
  // INTERSTITIAL AD
  // ============================================================

  InterstitialAd? _interstitialAd;
  bool _loadingInterstitial = false;

  void loadInterstitialAd() {
    if (_loadingInterstitial ||
        _interstitialAd != null) {
      return;
    }

    _loadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitialAd = ad;

          if (kDebugMode) {
            debugPrint(
              'Interstitial Ad loaded.',
            );
          }

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

              if (kDebugMode) {
                debugPrint(
                  'Interstitial show failed: '
                  '${error.message}',
                );
              }

              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          _interstitialAd = null;

          if (kDebugMode) {
            debugPrint(
              'Interstitial load failed: '
              '${error.message}',
            );
          }
        },
      ),
    );
  }

  bool get isInterstitialReady =>
      _interstitialAd != null;

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

        if (kDebugMode) {
          debugPrint(
            'Interstitial show error: '
            '${error.message}',
          );
        }

        onFinished?.call();
      },
    );

    ad.show();
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  RewardedAd? _rewardedAd;
  bool _loadingRewarded = false;

  void loadRewardedAd() {
    if (_loadingRewarded ||
        _rewardedAd != null) {
      return;
    }

    _loadingRewarded = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId1,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewardedAd = ad;

          if (kDebugMode) {
            debugPrint(
              'Rewarded Ad loaded.',
            );
          }

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

              if (kDebugMode) {
                debugPrint(
                  'Rewarded show failed: '
                  '${error.message}',
                );
              }

              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          _rewardedAd = null;

          if (kDebugMode) {
            debugPrint(
              'Rewarded load failed: '
              '${error.message}',
            );
          }
        },
      ),
    );
  }

  bool get isRewardedReady =>
      _rewardedAd != null;

  void showRewardedAd({
    required void Function(
      RewardItem reward,
    ) onReward,
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
      onAdDismissedFullScreenContent:
          (ad) {
        ad.dispose();

        loadRewardedAd();

        onFinished?.call();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        loadRewardedAd();

        if (kDebugMode) {
          debugPrint(
            'Rewarded show error: '
            '${error.message}',
          );
        }

        onFinished?.call();
      },
    );

    ad.show(
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        onReward(reward);
      },
    );
  }

  // ============================================================
  // SECOND REWARDED AD
  // ============================================================

  RewardedAd? _rewardedAd2;
  bool _loadingRewarded2 = false;

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

          if (kDebugMode) {
            debugPrint(
              'Rewarded Ad 2 loaded.',
            );
          }

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

          if (kDebugMode) {
            debugPrint(
              'Rewarded Ad 2 failed: '
              '${error.message}',
            );
          }
        },
      ),
    );
  }

  bool get isRewarded2Ready =>
      _rewardedAd2 != null;

  void showRewardedAd2({
    required void Function(
      RewardItem reward,
    ) onReward,
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
      onAdDismissedFullScreenContent:
          (ad) {
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
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        onReward(reward);
      },
    );
  }

  // ============================================================
  // APP OPEN AD
  // ============================================================

  AppOpenAd? _appOpenAd;
  bool _loadingAppOpen = false;
  bool _showingAppOpen = false;

  DateTime? _appOpenLoadedAt;

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
          _appOpenLoadedAt =
              DateTime.now();

          if (kDebugMode) {
            debugPrint(
              'App Open Ad loaded.',
            );
          }

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent:
                (ad) {
              _showingAppOpen = false;

              ad.dispose();

              _appOpenAd = null;
              _appOpenLoadedAt = null;

              loadAppOpenAd();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              _showingAppOpen = false;

              ad.dispose();

              _appOpenAd = null;
              _appOpenLoadedAt = null;

              loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loadingAppOpen = false;
          _appOpenAd = null;

          if (kDebugMode) {
            debugPrint(
              'App Open Ad failed: '
              '${error.message}',
            );
          }
        },
      ),
    );
  }

  bool get isAppOpenReady =>
      _appOpenAd != null;

  void showAppOpenAdIfAvailable() {
    final ad = _appOpenAd;

    if (ad == null ||
        _showingAppOpen) {
      loadAppOpenAd();
      return;
    }

    // App Open Ad সর্বোচ্চ ৪ ঘণ্টা ব্যবহারযোগ্য।
    if (_appOpenLoadedAt != null) {
      final age = DateTime.now()
          .difference(_appOpenLoadedAt!);

      if (age.inHours >= 4) {
        ad.dispose();

        _appOpenAd = null;
        _appOpenLoadedAt = null;

        loadAppOpenAd();

        return;
      }
    }

    _showingAppOpen = true;

    _appOpenAd = null;

    ad.show();
  }

  // ============================================================
  // NATIVE ADVANCED AD
  // ============================================================

  NativeAd createNativeAd({
    required NativeAdListener listener,
  }) {
    final nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      listener: listener,
      nativeTemplateStyle:
          NativeTemplateStyle(
        templateType:
            TemplateType.medium,
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
    _interstitialAd = null;

    _rewardedAd?.dispose();
    _rewardedAd = null;

    _rewardedAd2?.dispose();
    _rewardedAd2 = null;

    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
