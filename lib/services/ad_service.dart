import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // ============================================================
  // ADMOB AD UNIT IDS
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

  // Rewarded 1
  static const String rewardedAdUnitId =
      'ca-app-pub-9879411172250653/1960594674';

  // Rewarded 2
  static const String rewardedAdUnitId2 =
      'ca-app-pub-9879411172250653/1769022980';

  // Native Advanced
  static const String nativeAdUnitId =
      'ca-app-pub-9879411172250653/6507128160';

  // ============================================================
  // INITIALIZE ADMOB
  // ============================================================

  static Future<InitializationStatus> initialize() async {
    return MobileAds.instance.initialize();
  }

  // ============================================================
  // BANNER AD
  // ============================================================

  static BannerAd createBannerAd({
    required void Function(Ad ad) onLoaded,
    required void Function(Ad ad, LoadAdError error) onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
    );
  }

  // ============================================================
  // INTERSTITIAL AD
  // ============================================================

  static void loadInterstitial({
    required void Function(InterstitialAd ad) onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed ??
            (LoadAdError error) {},
      ),
    );
  }

  // ============================================================
  // REWARDED AD 1
  // ============================================================

  static void loadRewardedAd({
    required void Function(RewardedAd ad) onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed ??
            (LoadAdError error) {},
      ),
    );
  }

  // ============================================================
  // REWARDED AD 2
  // ============================================================

  static void loadRewardedAd2({
    required void Function(RewardedAd ad) onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId2,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed ??
            (LoadAdError error) {},
      ),
    );
  }

  // ============================================================
  // NATIVE AD
  // ============================================================

  static NativeAd createNativeAd({
    required String factoryId,
    required void Function(Ad ad) onLoaded,
    required void Function(Ad ad, LoadAdError error) onFailed,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
    );
  }

  // ============================================================
  // APP OPEN AD
  // ============================================================

  static void loadAppOpenAd({
    required void Function(AppOpenAd ad) onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed ??
            (LoadAdError error) {},
      ),
    );
  }
}
