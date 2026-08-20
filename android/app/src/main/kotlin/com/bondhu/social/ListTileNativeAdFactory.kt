package com.bondhu.social

import android.content.Context
import android.graphics.Color
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView

import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView

import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class ListTileNativeAdFactory(
    private val context: Context
) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {

        val adView = NativeAdView(context)

        val container = LinearLayout(context)

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

        // ========================================================
        // HEADLINE
        // ========================================================

        val headlineView = TextView(context)

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
            nativeAd.headline ?: "Sponsored"

        container.addView(
            headlineView,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        )

        // ========================================================
        // BODY
        // ========================================================

        val bodyView = TextView(context)

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
            nativeAd.body ?: "Sponsored content"

        container.addView(
            bodyView,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        )

        // ========================================================
        // ADD CONTAINER
        // ========================================================

        adView.addView(
            container
        )

        // ========================================================
        // REGISTER AD ASSETS
        // ========================================================

        adView.headlineView =
            headlineView

        adView.bodyView =
            bodyView

        // ========================================================
        // SET NATIVE AD
        // ========================================================

        adView.setNativeAd(
            nativeAd
        )

        return adView
    }
}
