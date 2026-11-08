package com.glasschat.app.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.clickable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.glasschat.app.ui.theme.LocalGlassColors
import com.glasschat.app.ui.theme.LocalReduceMotion
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

private val ActionWidth = 76.dp

/**
 * A swipeable list row with real affordances behind the content.
 *
 * Swipe right to pin/unpin, swipe left to reveal archive + delete. The revealed buttons are
 * always reachable for TalkBack users through each row's long-press menu, so no action is
 * gesture-only.
 */
@Composable
fun GlassSwipeRow(
    modifier: Modifier = Modifier,
    onSwipeRight: () -> Unit,
    onArchive: () -> Unit,
    onDelete: () -> Unit,
    pinLabel: String = "Pin",
    archiveLabel: String = "Archive",
    deleteLabel: String = "Delete",
    content: @Composable () -> Unit,
) {
    val colors = LocalGlassColors.current
    val reduceMotion = LocalReduceMotion.current
    val scope = rememberCoroutineScope()
    val offset = remember { Animatable(0f) }
    val density = LocalDensity.current
    val actionWidthPx = with(density) { ActionWidth.toPx() }
    val maxRight = with(density) { 84.dp.toPx() }
    val maxLeft = actionWidthPx * 2

    fun settle(target: Float) {
        scope.launch {
            offset.animateTo(
                targetValue = target,
                animationSpec = tween(durationMillis = if (reduceMotion) 0 else 220),
            )
        }
    }

    Box(modifier = modifier.fillMaxWidth().clip(RoundedCornerShape(22.dp))) {
        // Background affordances
        Row(
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Box(
                modifier = Modifier
                    .width(if (offset.value > 0f) with(density) { offset.value.toDp() } else 0.dp)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(22.dp))
                    .background(Color.Transparent),
            )
            Row {
                SwipeAction(
                    label = archiveLabel,
                    icon = androidx.compose.material.icons.Icons.Outlined.Archive,
                    background = colors.accent.copy(alpha = 0.24f),
                    contentColor = colors.accent,
                    onClick = {
                        settle(0f)
                        onArchive()
                    },
                )
                SwipeAction(
                    label = deleteLabel,
                    icon = androidx.compose.material.icons.Icons.Outlined.Delete,
                    background = colors.danger.copy(alpha = if (colors.isDark) 0.22f else 0.16f),
                    contentColor = colors.danger,
                    onClick = {
                        settle(0f)
                        onDelete()
                    },
                )
            }
        }

        // Pin affordance (revealed when swiping right)
        if (offset.value > 0f) {
            Box(
                modifier = Modifier
                    .align(Alignment.CenterStart)
                    .width(with(density) { maxRight.toDp() })
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(22.dp))
                    .background(colors.accent.copy(alpha = 0.22f))
                    .clickable(role = Role.Button) {
                        settle(0f)
                        onSwipeRight()
                    },
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        imageVector = androidx.compose.material.icons.Icons.Outlined.PushPin,
                        contentDescription = pinLabel,
                        tint = colors.accent,
                        modifier = Modifier.size(20.dp),
                    )
                }
            }
        }

        Box(
            modifier = Modifier
                .offset { IntOffset(offset.value.roundToInt(), 0) }
                .pointerInput(Unit) {
                    detectHorizontalDragGestures(
                        onDragEnd = {
                            val position = offset.value
                            when {
                                position >= maxRight * 0.55f -> {
                                    settle(0f)
                                    onSwipeRight()
                                }

                                position <= -maxLeft * 0.42f -> settle(-maxLeft)
                                position >= maxRight * 0.3f -> settle(0f)
                                else -> settle(0f)
                            }
                        },
                        onHorizontalDrag = { change, dragAmount ->
                            change.consume()
                            scope.launch {
                                val next = (offset.value + dragAmount)
                                    .coerceIn(-maxLeft, maxRight)
                                offset.snapTo(next)
                            }
                        },
                    )
                },
        ) {
            content()
        }
    }
}

@Composable
private fun SwipeAction(
    label: String,
    icon: ImageVector,
    background: Color,
    contentColor: Color,
    onClick: () -> Unit,
) {
    Column(
        modifier = Modifier
            .width(ActionWidth)
            .heightIn(min = 72.dp)
            .padding(2.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(background)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = contentColor,
            modifier = Modifier.size(20.dp),
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = contentColor,
        )
    }
}
