package com.bondhu.social

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
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

        val adView = LayoutInflater
            .from(context)
            .inflate(
                R.layout.native_ad,
                null
            ) as NativeAdView

        val headlineView =
            adView.findViewById<TextView>(
                R.id.native_ad_headline
            )

        val bodyView =
            adView.findViewById<TextView>(
                R.id.native_ad_body
            )

        val callToActionView =
            adView.findViewById<Button>(
                R.id.native_ad_call_to_action
            )

        val iconView =
            adView.findViewById<ImageView>(
                R.id.native_ad_icon
            )

        // ========================================================
        // HEADLINE
        // ========================================================

        headlineView.text =
            nativeAd.headline

        adView.headlineView =
            headlineView

        // ========================================================
        // BODY
        // ========================================================

        if (nativeAd.body != null) {
            bodyView.text =
                nativeAd.body

            bodyView.visibility =
                View.VISIBLE

            adView.bodyView =
                bodyView
        } else {
            bodyView.visibility =
                View.GONE
        }

        // ========================================================
        // CALL TO ACTION
        // ========================================================

        if (nativeAd.callToAction != null) {
            callToActionView.text =
                nativeAd.callToAction

            callToActionView.visibility =
                View.VISIBLE

            adView.callToActionView =
                callToActionView
        } else {
            callToActionView.visibility =
                View.GONE
        }

        // ========================================================
        // ICON
        // ========================================================

        val icon = nativeAd.icon

        if (icon != null) {
            iconView.setImageDrawable(
                icon.drawable
            )

            iconView.visibility =
                View.VISIBLE

            adView.iconView =
                iconView
        } else {
            iconView.visibility =
                View.GONE
        }

        // ========================================================
        // NATIVE AD
        // ========================================================

        adView.setNativeAd(nativeAd)

        return adView
    }
}
