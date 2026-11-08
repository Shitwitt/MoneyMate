package com.glasschat.app.di

import javax.inject.Qualifier

/** Long-lived scope that outlives any single screen (used for caching and cleanup work). */
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class ApplicationScope

/** Dispatcher for blocking file / database work. */
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher
