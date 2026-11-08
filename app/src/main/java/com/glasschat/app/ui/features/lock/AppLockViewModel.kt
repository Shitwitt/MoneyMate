package com.glasschat.app.ui.features.lock

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.repository.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

/**
 * Holds the unlock gate. The actual prompt is shown by the UI (it needs an Activity); this
 * view model only tracks whether the app should currently be locked.
 */
@HiltViewModel
class AppLockViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    settingsRepository: SettingsRepository,
) : ViewModel() {

    private val unlockedThisSession = MutableStateFlow(false)

    val locked: StateFlow<Boolean> = combine(
        settingsRepository.preferences,
        unlockedThisSession,
    ) { prefs, unlocked -> prefs.appLockEnabled && !unlocked }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    /** `true` when the device can offer biometrics or a device credential. */
    fun canAuthenticate(): Boolean {
        val manager = BiometricManager.from(context)
        val enabled = BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL
        return manager.canAuthenticate(enabled) == BiometricManager.BIOMETRIC_SUCCESS
    }

    fun onAuthenticated() {
        unlockedThisSession.value = true
    }

    fun onAppBackgrounded() {
        unlockedThisSession.value = false
    }
}
