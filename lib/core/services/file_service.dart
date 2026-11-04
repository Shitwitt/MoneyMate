import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/constants.dart';

class PickedDocument {
  final String name;
  final Uint8List bytes;
  const PickedDocument(this.name, this.bytes);
}

class FileService {
  static Future<PickedDocument?> pick(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > maxBackupBytes) {
      throw const FormatException('File exceeds the 50 MB safety limit');
    }
    final bytes = file.bytes;
    if (bytes == null) {
      throw const FormatException(
        'The system picker could not read this file. Copy it to your device and try again.',
      );
    }
    return PickedDocument(file.name, bytes);
  }

  static Future<void> save(
    Uint8List bytes,
    String name, {
    String mime = 'application/octet-stream',
  }) async {
    if (kIsWeb) {
      await FilePicker.platform.saveFile(fileName: name, bytes: bytes);
    } else {
      // A nonempty rect is required by UIActivityViewController on iPad.
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: name, mimeType: mime)],
        fileNameOverrides: [name],
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );
    }
  }
}
