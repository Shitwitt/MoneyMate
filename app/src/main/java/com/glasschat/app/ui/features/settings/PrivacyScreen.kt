package com.glasschat.app.ui.features.settings

import androidx.biometric.BiometricManager
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassSnackbarHost
import com.glasschat.app.ui.glass.GlassSwitch
import com.glasschat.app.ui.theme.LocalGlassColors
import kotlinx.coroutines.launch

@Composable
fun PrivacyScreen(
    onBack: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current
    val prefs = state.preferences
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(Unit) {
        viewModel.events.collect { snackbarHostState.showSnackbar(it.message) }
    }

    fun biometricsReady(): Boolean {
        val manager = BiometricManager.from(context)
        val allowed = BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL
        return manager.canAuthenticate(allowed) == BiometricManager.BIOMETRIC_SUCCESS
    }

    GlassScaffold(
        reserveBottomBar = false,
        topBar = { SettingsSubHeader("Privacy", "Nothing leaves this device", onBack) },
        snackbarHost = { GlassSnackbarHost(snackbarHostState) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            GlassSectionHeader(title = "App lock")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Require biometrics to open",
                        subtitle = if (biometricsReady()) {
                            "Fingerprint, face or device PIN"
                        } else {
                            "Set a screen lock on this device first"
                        },
                        trailing = {
                            GlassSwitch(
                                checked = prefs.appLockEnabled,
                                onCheckedChange = { enabled ->
                                    if (enabled && !biometricsReady()) {
                                        scope.launch {
                                            snackbarHostState.showSnackbar(
                                                "Add a fingerprint, face or PIN in system settings to use app lock",
                                            )
                                        }
                                    } else {
                                        viewModel.setAppLock(enabled)
                                    }
                                },
                            )
                        },
                    )
                }
            }

            GlassSectionHeader(title = "On screen")
            GlassCard(padding = PaddingValues(0.dp)) {
                Column {
                    GlassSettingRow(
                        title = "Hide previews in recent apps",
                        subtitle = "Blocks the task switcher thumbnail",
                        trailing = {
                            GlassSwitch(
                                checked = prefs.hidePreviewsInRecents,
                                onCheckedChange = viewModel::setHidePreviews,
                            )
                        },
                    )
                    GlassSettingRow(
                        title = "Blur media in chat list",
                        subtitle = "Thumbnails are frosted until you open them",
                        trailing = {
                            GlassSwitch(
                                checked = prefs.blurMediaInList,
                                onCheckedChange = viewModel::setBlurMedia,
                            )
                        },
                    )
                }
            }

            GlassSectionHeader(title = "What GlassChat never does")
            GlassCard {
                Text(
                    text = "· No internet permission is declared, so no message or file can be uploaded.\n" +
                        "· Your address book is never read; contacts here are local records.\n" +
                        "· No analytics, no crash reporting, no advertising identifiers.\n" +
                        "· Android cloud backup is disabled for this app's data.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.textSecondary,
                )
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}
