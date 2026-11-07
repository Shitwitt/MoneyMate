import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Local, offline file I/O for backups and spreadsheet exports.
///
/// Everything here is real device I/O — a JSON/CSV document is written into the
/// app's own temporary directory and handed to the platform share sheet through
/// `share_plus`, and a restore reads the picked file's bytes through
/// `file_picker`. No network, no mock, and no permission beyond what the picker
/// and the share sheet already own.
class BackupService {
  const BackupService._();

  /// `paisa_backup_20261107.json`
  static String backupFileName([DateTime? now]) =>
      'paisa_backup_${_stamp(now ?? DateTime.now())}.json';

  /// `paisa_transactions_20261107.csv`
  static String csvFileName([DateTime? now]) =>
      'paisa_transactions_${_stamp(now ?? DateTime.now())}.csv';

  static String _stamp(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}';

  /// Writes [content] next to the app's temporary files and returns the path.
  ///
  /// Returns `null` on web, where there is no writable filesystem — callers
  /// fall back to [shareDocument], which shares in-memory bytes instead.
  static Future<String?> writeTemporaryFile(
    String fileName,
    String content,
  ) async {
    if (kIsWeb) return null;
    final Directory directory = await getTemporaryDirectory();
    final Directory exports = Directory('${directory.path}/moneymate_exports');
    if (!exports.existsSync()) {
      await exports.create(recursive: true);
    }
    final File file = File('${exports.path}/$fileName');
    await file.writeAsString(content, flush: true);
    return file.path;
  }

  /// Shares a text document (JSON backup or CSV) through the platform sheet.
  ///
  /// Returns `true` when the sheet reported a share, `false` when the user
  /// dismissed it. Throws [PlatformException] style errors upward so the UI can
  /// show the real reason instead of pretending it worked.
  static Future<bool> shareDocument({
    required String fileName,
    required String content,
    required String mimeType,
    required String subject,
    Rect? sharePositionOrigin,
  }) async {
    final String? path = await writeTemporaryFile(fileName, content);
    final List<XFile> files = <XFile>[
      if (path != null)
        XFile(path, mimeType: mimeType, name: fileName)
      else
        XFile.fromData(
          utf8.encode(content),
          mimeType: mimeType,
          name: fileName,
        ),
    ];
    final ShareResult result = await Share.shareXFiles(
      files,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
    return result.status != ShareResultStatus.dismissed;
  }

  /// Shares the full backup document.
  static Future<bool> shareBackup(
    String json, {
    Rect? sharePositionOrigin,
  }) {
    return shareDocument(
      fileName: backupFileName(),
      content: json,
      mimeType: 'application/json',
      subject: 'MoneyMate backup',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Shares the ledger as a spreadsheet-ready CSV.
  static Future<bool> shareCsv(String csv, {Rect? sharePositionOrigin}) {
    return shareDocument(
      fileName: csvFileName(),
      content: csv,
      mimeType: 'text/csv',
      subject: 'MoneyMate transactions',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Lets the user pick a `.json` backup and returns its text, or `null` when
  /// the picker was dismissed.
  ///
  /// The bytes are read through the picker so the flow works identically on
  /// Android, iOS, desktop and web (where there is no readable path).
  static Future<String?> pickBackupJson() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final PlatformFile file = result.files.first;
    if (file.bytes != null) return utf8.decode(file.bytes!, allowMalformed: true);

    final String? path = file.path;
    if (path == null || path.isEmpty) {
      throw const FormatException('That file could not be read.');
    }
    return File(path).readAsString();
  }

  /// Human size label for the "last export" line, e.g. `12.4 KB`.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}
