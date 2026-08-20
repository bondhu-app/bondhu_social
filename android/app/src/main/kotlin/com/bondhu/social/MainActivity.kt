package com.bondhu.social

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {

    private var nativeAdFactory: ListTileNativeAdFactory? = null

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        nativeAdFactory = ListTileNativeAdFactory(
            this
        )

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

        super.cleanUpFlutterEngine(
            flutterEngine
        )
    }
}
