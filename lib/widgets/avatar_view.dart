import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants/avatars.dart';

/// Renders the user's avatar: their picked photo when one exists and still
/// resolves on disk, otherwise the selected built-in tile.
///
/// Every avatar surface in the app goes through this widget so the "photo
/// deleted outside the app" case degrades to the tile instead of a broken
/// image box.
class PaisaAvatarView extends StatelessWidget {
  const PaisaAvatarView({
    super.key,
    required this.avatarIndex,
    this.imagePath,
    this.size = 48,
    this.borderWidth = 0,
    this.borderColor,
  });

  /// Index into [Avatars.all].
  final int avatarIndex;

  /// Absolute path of a user photo, if any.
  final String? imagePath;

  /// Diameter of the circle.
  final double size;

  /// Ring thickness drawn around the avatar (`0` for none).
  final double borderWidth;

  /// Ring colour; defaults to the theme's primary.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final PaisaAvatar avatar = Avatars.byIndex(avatarIndex);
    final bool hasImage = imagePath != null && imagePath!.trim().isNotEmpty;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage ? null : LinearGradient(colors: avatar.gradient),
        color: hasImage ? scheme.surfaceContainerHighest : null,
        border: borderWidth <= 0
            ? null
            : Border.all(
                color: borderColor ?? scheme.primary,
                width: borderWidth,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? _AvatarFile(path: imagePath!, avatar: avatar)
          : Icon(avatar.icon, size: size * 0.5, color: avatar.foreground),
    );
  }
}

/// Loads the photo from disk and falls back to the tile when it is gone.
class _AvatarFile extends StatelessWidget {
  const _AvatarFile({required this.path, required this.avatar});

  final String path;
  final PaisaAvatar avatar;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Icon(avatar.icon, size: 24, color: avatar.foreground);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: avatar.gradient),
          ),
          child: Icon(avatar.icon, color: avatar.foreground),
        );
      },
    );
  }
}
