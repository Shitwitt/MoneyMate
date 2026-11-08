package com.glasschat.app.ui.glass

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import com.glasschat.app.ui.theme.GlassRadius
import com.glasschat.app.ui.theme.LocalGlassColors

/**
 * Rounded, multiline-capable text field with a glass container. It intentionally avoids
 * Material's outlined/filled text fields so the composer reads as a single translucent bar.
 */
@Composable
fun GlassTextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    minLines: Int = 1,
    maxLines: Int = 5,
    leading: (@Composable RowScope.() -> Unit)? = null,
    trailing: (@Composable RowScope.() -> Unit)? = null,
    keyboardOptions: KeyboardOptions = KeyboardOptions(
        capitalization = KeyboardCapitalization.Sentences,
        imeAction = ImeAction.Default,
    ),
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    enabled: Boolean = true,
) {
    val colors = LocalGlassColors.current
    GlassSurface(
        modifier = modifier,
        shape = RoundedCornerShape(GlassRadius.field),
        fill = colors.glassFill,
        shadowElevation = 0.dp,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 52.dp)
                .padding(horizontal = 8.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            leading?.let {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    content = it,
                )
            }
            BasicTextField(
                value = value,
                onValueChange = onValueChange,
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 8.dp),
                enabled = enabled,
                textStyle = MaterialTheme.typography.bodyLarge.copy(color = colors.textPrimary),
                cursorBrush = SolidColor(colors.accent),
                minLines = minLines,
                maxLines = maxLines,
                keyboardOptions = keyboardOptions,
                keyboardActions = keyboardActions,
                decorationBox = { innerTextField ->
                    Box {
                        if (value.isEmpty()) {
                            Text(
                                text = placeholder,
                                style = MaterialTheme.typography.bodyLarge,
                                color = colors.textTertiary,
                                maxLines = maxLines,
                            )
                        }
                        innerTextField()
                    }
                },
            )
            trailing?.let {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    content = it,
                )
            }
        }
    }
}

/** Single-line field with a floating label, used across the contact/profile editors. */
@Composable
fun GlassLabeledField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    singleLine: Boolean = true,
    maxLines: Int = 4,
    supportingText: String? = null,
    keyboardOptions: KeyboardOptions = KeyboardOptions(
        capitalization = KeyboardCapitalization.Sentences,
    ),
    trailing: (@Composable RowScope.() -> Unit)? = null,
) {
    val colors = LocalGlassColors.current
    Column(modifier.fillMaxWidth()) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = colors.textTertiary,
            modifier = Modifier.padding(start = 6.dp, bottom = 6.dp),
        )
        GlassTextField(
            value = value,
            onValueChange = onValueChange,
            placeholder = placeholder,
            minLines = 1,
            maxLines = if (singleLine) 1 else maxLines,
            keyboardOptions = keyboardOptions,
            trailing = trailing,
            modifier = Modifier.fillMaxWidth(),
        )
        if (supportingText != null) {
            Text(
                text = supportingText,
                style = MaterialTheme.typography.labelSmall,
                color = colors.textTertiary,
                modifier = Modifier.padding(start = 6.dp, top = 6.dp),
            )
        }
    }
}

/** Search box used by Chats, Contacts and in-chat search. */
@Composable
fun GlassSearchField(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "Search",
    onClear: () -> Unit = { onQueryChange("") },
) {
    val colors = LocalGlassColors.current
    GlassTextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = placeholder,
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = placeholder },
        leading = {
            Icon(
                imageVector = Icons.Filled.Search,
                contentDescription = null,
                tint = colors.textTertiary,
                modifier = Modifier
                    .padding(start = 8.dp)
                    .size(19.dp),
            )
            Spacer(Modifier.width(4.dp))
        },
        trailing = {
            if (query.isNotEmpty()) {
                GlassIconButton(
                    icon = Icons.Filled.Close,
                    contentDescription = "Clear search",
                    tint = colors.textSecondary,
                    background = null,
                    size = 32.dp,
                    onClick = onClear,
                )
            }
        },
    )
}
