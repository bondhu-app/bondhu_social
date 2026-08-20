package com.bondhu.social

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.TextView

import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register Native Ad Factory for Flutter Google Mobile Ads.
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "listTile",
            ListTileNativeAdFactory(this)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // Unregister the Native Ad Factory.
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "listTile"
        )

        super.cleanUpFlutterEngine(flutterEngine)
    }
}

/**
 * Native Ad Factory
 *
 * This factory creates the Android view used by:
 *
 * factoryId: "listTile"
 *
 * from lib/services/ad_service.dart
 */
class ListTileNativeAdFactory(
    private val context: Context
) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {

        val adView = LayoutInflater
            .from(context)
            .inflate(
                android.R.layout.simple_list_item_2,
                null
            ) as NativeAdView

        val headlineView =
            adView.findViewById<TextView>(android.R.id.text1)

        val bodyView =
            adView.findViewById<TextView>(android.R.id.text2)

        headlineView.text =
            nativeAd.headline ?: "Sponsored"

        bodyView.text =
            nativeAd.body ?: "Advertisement"

        adView.headlineView = headlineView
        adView.bodyView = bodyView

        adView.setNativeAd(nativeAd)

        return adView
    }
}
