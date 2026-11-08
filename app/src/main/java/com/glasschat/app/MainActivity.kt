package com.glasschat.app

import android.os.Bundle
import android.view.WindowManager
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.core.content.ContextCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.rememberNavController
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.ui.MainViewModel
import com.glasschat.app.ui.features.lock.AppLockScreen
import com.glasschat.app.ui.features.lock.LaunchGate
import com.glasschat.app.ui.navigation.GlassChatNavHost
import com.glasschat.app.ui.navigation.Routes
import com.glasschat.app.ui.theme.GlassChatTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * Single-activity host.
 *
 * FragmentActivity (rather than ComponentActivity) is required by androidx.biometric so the
 * optional app lock can use the platform biometric / device-credential prompt.
 */
@AndroidEntryPoint
class MainActivity : FragmentActivity() {

    private val mainViewModel: MainViewModel by viewModels()
    private val appLockViewModel: com.glasschat.app.ui.features.lock.AppLockViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        val splash = installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        splash.setKeepOnScreenCondition { !mainViewModel.isReady.value }

        setContent {
            val preferencesState by mainViewModel.preferences.collectAsStateWithLifecycle()
            val preferences = preferencesState ?: AppPreferences()
            val locked by appLockViewModel.locked.collectAsStateWithLifecycle()

            GlassChatTheme(preferences = preferences) {
                SideEffect {
                    if (preferences.hidePreviewsInRecents) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                }

                Surface(modifier = Modifier.fillMaxSize(), color = Color.Transparent) {
                    Box(
                        Modifier
                            .fillMaxSize()
                            .background(Color.Black.copy(alpha = 0.001f)),
                    ) {
                        if (preferencesState == null) {
                            LaunchGate()
                        } else {
                            val navController = rememberNavController()
                            GlassChatNavHost(
                                navController = navController,
                                startDestination = if (preferences.onboardingComplete) {
                                    Routes.CHATS
                                } else {
                                    Routes.ONBOARDING
                                },
                            )
                        }

                        if (locked) {
                            AppLockScreen(
                                biometricsAvailable = appLockViewModel.canAuthenticate(),
                                onUnlock = ::promptUnlock,
                            )
                        }
                    }
                }
            }

            LaunchedEffect(locked) {
                if (locked) promptUnlock()
            }
        }
    }

    override fun onStop() {
        super.onStop()
        appLockViewModel.onAppBackgrounded()
    }

    /** Shows the biometric / device-credential sheet when the device supports it. */
    private fun promptUnlock() {
        if (!appLockViewModel.canAuthenticate()) return
        val prompt = BiometricPrompt(
            this,
            ContextCompat.getMainExecutor(this),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    appLockViewModel.onAuthenticated()
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    // Stay locked; the user can retry from the button on the lock screen.
                }
            },
        )
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Unlock GlassChat")
            .setSubtitle("Your conversations never leave this device")
            .setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                    BiometricManager.Authenticators.DEVICE_CREDENTIAL,
            )
            .build()
        runCatching { prompt.authenticate(info) }
    }
}
