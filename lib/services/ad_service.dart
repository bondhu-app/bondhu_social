import 'dart:async';

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
  // INTERNAL ADS
  // ============================================================

  BannerAd? _bannerAd;

  AppOpenAd? _appOpenAd;

  InterstitialAd? _interstitialAd;

  RewardedAd? _rewardedAd;

  RewardedAd? _rewardedAd2;

  NativeAd? _nativeAd;

  bool _isLoadingAppOpenAd = false;

  bool _isLoadingInterstitialAd = false;

  bool _isLoadingRewardedAd = false;

  bool _isLoadingRewardedAd2 = false;

  bool _isShowingAppOpenAd = false;

  bool _isShowingInterstitialAd = false;

  bool _isShowingRewardedAd = false;

  bool _isShowingRewardedAd2 = false;

  DateTime? _lastInterstitialShown;

  DateTime? _lastRewardedShown;

  // ============================================================
  // INITIALIZE ADMOB
  // ============================================================

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();

      preloadAds();
    } catch (e) {
      debugPrint(
        'AdMob initialize error: $e',
      );
    }
  }

  // ============================================================
  // PRELOAD ALL ADS
  // ============================================================

  void preloadAds() {
    loadBannerAd();
    loadAppOpenAd();
    loadInterstitialAd();
    loadRewardedAd();
    loadRewardedAd2();
    loadNativeAd();
  }

  // ============================================================
  // BANNER AD
  // ============================================================

  void loadBannerAd() {
    _bannerAd?.dispose();

    final ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint(
            'Banner Ad loaded successfully.',
          );
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            'Banner Ad failed: $error',
          );

          ad.dispose();

          _bannerAd = null;
        },
        onAdOpened: (ad) {
          debugPrint(
            'Banner Ad opened.',
          );
        },
        onAdClosed: (ad) {
          debugPrint(
            'Banner Ad closed.',
          );
        },
        onAdImpression: (ad) {
          debugPrint(
            'Banner Ad impression.',
          );
        },
      ),
    );

    _bannerAd = ad;

    ad.load();
  }

  // ============================================================
  // GET BANNER AD
  // ============================================================

  BannerAd? get bannerAd => _bannerAd;

  // ============================================================
  // APP OPEN AD
  // ============================================================

  void loadAppOpenAd() {
    if (_isLoadingAppOpenAd ||
        _appOpenAd != null) {
      return;
    }

    _isLoadingAppOpenAd = true;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAppOpenAd = false;

          _appOpenAd = ad;

          debugPrint(
            'App Open Ad loaded.',
          );
        },
        onAdFailedToLoad: (error) {
          _isLoadingAppOpenAd = false;

          _appOpenAd = null;

          debugPrint(
            'App Open Ad failed: $error',
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW APP OPEN AD
  // ============================================================

  void showAppOpenAd() {
    final ad = _appOpenAd;

    if (ad == null) {
      loadAppOpenAd();
      return;
    }

    if (_isShowingAppOpenAd) {
      return;
    }

    _isShowingAppOpenAd = true;

    _appOpenAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint(
          'App Open Ad showed.',
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint(
          'App Open Ad dismissed.',
        );

        _isShowingAppOpenAd = false;

        ad.dispose();

        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        debugPrint(
          'App Open Ad failed to show: $error',
        );

        _isShowingAppOpenAd = false;

        ad.dispose();

        loadAppOpenAd();
      },
      onAdImpression: (ad) {
        debugPrint(
          'App Open Ad impression.',
        );
      },
    );

    ad.show();
  }

  // ============================================================
  // INTERSTITIAL AD
  // ============================================================

  void loadInterstitialAd() {
    if (_isLoadingInterstitialAd ||
        _interstitialAd != null) {
      return;
    }

    _isLoadingInterstitialAd = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback:
          InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitialAd = false;

          _interstitialAd = ad;

          debugPrint(
            'Interstitial Ad loaded.',
          );
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitialAd = false;

          _interstitialAd = null;

          debugPrint(
            'Interstitial Ad failed: $error',
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW INTERSTITIAL AD
  // ============================================================

  void showInterstitialAd() {
    final ad = _interstitialAd;

    if (ad == null) {
      loadInterstitialAd();
      return;
    }

    if (_isShowingInterstitialAd) {
      return;
    }

    // ----------------------------------------------------------
    // Prevent showing too frequently.
    // ----------------------------------------------------------

    final now = DateTime.now();

    if (_lastInterstitialShown != null) {
      final difference =
          now.difference(
        _lastInterstitialShown!,
      );

      if (difference.inSeconds < 60) {
        return;
      }
    }

    _isShowingInterstitialAd = true;

    _interstitialAd = null;

    _lastInterstitialShown = now;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint(
          'Interstitial Ad showed.',
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint(
          'Interstitial Ad dismissed.',
        );

        _isShowingInterstitialAd = false;

        ad.dispose();

        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        debugPrint(
          'Interstitial Ad failed: $error',
        );

        _isShowingInterstitialAd = false;

        ad.dispose();

        loadInterstitialAd();
      },
      onAdImpression: (ad) {
        debugPrint(
          'Interstitial Ad impression.',
        );
      },
    );

    ad.show();
  }

  // ============================================================
  // REWARDED AD #1
  // ============================================================

  void loadRewardedAd() {
    if (_isLoadingRewardedAd ||
        _rewardedAd != null) {
      return;
    }

    _isLoadingRewardedAd = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingRewardedAd = false;

          _rewardedAd = ad;

          debugPrint(
            'Rewarded Ad #1 loaded.',
          );
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewardedAd = false;

          _rewardedAd = null;

          debugPrint(
            'Rewarded Ad #1 failed: $error',
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW REWARDED AD #1
  // ============================================================

  void showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdClosed,
  }) {
    final ad = _rewardedAd;

    if (ad == null) {
      loadRewardedAd();

      onAdClosed?.call();

      return;
    }

    if (_isShowingRewardedAd) {
      return;
    }

    _isShowingRewardedAd = true;

    _rewardedAd = null;

    bool rewardEarned = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint(
          'Rewarded Ad #1 showed.',
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint(
          'Rewarded Ad #1 dismissed.',
        );

        _isShowingRewardedAd = false;

        ad.dispose();

        loadRewardedAd();

        if (!rewardEarned) {
          onAdClosed?.call();
        }
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        debugPrint(
          'Rewarded Ad #1 failed to show: $error',
        );

        _isShowingRewardedAd = false;

        ad.dispose();

        loadRewardedAd();

        onAdClosed?.call();
      },
      onAdImpression: (ad) {
        debugPrint(
          'Rewarded Ad #1 impression.',
        );
      },
    );

    ad.show(
      onUserEarnedReward:
          (ad, rewardItem) {
        rewardEarned = true;

        debugPrint(
          'Reward earned: '
          '${rewardItem.amount} '
          '${rewardItem.type}',
        );

        onRewardEarned();
      },
    );
  }

  // ============================================================
  // REWARDED AD #2
  // ============================================================

  void loadRewardedAd2() {
    if (_isLoadingRewardedAd2 ||
        _rewardedAd2 != null) {
      return;
    }

    _isLoadingRewardedAd2 = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId2,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingRewardedAd2 = false;

          _rewardedAd2 = ad;

          debugPrint(
            'Rewarded Ad #2 loaded.',
          );
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewardedAd2 = false;

          _rewardedAd2 = null;

          debugPrint(
            'Rewarded Ad #2 failed: $error',
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW REWARDED AD #2
  // ============================================================

  void showRewardedAd2({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdClosed,
  }) {
    final ad = _rewardedAd2;

    if (ad == null) {
      loadRewardedAd2();

      onAdClosed?.call();

      return;
    }

    if (_isShowingRewardedAd2) {
      return;
    }

    _isShowingRewardedAd2 = true;

    _rewardedAd2 = null;

    bool rewardEarned = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint(
          'Rewarded Ad #2 showed.',
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint(
          'Rewarded Ad #2 dismissed.',
        );

        _isShowingRewardedAd2 = false;

        ad.dispose();

        loadRewardedAd2();

        if (!rewardEarned) {
          onAdClosed?.call();
        }
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        debugPrint(
          'Rewarded Ad #2 failed to show: $error',
        );

        _isShowingRewardedAd2 = false;

        ad.dispose();

        loadRewardedAd2();

        onAdClosed?.call();
      },
      onAdImpression: (ad) {
        debugPrint(
          'Rewarded Ad #2 impression.',
        );
      },
    );

    ad.show(
      onUserEarnedReward:
          (ad, rewardItem) {
        rewardEarned = true;

        debugPrint(
          'Reward #2 earned: '
          '${rewardItem.amount} '
          '${rewardItem.type}',
        );

        onRewardEarned();
      },
    );
  }

  // ============================================================
  // NATIVE AD
  // ============================================================

  void loadNativeAd() {
    _nativeAd?.dispose();

    final ad = NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint(
            'Native Ad loaded.',
          );
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            'Native Ad failed: $error',
          );

          ad.dispose();

          _nativeAd = null;
        },
        onAdOpened: (ad) {
          debugPrint(
            'Native Ad opened.',
          );
        },
        onAdClosed: (ad) {
          debugPrint(
            'Native Ad closed.',
          );
        },
        onAdImpression: (ad) {
          debugPrint(
            'Native Ad impression.',
          );
        },
      ),

      // --------------------------------------------------------
      // IMPORTANT
      // --------------------------------------------------------
      //
      // NativeAd needs a native factory.
      // If your Android project has no native factory yet,
      // this ad may fail to load.
      //
      // Therefore the native ad is kept available through
      // the service, but the actual NativeAd widget should
      // only be displayed after Android native factory setup.
      //
      // --------------------------------------------------------
    );

    _nativeAd = ad;

    ad.load();
  }

  // ============================================================
  // GET NATIVE AD
  // ============================================================

  NativeAd? get nativeAd => _nativeAd;

  // ============================================================
  // DISPOSE BANNER
  // ============================================================

  void disposeBannerAd() {
    _bannerAd?.dispose();

    _bannerAd = null;
  }

  // ============================================================
  // DISPOSE NATIVE
  // ============================================================

  void disposeNativeAd() {
    _nativeAd?.dispose();

    _nativeAd = null;
  }

  // ============================================================
  // DISPOSE ALL
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

    _isLoadingAppOpenAd = false;

    _isLoadingInterstitialAd = false;

    _isLoadingRewardedAd = false;

    _isLoadingRewardedAd2 = false;

    _isShowingAppOpenAd = false;

    _isShowingInterstitialAd = false;

    _isShowingRewardedAd = false;

    _isShowingRewardedAd2 = false;
  }
}
