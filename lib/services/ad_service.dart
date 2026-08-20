import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // ============================================================
  // AD UNIT IDs
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

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ============================================================
  // BANNER
  // ============================================================

  BannerAd createBannerAd({
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
  }) {
    late final BannerAd bannerAd;

    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (kDebugMode) {
            debugPrint(
              'Banner Ad failed: ${error.message}',
            );
          }

          onFailed();
        },
      ),
    );

    bannerAd.load();

    return bannerAd;
  }

  // ============================================================
  // INTERSTITIAL
  // ============================================================

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;

  void loadInterstitialAd() {
    if (_isLoadingInterstitial ||
        _interstitialAd != null) {
      return;
    }

    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
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
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;

          if (kDebugMode) {
            debugPrint(
              'Interstitial failed: ${error.message}',
            );
          }
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

    ad.show();
  }

  // ============================================================
  // REWARDED
  // ============================================================

  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  void loadRewardedAd() {
    if (_isLoadingRewarded ||
        _rewardedAd != null) {
      return;
    }

    _isLoadingRewarded = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId1,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
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
        onAdFailedToLoad: (error) {
          _isLoadingRewarded = false;
          _rewardedAd = null;

          if (kDebugMode) {
            debugPrint(
              'Rewarded failed: ${error.message}',
            );
          }
        },
      ),
    );
  }

  void showRewardedAd({
    required void Function(
      RewardItem reward,
    ) onReward,
  }) {
    final ad = _rewardedAd;

    if (ad == null) {
      loadRewardedAd();
      return;
    }

    _rewardedAd = null;

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
  // APP OPEN
  // ============================================================

  AppOpenAd? _appOpenAd;
  bool _isLoadingAppOpen = false;
  bool _isShowingAppOpen = false;

  DateTime? _appOpenLoadedTime;

  void loadAppOpenAd() {
    if (_isLoadingAppOpen ||
        _appOpenAd != null) {
      return;
    }

    _isLoadingAppOpen = true;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback:
          AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAppOpen = false;
          _appOpenAd = ad;
          _appOpenLoadedTime =
              DateTime.now();

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent:
                (ad) {
              _isShowingAppOpen = false;

              ad.dispose();

              _appOpenAd = null;

              loadAppOpenAd();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              _isShowingAppOpen = false;

              ad.dispose();

              _appOpenAd = null;

              loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoadingAppOpen = false;
          _appOpenAd = null;

          if (kDebugMode) {
            debugPrint(
              'App Open failed: ${error.message}',
            );
          }
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    final ad = _appOpenAd;

    if (ad == null ||
        _isShowingAppOpen) {
      loadAppOpenAd();
      return;
    }

    // 4 ঘণ্টার বেশি পুরোনো Ad দেখাব না।
    if (_appOpenLoadedTime != null &&
        DateTime.now()
                .difference(
                  _appOpenLoadedTime!,
                )
                .inHours >=
            4) {
      ad.dispose();
      _appOpenAd = null;
      _appOpenLoadedTime = null;

      loadAppOpenAd();
      return;
    }

    _isShowingAppOpen = true;

    _appOpenAd = null;

    ad.show();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;

    _rewardedAd?.dispose();
    _rewardedAd = null;

    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
