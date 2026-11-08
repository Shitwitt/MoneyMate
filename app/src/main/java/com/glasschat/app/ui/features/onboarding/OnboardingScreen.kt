package com.glasschat.app.ui.features.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.glasschat.app.domain.model.ThemeMode
import com.glasschat.app.ui.components.AccentColorPicker
import com.glasschat.app.ui.glass.AuroraBackground
import com.glasschat.app.ui.components.GlassAvatar
import com.glasschat.app.ui.glass.GlassCard
import com.glasschat.app.ui.glass.GlassChip
import com.glasschat.app.ui.glass.GlassLabeledField
import com.glasschat.app.ui.glass.GlassSegmentedControl
import com.glasschat.app.ui.glass.GlassSettingRow
import com.glasschat.app.ui.glass.GlassSwitch
import com.glasschat.app.ui.glass.GlassSurface
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors
import androidx.compose.foundation.shape.RoundedCornerShape

@Composable
fun OnboardingScreen(
    onFinished: () -> Unit,
    viewModel: OnboardingViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val colors = LocalGlassColors.current

    Box(Modifier.fillMaxSize()) {
        AuroraBackground(Modifier.fillMaxSize())
        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
                .padding(horizontal = 20.dp),
        ) {
            Spacer(Modifier.height(18.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                GlassSurface(
                    modifier = Modifier.size(46.dp),
                    shape = RoundedCornerShape(15.dp),
                    fill = colors.accent.copy(alpha = 0.24f),
                    shadowElevation = 0.dp,
                ) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(text = "💬", style = MaterialTheme.typography.titleLarge)
                    }
                }
                Spacer(Modifier.width(12.dp))
                Column {
                    Text(
                        text = "GlassChat",
                        style = MaterialTheme.typography.headlineSmall,
                        color = colors.textPrimary,
                    )
                    Text(
                        text = "Offline chat workspace",
                        style = MaterialTheme.typography.labelMedium,
                        color = colors.textSecondary,
                    )
                }
            }

            Spacer(Modifier.height(18.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                repeat(OnboardingUiState.STEP_COUNT) { index ->
                    Box(
                        modifier = Modifier
                            .height(5.dp)
                            .width(if (index == state.step) 26.dp else 10.dp)
                            .clip(CircleShape)
                            .background(
                                if (index <= state.step) colors.accent else colors.glassFillStrong,
                            ),
                    )
                }
            }

            Spacer(Modifier.height(18.dp))

            AnimatedContent(
                targetState = state.step,
                transitionSpec = { fadeIn() togetherWith fadeOut() },
                modifier = Modifier.weight(1f),
                label = "onboarding-step",
            ) { step ->
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    when (step) {
                        0 -> WelcomeStep(
                            name = state.displayName,
                            onNameChange = viewModel::setName,
                        )

                        1 -> LookStep(
                            accent = state.accent,
                            themeMode = state.themeMode,
                            onAccent = { value -> value?.let(viewModel::setAccent) },
                            onTheme = viewModel::setTheme,
                        )

                        else -> ReadyStep(
                            name = state.displayName,
                            accent = state.accent,
                            includeSamples = state.includeSamples,
                            onSamples = viewModel::setIncludeSamples,
                            isFinishing = state.isFinishing,
                            onFinish = { viewModel.finish(onFinished) },
                        )
                    }
                }
            }

            Spacer(Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                AnimatedVisibility(visible = state.step > 0) {
                    GlassChip(label = "Back", onClick = viewModel::back)
                }
                Spacer(Modifier.weight(1f))
                if (state.step < OnboardingUiState.STEP_COUNT - 1) {
                    GlassChip(
                        label = "Continue",
                        selected = true,
                        onClick = viewModel::next,
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
            Text(
                text = "No account, no internet permission, no analytics. Everything stays in this app.",
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(18.dp))
        }
    }
}

@Composable
private fun WelcomeStep(name: String, onNameChange: (String) -> Unit) {
    val colors = LocalGlassColors.current
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(
            text = "Write the conversations\nyou keep replaying.",
            style = MaterialTheme.typography.displaySmall,
            color = colors.textPrimary,
        )
        Text(
            text = "GlassChat is a private studio for drafting chats with friends, colleagues or characters you invent. You author both sides — nothing is ever sent.",
            style = MaterialTheme.typography.bodyLarge,
            color = colors.textSecondary,
        )
        GlassCard(padding = PaddingValues(16.dp)) {
            Column {
                GlassLabeledField(
                    label = "What should you be called?",
                    value = name,
                    onValueChange = onNameChange,
                    placeholder = "Me",
                    supportingText = "You can change this later in My profile",
                )
                Spacer(Modifier.height(10.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    GlassAvatar(
                        name = name.ifBlank { "Me" },
                        accentColor = colors.accent,
                        size = 38.dp,
                    )
                    Spacer(Modifier.width(10.dp))
                    Text(
                        text = "This avatar marks your messages.",
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.textTertiary,
                    )
                }
            }
        }
    }
}

@Composable
private fun LookStep(
    accent: Long,
    themeMode: ThemeMode,
    onAccent: (Long?) -> Unit,
    onTheme: (ThemeMode) -> Unit,
) {
    val colors = LocalGlassColors.current
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(
            text = "Choose your light.",
            style = MaterialTheme.typography.displaySmall,
            color = colors.textPrimary,
        )
        Text(
            text = "Glass surfaces pick up the accent you choose. Everything is designed to stay readable at large text sizes and in both light and dark.",
            style = MaterialTheme.typography.bodyLarge,
            color = colors.textSecondary,
        )
        GlassCard {
            Column {
                Text(
                    text = "Accent",
                    style = MaterialTheme.typography.labelMedium,
                    color = colors.textTertiary,
                )
                Spacer(Modifier.height(4.dp))
                AccentColorPicker(
                    selected = accent,
                    onSelect = onAccent,
                    allowInherit = false,
                )
                Spacer(Modifier.height(12.dp))
                GlassSegmentedControl(
                    options = ThemeMode.entries.toList(),
                    selected = themeMode,
                    onSelect = onTheme,
                    label = { mode ->
                        when (mode) {
                            ThemeMode.SYSTEM -> "System"
                            ThemeMode.LIGHT -> "Light"
                            ThemeMode.DARK -> "Dark"
                        }
                    },
                )
            }
        }
    }
}

