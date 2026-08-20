package com.bondhu.social

import android.graphics.Color
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView

import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {

    private var nativeAdFactory: ListTileNativeAdFactory? = null

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        nativeAdFactory = ListTileNativeAdFactory()

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "listTile",
            nativeAdFactory!!
        )
    }

    override fun cleanUpFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "listTile"
        )

        nativeAdFactory = null

        super.cleanUpFlutterEngine(flutterEngine)
    }
}

/**
 * Native Ad Factory
 *
 * factoryId:
 * listTile
 */
class ListTileNativeAdFactory : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd?,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {

        val adView = NativeAdView(this@ListTileNativeAdFactory.context)

        val container = LinearLayout(
            adView.context
        )

        container.orientation =
            LinearLayout.VERTICAL

        container.setPadding(
            20,
            16,
            20,
            16
        )

        container.setBackgroundColor(
            Color.WHITE
        )

        val headline = TextView(
            adView.context
        )

        headline.textSize = 17f
        headline.setTextColor(
            Color.BLACK
        )

        headline.gravity =
            Gravity.CENTER_VERTICAL

        headline.setPadding(
            8,
            8,
            8,
            8
        )

        headline.text =
            nativeAd?.headline ?: "Sponsored"

        container.addView(
            headline,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        val body = TextView(
            adView.context
        )

        body.textSize = 14f
        body.setTextColor(
            Color.DKGRAY
        )

        body.setPadding(
            8,
            4,
            8,
            8
        )

        body.text =
            nativeAd?.body ?: "Sponsored content"

        container.addView(
            body,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        adView.addView(container)

        adView.headlineView = headline
        adView.bodyView = body

        adView.setNativeAd(
            nativeAd
        )

        return adView
    }
}
