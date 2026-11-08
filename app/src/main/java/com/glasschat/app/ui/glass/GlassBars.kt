package com.glasschat.app.ui.glass

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarData
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.glasschat.app.domain.model.AppPreferences
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.ui.theme.LocalGlassMotion
import com.glasschat.app.ui.theme.LocalReduceMotion
import com.glasschat.app.ui.theme.Wallpapers

/** Height reserved for the floating bottom navigation bar (excluding system insets). */
val GlassBottomBarHeight = 74.dp

/** Distance the floating bar keeps from the bottom system inset. */
val GlassBottomBarGap = 12.dp

/**
 * Ambient backdrop: a deep gradient plus two slow refraction blobs. Motion is disabled
 * when the user asks for reduced motion, and the blur is a no-op below API 31 (the radial
 * gradients already read as soft there).
 */
@Composable
fun AuroraBackground(
    modifier: Modifier = Modifier,
    wallpaper: String? = null,
    animate: Boolean = true,
) {
    val colors = LocalGlassColors.current
    val reduceMotion = LocalReduceMotion.current
    val resolved = wallpaper ?: AppPreferences.WALLPAPER_AURORA
    val palette = remember(resolved, colors.isDark) { Wallpapers.palette(resolved, colors.isDark) }
    val customPath = remember(resolved) {
        if (resolved.startsWith(AppPreferences.CUSTOM_PREFIX)) {
            resolved.removePrefix(AppPreferences.CUSTOM_PREFIX)
        } else {
            null
        }
    }

    Box(modifier.background(Brush.verticalGradient(listOf(palette[0], palette[1])))) {
        if (customPath != null) {
            AsyncImage(
                model = customPath,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
            Box(
                Modifier
                    .fillMaxSize()
                    .background(palette[1].copy(alpha = if (colors.isDark) 0.45f else 0.35f)),
            )
        }

        val drift = if (reduceMotion || !animate) {
            0f
        } else {
            val transition = rememberInfiniteTransition(label = "aurora-drift")
            val value by transition.animateFloat(
                initialValue = 0f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(durationMillis = 16_000, easing = LinearEasing),
                    repeatMode = RepeatMode.Reverse,
                ),
                label = "aurora-drift-value",
            )
            value
        }

        Canvas(
            modifier = Modifier
                .fillMaxSize()
                .blur(64.dp),
        ) {
            val blobRadius = size.minDimension * 0.55f
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(palette[2].copy(alpha = 0.55f), Color.Transparent),
                    center = Offset(size.width * (0.18f + 0.08f * drift), size.height * 0.12f),
                    radius = blobRadius,
                ),
                radius = blobRadius,
                center = Offset(size.width * (0.18f + 0.08f * drift), size.height * 0.12f),
            )
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(palette[2].copy(alpha = 0.34f), Color.Transparent),
                    center = Offset(size.width * (0.92f - 0.10f * drift), size.height * 0.78f),
                    radius = blobRadius * 0.9f,
                ),
                radius = blobRadius * 0.9f,
                center = Offset(size.width * (0.92f - 0.10f * drift), size.height * 0.78f),
            )
            if (!colors.isDark) {
                // Light mode benefits from a bright refraction streak near the top.
                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(Color.White.copy(alpha = 0.55f), Color.Transparent),
                        center = Offset(size.width * 0.75f, size.height * 0.18f),
                        radius = blobRadius * 0.7f,
                    ),
                    radius = blobRadius * 0.7f,
                    center = Offset(size.width * 0.75f, size.height * 0.18f),
                )
            }
        }
    }
}

/**
 * Screen skeleton: backdrop, top bar, floating bottom bar, snackbar host and optional FAB.
 * Content receives padding that accounts for the floating bar so nothing is ever obscured.
 */
@Composable
fun GlassScaffold(
    modifier: Modifier = Modifier,
    wallpaper: String? = null,
    topBar: @Composable () -> Unit = {},
    bottomBar: @Composable () -> Unit = {},
    snackbarHost: @Composable () -> Unit = {},
    floatingActionButton: (@Composable () -> Unit)? = null,
    reserveBottomBar: Boolean = true,
    content: @Composable (PaddingValues) -> Unit,
) {
    val navigationInset = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
    val contentBottomPadding = if (reserveBottomBar) {
        GlassBottomBarHeight + GlassBottomBarGap + navigationInset + 12.dp
    } else {
        0.dp
    }
    Box(modifier.fillMaxSize()) {
        AuroraBackground(modifier = Modifier.fillMaxSize(), wallpaper = wallpaper)
        Column(Modifier.fillMaxSize()) {
            topBar()
            Box(Modifier.weight(1f)) {
                content(PaddingValues(bottom = contentBottomPadding))
            }
        }
        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth(),
            contentAlignment = Alignment.BottomCenter,
        ) {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Box(Modifier.padding(horizontal = 20.dp)) { snackbarHost() }
                Spacer(Modifier.height(8.dp))
                bottomBar()
            }
        }
        if (floatingActionButton != null) {
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(
                        end = 20.dp,
                        bottom = contentBottomPadding + 4.dp,
                    ),
            ) {
                floatingActionButton()
            }
        }
    }
}

/**
 * Frosted header. `compact` is used inside conversations (avatar + name), the default size
 * is used for the four primary tabs.
 */
