package com.glasschat.app.ui.features.lock

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.glasschat.app.ui.glass.AuroraBackground
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassLoadingState
import com.glasschat.app.ui.glass.GlassSurface
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors

/**
 * Full-screen privacy gate shown whenever the app lock is enabled and the session is not
 * yet unlocked. It deliberately reveals nothing about the conversations underneath.
 */
@Composable
fun AppLockScreen(
    biometricsAvailable: Boolean,
    onUnlock: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    Box(modifier.fillMaxSize()) {
        AuroraBackground(modifier = Modifier.fillMaxSize(), animate = false)
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(28.dp),
            contentAlignment = Alignment.Center,
        ) {
            GlassSurface(
                modifier = Modifier.widthIn(max = 420.dp),
                shape = RoundedCornerShape(GlassRadius.panel),
                fill = colors.glassFillStrong,
                shadowElevation = 26.dp,
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(28.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    GlassSurface(
                        modifier = Modifier.size(76.dp),
                        shape = CircleShape,
                        fill = colors.accent.copy(alpha = 0.18f),
                        shadowElevation = 0.dp,
                    ) {
                        Box(
                            Modifier
                                .fillMaxWidth()
                                .height(76.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Lock,
                                contentDescription = null,
                                tint = colors.accent,
                                modifier = Modifier.size(30.dp),
                            )
                        }
                    }
                    Spacer(Modifier.height(18.dp))
                    Text(
                        text = "GlassChat is locked",
                        style = MaterialTheme.typography.headlineSmall,
                        color = colors.textPrimary,
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = if (biometricsAvailable) {
                            "Unlock with your fingerprint, face or device PIN. Nothing is uploaded to check it."
                        } else {
                            "Set up a screen lock on this device to use the GlassChat app lock."
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textSecondary,
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(22.dp))
                    if (biometricsAvailable) {
                        GlassChip(
                            label = "Unlock",
                            selected = true,
                            onClick = onUnlock,
                        )
                    } else {
                        Text(
                            text = "App lock is enabled in Settings → Privacy. You can turn it off from the system settings entry for GlassChat.",
                            style = MaterialTheme.typography.labelSmall,
                            color = colors.textTertiary,
                            textAlign = TextAlign.Center,
                        )
                    }
                }
            }
        }
    }
}

/** Shown for the handful of frames before preferences are read from DataStore. */
@Composable
fun LaunchGate(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize()) {
        AuroraBackground(modifier = Modifier.fillMaxSize(), animate = false)
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            GlassLoadingState(message = "Opening your chats…")
        }
    }
}