@Composable
private fun ReadyStep(
    name: String,
    accent: Long,
    includeSamples: Boolean,
    onSamples: (Boolean) -> Unit,
    isFinishing: Boolean,
    onFinish: () -> Unit,
) {
    val colors = LocalGlassColors.current
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(
            text = "You're set, ${name.ifBlank { "friend" }}.",
            style = MaterialTheme.typography.displaySmall,
            color = colors.textPrimary,
        )
        Text(
            text = "Create contacts, then start a chat alone or with a group. Switch the composer between Me and the other participant to write both sides.",
            style = MaterialTheme.typography.bodyLarge,
            color = colors.textSecondary,
        )
        GlassCard(padding = PaddingValues(0.dp)) {
            GlassSettingRow(
                title = "Start with two sample chats",
                subtitle = "Maya Chen and a small group — delete them any time",
                trailing = {
                    GlassSwitch(checked = includeSamples, onCheckedChange = onSamples)
                },
            )
        }
        GlassCard {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    androidx.compose.material3.Icon(
                        imageVector = Icons.Filled.Check,
                        contentDescription = null,
                        tint = colors.accent,
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(
                        text = "Works completely offline",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textPrimary,
                    )
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    androidx.compose.material3.Icon(
                        imageVector = Icons.Filled.Check,
                        contentDescription = null,
                        tint = colors.accent,
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(
                        text = "Media copied into private app storage",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textPrimary,
                    )
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    androidx.compose.material3.Icon(
                        imageVector = Icons.Filled.Check,
                        contentDescription = null,
                        tint = colors.accent,
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(
                        text = "Optional biometric app lock",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textPrimary,
                    )
                }
            }
        }
        GlassChip(
            label = if (isFinishing) "Preparing…" else "Enter GlassChat",
            selected = true,
            onClick = { if (!isFinishing) onFinish() },
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.height(4.dp))
        Text(
            text = "Detail settings — theme, wallpapers, backups and privacy — live in the Settings tab.",
            style = MaterialTheme.typography.labelSmall,
            color = colors.textTertiary,
        )
    }
}
