package com.glasschat.app.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.domain.repository.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Owns the two app-level concerns: the theme snapshot (so the very first frame is already
 * correct) and whether onboarding has been completed yet.
 */
@HiltViewModel
class MainViewModel @Inject constructor(
    settingsRepository: SettingsRepository,
) : ViewModel() {

    private val _preferences = MutableStateFlow<AppPreferences?>(null)
    val preferences: StateFlow<AppPreferences?> = _preferences.asStateFlow()

    private val _isReady = MutableStateFlow(false)
    val isReady: StateFlow<Boolean> = _isReady.asStateFlow()

    init {
        viewModelScope.launch {
            val loaded = settingsRepository.preferences.first()
            _preferences.value = loaded
            _isReady.value = true
            settingsRepository.preferences.collect { _preferences.value = it }
        }
    }
}
