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
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMob initialize error: $e');
    }
  }

  // ============================================================
  // BANNER
  // ============================================================

  BannerAd? createBannerAd({
    required void Function(Ad ad) onLoaded,
    required void Function(Ad ad, LoadAdError error) onFailed,
  }) {
    BannerAd bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
    );

    bannerAd.load();

    return bannerAd;
  }

  // ============================================================
  // INTERSTITIAL
  // ============================================================

  InterstitialAd? _interstitialAd;

  bool _isInterstitialLoading = false;

  void loadInterstitialAd() {
    if (_interstitialAd != null ||
        _isInterstitialLoading) {
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
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;

          debugPrint(
            'Interstitial load error: $error',
          );
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    final ad = _interstitialAd;

    if (ad == null) {
      loadInterstitialAd();
      return;
    }

    _interstitialAd = null;

    await ad.show();
  }

  // ============================================================
  // REWARDED AD - 1
  // ============================================================

  RewardedAd? _rewardedAd;

  bool _isRewardedLoading = false;

  void loadRewardedAd() {
    if (_rewardedAd != null ||
        _isRewardedLoading) {
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
          _isRewardedLoading = false;
          _rewardedAd = null;

          debugPrint(
            'Rewarded load error: $error',
          );
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required void Function(
      num rewardAmount,
      String rewardType,
    ) onRewarded,
  }) async {
    final ad = _rewardedAd;

    if (ad == null) {
      loadRewardedAd();
      return false;
    }

    _rewardedAd = null;

    bool rewarded = false;

    ad.show(
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        rewarded = true;

        onRewarded(
          reward.amount,
          reward.type,
        );
      },
    );

    return rewarded;
  }

  // ============================================================
  // REWARDED AD - 2
  // ============================================================

  RewardedAd? _rewardedAd2;

  bool _isRewardedLoading2 = false;

  void loadRewardedAd2() {
    if (_rewardedAd2 != null ||
        _isRewardedLoading2) {
      return;
    }

    _isRewardedLoading2 = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId2,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewardedLoading2 = false;
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
          _isRewardedLoading2 = false;
          _rewardedAd2 = null;

          debugPrint(
            'Rewarded 2 load error: $error',
          );
        },
      ),
    );
  }

  void showRewardedAd2({
    required void Function(
      num rewardAmount,
      String rewardType,
    ) onRewarded,
  }) {
    final ad = _rewardedAd2;

    if (ad == null) {
      loadRewardedAd2();
      return;
    }

    _rewardedAd2 = null;

    ad.show(
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        onRewarded(
          reward.amount,
          reward.type,
        );
      },
    );
  }

  // ============================================================
  // NATIVE ADVANCED
  // ============================================================

  NativeAd createNativeAd({
    required void Function(Ad ad) onLoaded,
    required void Function(Ad ad, LoadAdError error)
        onFailed,
  }) {
    final nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
      factoryId: 'listTile',
    );

    nativeAd.load();

    return nativeAd;
  }

  // ============================================================
  // APP OPEN AD
  // ============================================================

  AppOpenAd? _appOpenAd;

  bool _isAppOpenLoading = false;

  DateTime? _appOpenLoadTime;

  bool get isAppOpenAdAvailable {
    if (_appOpenAd == null) {
      return false;
    }

    if (_appOpenLoadTime == null) {
      return false;
    }

    final difference =
        DateTime.now().difference(
      _appOpenLoadTime!,
    );

    return difference.inHours < 4;
  }

  void loadAppOpenAd() {
    if (_appOpenAd != null ||
        _isAppOpenLoading) {
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

          _appOpenLoadTime =
              DateTime.now();

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent:
                (ad) {
              ad.dispose();
              _appOpenAd = null;
              _appOpenLoadTime = null;
              loadAppOpenAd();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              ad.dispose();
              _appOpenAd = null;
              _appOpenLoadTime = null;
              loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isAppOpenLoading = false;
          _appOpenAd = null;
          _appOpenLoadTime = null;

          debugPrint(
            'App Open load error: $error',
          );
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    if (!isAppOpenAdAvailable) {
      loadAppOpenAd();
      return;
    }

    final ad = _appOpenAd;

    if (ad == null) {
      return;
    }

    _appOpenAd = null;
    _appOpenLoadTime = null;

    ad.show();
  }

  // ============================================================
  // LOAD ALL ADS
  // ============================================================

  void preloadAds() {
    loadInterstitialAd();
    loadRewardedAd();
    loadRewardedAd2();
    loadAppOpenAd();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void disposeBanner(BannerAd? ad) {
    ad?.dispose();
  }
}
