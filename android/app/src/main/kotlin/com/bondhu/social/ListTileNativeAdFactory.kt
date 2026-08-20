package com.bondhu.social

import android.graphics.Color
import android.view.LayoutInflater
import android.widget.LinearLayout
import android.widget.TextView

import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView

import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class ListTileNativeAdFactory(
    private val inflater: LayoutInflater
) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd?,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {

        val adView = NativeAdView(
            inflater.context
        )

        val container = LinearLayout(
            inflater.context
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

        // --------------------------------------------------------
        // HEADLINE
        // --------------------------------------------------------

        val headlineView = TextView(
            inflater.context
        )

        headlineView.textSize = 17f

        headlineView.setTextColor(
            Color.BLACK
        )

        headlineView.setPadding(
            8,
            8,
            8,
            8
        )

        headlineView.text =
            nativeAd?.headline ?: "Sponsored"

        container.addView(
            headlineView,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        // --------------------------------------------------------
        // BODY
        // --------------------------------------------------------

        val bodyView = TextView(
            inflater.context
        )

        bodyView.textSize = 14f

        bodyView.setTextColor(
            Color.DKGRAY
        )

        bodyView.setPadding(
            8,
            4,
            8,
            8
        )

        bodyView.text =
            nativeAd?.body ?: "Sponsored content"

        container.addView(
            bodyView,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        // --------------------------------------------------------
        // ADD VIEW
        // --------------------------------------------------------

        adView.addView(
            container
        )

        // --------------------------------------------------------
        // REGISTER AD ASSETS
        // --------------------------------------------------------

        adView.headlineView =
            headlineView

        adView.bodyView =
            bodyView

        // --------------------------------------------------------
        // SET NATIVE AD
        // --------------------------------------------------------

        adView.setNativeAd(
            nativeAd
        )

        return adView
    }
}
