package com.glasschat.app

import android.app.Application
import coil.ImageLoader
import coil.ImageLoaderFactory
import coil.decode.VideoFrameDecoder
import coil.disk.DiskCache
import dagger.hilt.android.HiltAndroidApp

/**
 * Application entry point. Everything GlassChat stores lives under the app's private
 * data directory, so no external storage permission is ever required.
 */
@HiltAndroidApp
class GlassChatApplication : Application(), ImageLoaderFactory {

    /**
     * Coil is configured with a small disk cache plus a video frame decoder so that video
     * attachments can render a still thumbnail without pulling in a full media pipeline.
     */
    override fun newImageLoader(): ImageLoader = ImageLoader.Builder(this)
        .components { add(VideoFrameDecoder.Factory()) }
        .diskCache {
            DiskCache.Builder()
                .directory(cacheDir.resolve("image_cache"))
                .maxSizeBytes(96L * 1024L * 1024L)
                .build()
        }
        .crossfade(true)
        .build()
}