@Composable
fun GlassTopBar(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    onBack: (() -> Unit)? = null,
    backContentDescription: String = "Go back",
    leading: @Composable (() -> Unit)? = null,
    compact: Boolean = false,
    actions: @Composable RowScope.() -> Unit = {},
) {
    val colors = LocalGlassColors.current
    GlassSurface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(bottomStart = GlassRadius.panel, bottomEnd = GlassRadius.panel),
        fill = colors.glassFill,
        shadowElevation = 10.dp,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .windowInsetsPadding(WindowInsets.statusBars)
                .padding(horizontal = 14.dp, vertical = if (compact) 10.dp else 16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (onBack != null) {
                GlassIconButton(
                    icon = androidx.compose.material.icons.Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = backContentDescription,
                    background = null,
                    onClick = onBack,
                )
                Spacer(Modifier.width(2.dp))
            }
            leading?.let {
                it()
                Spacer(Modifier.width(10.dp))
            }
            Column(Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = if (compact) {
                        MaterialTheme.typography.titleLarge
                    } else {
                        MaterialTheme.typography.headlineLarge
                    },
                    color = colors.textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (subtitle != null) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.textSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically, content = actions)
        }
    }
}

data class GlassNavItem(
    val label: String,
    val icon: ImageVector,
    val selectedIcon: ImageVector = icon,
    val badgeCount: Int = 0,
)

/** Floating, translucent tab bar with a spring-animated accent pill. */
@Composable
fun GlassBottomBar(
    items: List<GlassNavItem>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    val motion = LocalGlassMotion.current
    GlassSurface(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .navigationBarsPadding(),
        shape = RoundedCornerShape(GlassRadius.bar),
        fill = colors.glassFillStrong,
        shadowElevation = 22.dp,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(GlassBottomBarHeight)
                .padding(horizontal = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceEvenly,
        ) {
            items.forEachIndexed { index, item ->
                val selected = index == selectedIndex
                val tint by animateColorAsState(
                    targetValue = if (selected) colors.accent else colors.textSecondary,
                    animationSpec = tween(motion.medium),
                    label = "nav-tint-$index",
                )
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .heightIn(min = 56.dp)
                        .clip(RoundedCornerShape(GlassRadius.chip))
                        .testTag("tab_${item.label}")
                        .background(
                            if (selected) {
                                colors.accent.copy(alpha = if (colors.reduceTransparency) 0.18f else 0.14f)
                            } else {
                                Color.Transparent
                            },
                        )
                        .selectable(
                            selected = selected,
                            role = Role.Tab,
                            onClick = { onSelect(index) },
                        )
                        .padding(vertical = 8.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Box {
                            Icon(
                                imageVector = if (selected) item.selectedIcon else item.icon,
                                contentDescription = null,
                                tint = tint,
                                modifier = Modifier.size(22.dp),
                            )
                            if (item.badgeCount > 0) {
                                Box(Modifier.padding(start = 18.dp)) {
                                    GlassBadge(count = item.badgeCount)
                                }
                            }
                        }
                        Spacer(Modifier.height(3.dp))
                        Text(
                            text = item.label,
                            style = MaterialTheme.typography.labelSmall,
                            color = tint,
                            maxLines = 1,
                        )
                    }
                }
            }
        }
    }
}

/**
 * Tablet / foldable navigation: the same destinations, stacked vertically. Used when the
 * window is at least 600dp wide so the bottom bar does not waste horizontal space.
 */
@Composable
fun GlassNavigationRail(
    items: List<GlassNavItem>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    GlassSurface(
        modifier = modifier
            .width(88.dp)
            .fillMaxHeight(),
        shape = RoundedCornerShape(topEnd = GlassRadius.panel, bottomEnd = GlassRadius.panel),
        fill = colors.glassFill,
        shadowElevation = 12.dp,
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .windowInsetsPadding(WindowInsets.statusBars)
                .navigationBarsPadding()
                .padding(vertical = 14.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            items.forEachIndexed { index, item ->
                val selected = index == selectedIndex
                val tint by animateColorAsState(
                    targetValue = if (selected) colors.accent else colors.textSecondary,
                    animationSpec = tween(LocalGlassMotion.current.medium),
                    label = "rail-tint-$index",
                )
                Column(
                    modifier = Modifier
                        .size(68.dp)
                        .clip(RoundedCornerShape(GlassRadius.chip))
                        .background(
                            if (selected) colors.accent.copy(alpha = 0.14f) else Color.Transparent,
                        )
                        .selectable(selected = selected, role = Role.Tab, onClick = { onSelect(index) })
                        .padding(6.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    Icon(
                        imageVector = if (selected) item.selectedIcon else item.icon,
                        contentDescription = null,
                        tint = tint,
                        modifier = Modifier.size(22.dp),
                    )
                    Spacer(Modifier.height(3.dp))
                    Text(
                        text = item.label,
                        style = MaterialTheme.typography.labelSmall,
                        color = tint,
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

/** Glass-styled snackbar host, including the undo action used by swipe gestures. */
@Composable
fun GlassSnackbarHost(
    hostState: SnackbarHostState,
    modifier: Modifier = Modifier,
) {
    val colors = LocalGlassColors.current
    SnackbarHost(hostState = hostState, modifier = modifier) { data: SnackbarData ->
        GlassSurface(
            shape = RoundedCornerShape(GlassRadius.chip),
            fill = colors.glassFillStrong,
            shadowElevation = 16.dp,
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = data.visuals.message,
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.textPrimary,
                    modifier = Modifier.weight(1f),
                )
                val action = data.visuals.actionLabel
                if (action != null) {
                    Spacer(Modifier.width(12.dp))
                    Box(
                        modifier = Modifier
                            .clip(CircleShape)
                            .clickable { data.performAction() }
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                    ) {
                        Text(
                            text = action,
                            style = MaterialTheme.typography.labelLarge,
                            color = colors.accent,
                        )
                    }
                }
            }
        }
    }
}
