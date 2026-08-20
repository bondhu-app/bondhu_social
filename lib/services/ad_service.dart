import 'dart:io';

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

  static const String rewardedAdUnitId =
      'ca-app-pub-9879411172250653/1960594674';

  static const String rewardedAdUnitId2 =
      'ca-app-pub-9879411172250653/1769022980';

  static const String nativeAdUnitId =
      'ca-app-pub-9879411172250653/6507128160';

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ============================================================
  // PLATFORM CHECK
  // ============================================================

  static String get bannerUnitId {
    if (Platform.isAndroid) {
      return bannerAdUnitId;
    }

    return bannerAdUnitId;
  }

  static String get appOpenUnitId {
    if (Platform.isAndroid) {
      return appOpenAdUnitId;
    }

    return appOpenAdUnitId;
  }

  static String get interstitialUnitId {
    if (Platform.isAndroid) {
      return interstitialAdUnitId;
    }

    return interstitialAdUnitId;
  }

  static String get rewardedUnitId {
    if (Platform.isAndroid) {
      return rewardedAdUnitId;
    }

    return rewardedAdUnitId;
  }

  // ============================================================
  // BANNER
  // ============================================================

  BannerAd? _bannerAd;

  bool _bannerLoaded = false;

  bool get bannerLoaded => _bannerLoaded;

  void loadBanner() {
    _bannerAd?.dispose();

    _bannerLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: bannerUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          _bannerLoaded = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  BannerAd? get bannerAd => _bannerAd;

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _bannerLoaded = false;
  }

  // ============================================================
  // INTERSTITIAL
  // ============================================================

  InterstitialAd? _interstitialAd;

  bool _isInterstitialLoading = false;

  void loadInterstitial() {
    if (_isInterstitialLoading ||
        _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitial() {
    final ad = _interstitialAd;

    if (ad == null) {
      loadInterstitial();
      return;
    }

    _interstitialAd = null;

    ad.show();
  }

  // ============================================================
  // REWARDED
  // ============================================================

  RewardedAd? _rewardedAd;

  bool _isRewardedLoading = false;

  void loadRewarded() {
    if (_isRewardedLoading ||
        _rewardedAd != null) {
      return;
    }

    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent:
                (ad) {
              ad.dispose();
              _rewardedAd = null;
              loadRewarded();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  void showRewarded({
    required VoidCallback onReward,
  }) {
    final ad = _rewardedAd;

    if (ad == null) {
      loadRewarded();
      return;
    }

    _rewardedAd = null;

    ad.show(
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        onReward();
      },
    );
  }

  // ============================================================
  // NATIVE ADVANCED
  // ============================================================

  NativeAd? createNativeAd({
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
  }) {
    NativeAd? nativeAd;

    nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed();
        },
      ),
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
  // APP OPEN
  // ============================================================

  AppOpenAd? _appOpenAd;

  bool _isAppOpenLoading = false;

  bool _isShowingAppOpenAd = false;

  DateTime? _appOpenLoadTime;

  bool get isAppOpenAdAvailable {
    return _appOpenAd != null;
  }

  void loadAppOpenAd() {
    if (_isAppOpenLoading ||
        _appOpenAd != null) {
      return;
    }

    _isAppOpenLoading = true;

    AppOpenAd.load(
      adUnitId: appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
          _appOpenLoadTime = DateTime.now();

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
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    if (_isShowingAppOpenAd) {
      return;
    }

    final ad = _appOpenAd;

    if (ad == null) {
      loadAppOpenAd();
      return;
    }

    if (_appOpenLoadTime != null) {
      final difference =
          DateTime.now().difference(
        _appOpenLoadTime!,
      );

      if (difference >
          const Duration(hours: 4)) {
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoadTime = null;

        loadAppOpenAd();
        return;
      }
    }

    _isShowingAppOpenAd = true;

    _appOpenAd = null;

    ad.show();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    disposeBanner();

    _interstitialAd?.dispose();
    _interstitialAd = null;

    _rewardedAd?.dispose();
    _rewardedAd = null;

    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
