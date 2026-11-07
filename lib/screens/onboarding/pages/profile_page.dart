import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/avatars.dart';
import '../../../core/l10n/app_strings.dart';

/// Page 2 — name + avatar.
///
/// Avatars are the twelve built-in illustrated tiles; "Use a photo" additionally
/// lets the user pick an image, which is **copied into the app's documents
/// directory** so the reference survives cache eviction and reboots.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.initialName,
    required this.avatarIndex,
    required this.customImagePath,
    required this.onChanged,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onContinue,
    required this.onBack,
  });

  final String initialName;
  final int avatarIndex;
  final String? customImagePath;

  /// Called on every keystroke / avatar tap so the parent keeps the draft.
  final void Function({String? name, int? avatarIndex}) onChanged;

  /// Must return the persisted image path (or `null` when cancelled).
  final Future<String?> Function() onPickImage;
  final VoidCallback onRemoveImage;

  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final String name = _nameController.text.trim();
    widget.onChanged(name: name);
    if (name.isEmpty) {
      // The validator message already explains the requirement.
      _formKey.currentState?.validate();
      return;
    }
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool hasPhoto = widget.customImagePath != null &&
        widget.customImagePath!.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                  const Spacer(),
                  Text(
                    '2 / 5',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        context.tr('profileTitle'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---------------- Avatar preview + name ----------------
                      Row(
                        children: <Widget>[
                          _AvatarPreview(
                            imagePath: hasPhoto ? widget.customImagePath : null,
                            avatar: Avatars.byIndex(widget.avatarIndex),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              maxLength: 32,
                              autofocus: true,
                              onChanged: (String value) =>
                                  widget.onChanged(name: value),
                              onFieldSubmitted: (_) => _submit(),
                              style: theme.textTheme.titleMedium,
                              decoration: InputDecoration(
                                labelText: context.tr('profileName'),
                                hintText: context.tr('profileNameHint'),
                                prefixIcon:
                                    const Icon(Icons.person_outline_rounded),
                                counterText: '',
                              ),
                              validator: (String? value) {
                                final String text = (value ?? '').trim();
                                if (text.isEmpty) {
                                  return context.tr('nameRequired');
                                }
                                if (text.length > 32) {
                                  return context.tr('nameTooLong');
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ---------------- Avatar grid ----------------
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              context.tr('chooseAvatar'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (hasPhoto)
                            TextButton.icon(
                              onPressed: widget.onRemoveImage,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: Text(context.tr('removePhoto')),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: Avatars.count + 1, // + photo tile
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          if (index == Avatars.count) {
                            return _PhotoTile(
                              imagePath: hasPhoto ? widget.customImagePath : null,
                              onTap: () async {
                                final String? path = await widget.onPickImage();
                                if (path != null) {
                                  widget.onChanged();
                                }
                              },
                            );
                          }
                          final PaisaAvatar avatar = Avatars.all[index];
                          final bool selected = !hasPhoto &&
                              widget.avatarIndex == index;
                          return _AvatarTile(
                            avatar: avatar,
                            selected: selected,
                            onTap: () {
                              widget.onChanged(avatarIndex: index);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        hasPhoto
                            ? 'Your photo is stored only on this device.'
                            : 'Pick a tile — you can change it any time in Settings.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(context.tr('onboardingNext')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large circular preview of the current selection.
class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.imagePath, required this.avatar});

  final String? imagePath;
  final PaisaAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage ? null : LinearGradient(colors: avatar.gradient),
        border: Border.all(color: scheme.primary, width: 2.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? _LocalImage(path: imagePath!, fit: BoxFit.cover)
          : Icon(avatar.icon, size: 40, color: avatar.foreground),
    );
  }
}

/// One selectable avatar in the grid.
class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatar,
    required this.selected,
    required this.onTap,
  });

  final PaisaAvatar avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: avatar.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: avatar.gradient),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2.4,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(avatar.icon, size: 30, color: avatar.foreground),
              if (selected)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "+ photo" tile at the end of the avatar grid.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.imagePath, required this.onTap});

  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool hasImage = imagePath != null && imagePath!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasImage ? scheme.primary : scheme.outlineVariant,
            width: hasImage ? 2.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? _LocalImage(path: imagePath!, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Photo',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Renders a file from the local filesystem, with a graceful placeholder when
/// the file was deleted outside the app.
class _LocalImage extends StatelessWidget {
  const _LocalImage({required this.path, required this.fit});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Center(child: Icon(Icons.image_not_supported_outlined));
    }
    final File file = File(path);
    return Image.file(
      file,
      fit: fit,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.person_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

/// Copies a picked image into the app documents directory and returns the new
/// path, or `null` when the user cancels.
///
/// Kept here (rather than in the screen) so it is unit-testable and reusable
/// from Settings › Profile later.
Future<String?> pickAndPersistAvatar() async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: kIsWeb,
  );
  if (result == null || result.files.isEmpty) return null;

  final PlatformFile file = result.files.first;
  if (kIsWeb) {
    // The web picker hands back a blob URL; there is no documents directory to
    // copy into, so it is used as-is (and forgotten on reload).
    return file.path;
  }
  final String? sourcePath = file.path;
  if (sourcePath == null || sourcePath.isEmpty) return null;

  final Directory documents = await getApplicationDocumentsDirectory();
  final Directory avatarsDir = Directory('${documents.path}/avatars');
  if (!avatarsDir.existsSync()) {
    avatarsDir.createSync(recursive: true);
  }
  final String extension = sourcePath.contains('.')
      ? sourcePath.substring(sourcePath.lastIndexOf('.'))
      : '.jpg';
  final String target =
      '${avatarsDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}$extension';
  await File(sourcePath).copy(target);
  return target;
}
