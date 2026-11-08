package com.glasschat.app.ui.features.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.glasschat.app.BuildConfig
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassScaffold
import com.glasschat.app.ui.glass.GlassSectionHeader
import com.glasschat.app.ui.theme.LocalGlassColors

@Composable
fun AboutScreen(onBack: () -> Unit) {
    val colors = LocalGlassColors.current

    val licenses = listOf(
        "Kotlin & Kotlin Coroutines — Apache License 2.0",
        "AndroidX, Jetpack Compose, Material 3 — Apache License 2.0",
        "Room, DataStore, Hilt/Dagger, Navigation, Coil — Apache License 2.0",
        "kotlinx.serialization — Apache License 2.0",
        "androidx.biometric — Apache License 2.0",
    )

    GlassScaffold(
        reserveBottomBar = false,
        topBar = { SettingsSubHeader("About", "GlassChat ${BuildConfig.VERSION_NAME}", onBack) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            GlassCard {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    com.glasschat.app.ui.glass.GlassSurface(
                        modifier = Modifier.size(84.dp),
                        shape = androidx.compose.foundation.shape.RoundedCornerShape(26.dp),
                        fill = colors.accent.copy(alpha = 0.22f),
                        shadowElevation = 0.dp,
                    ) {
                        Column(
                            Modifier.fillMaxWidth().padding(6.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            Text(text = "💬", style = MaterialTheme.typography.displaySmall)
                        }
                    }
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = "GlassChat",
                        style = MaterialTheme.typography.headlineSmall,
                        color = colors.textPrimary,
                    )
                    Text(
                        text = "Version ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})",
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.textSecondary,
                    )
                    Spacer(Modifier.height(10.dp))
                    Text(
                        text = "An offline-first chat workspace for writing conversations with yourself, real people you know, or fictional characters — all stored only on this device.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textSecondary,
                        textAlign = TextAlign.Center,
                    )
                }
            }

            GlassSectionHeader(title = "What this app is not")
            GlassCard {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        text = "GlassChat does not send messages, create accounts, sync devices or connect to any service. There is no server, and the app does not request the INTERNET permission.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textPrimary,
                    )
                    Text(
                        text = "Delivery ticks, unread badges and typing dots are cosmetic simulations for the conversations you author. They are always labelled as simulated.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textSecondary,
                    )
                    Text(
                        text = "GlassChat is not affiliated with, endorsed by, or connected to Apple, Signal, Google, Meta or any messaging provider.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textSecondary,
                    )
                }
            }

            GlassSectionHeader(title = "Open-source licenses")
            GlassCard {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    licenses.forEach { line ->
                        Text(
                            text = "· $line",
                            style = MaterialTheme.typography.bodySmall,
                            color = colors.textSecondary,
                        )
                    }
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = "Full license texts remain available from each project's source repository.",
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.textTertiary,
                    )
                }
            }

            GlassSectionHeader(title = "Design")
            GlassCard {
                Text(
                    text = "GlassChat's look is an original interpretation of translucent, layered surfaces: frosted panels, refraction highlights, aurora backdrops and spring motion. No third-party UI assets are used.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.textSecondary,
                )
            }

            Spacer(Modifier.height(28.dp))
            Text(
                text = "Built with Kotlin and Jetpack Compose.",
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(24.dp))
        }
    }
}
