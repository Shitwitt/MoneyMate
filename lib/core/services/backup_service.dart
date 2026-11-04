import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import '../data/validation.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class BackupPreview {
  final AppData data;
  final DateTime createdAt;
  const BackupPreview(this.data, this.createdAt);
  int get transactions => data.profiles.fold(
    0,
    (sum, profile) => sum + profile.transactions.length,
  );
  int get receipts => data.profiles.fold(
    0,
    (sum, profile) =>
        sum +
        profile.transactions.fold<int>(
          0,
          (sum, entry) => sum + entry.receipts.length,
        ),
  );
}

class BackupService {
  static Uint8List export(AppData app, {bool zip = true}) {
    // Security secrets are not portable. The current installation retains its lock
    // when restoring; a new installation explicitly sets a new PIN/biometric lock.
    final safe = app.copyWith(
      settings: app.settings.copyWith(
        lockMode: 'none',
        pinHash: '',
        pinSalt: '',
        allowSilentAdds: false,
      ),
    );
    final data = safe.toJson();
    final envelope = {
      'format': 'paisaclone-backup',
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'checksum': sha256.convert(utf8.encode(jsonEncode(data))).toString(),
      'data': data,
    };
    final json = utf8.encode(jsonEncode(envelope));
    if (json.length > maxBackupBytes) {
      throw const FormatException(
        'Backup exceeds 50 MB. Remove some receipts before exporting.',
      );
    }
    if (!zip) return Uint8List.fromList(json);
    final archive = Archive()
      ..addFile(ArchiveFile('paisaclone.json', json.length, json))
      ..addFile(
        ArchiveFile.string(
          'READ-ME.txt',
          'PaisaClone local backup. Includes every profile and embedded receipt. UNENCRYPTED: keep private. Restore from Settings > Backup. PIN hashes are intentionally excluded.',
        ),
      );
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static BackupPreview inspect(Uint8List bytes, String filename) {
    require(
      bytes.length <= maxBackupBytes,
      'Backup exceeds the 50 MB safety limit',
    );
    List<int> content = bytes;
    if (filename.toLowerCase().endsWith('.zip') ||
        (bytes.length > 4 && bytes[0] == 80 && bytes[1] == 75)) {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      require(
        archive.files.length <= 10 &&
            archive.files.fold<int>(0, (sum, file) => sum + file.size) <=
                maxBackupBytes,
        'Archive is too large or has unexpected contents',
      );
      final files = archive.files.where(
        (file) => file.name == 'paisaclone.json' && file.isFile,
      );
      require(files.length == 1, 'This ZIP is not a PaisaClone backup');
      // Never extract arbitrary paths to the filesystem (prevents ZIP traversal).
      content = files.single.content as List<int>;
    }
    final envelope = readMap(jsonDecode(utf8.decode(content)));
    require(
      envelope['format'] == 'paisaclone-backup' && envelope['version'] == 1,
      'Unsupported backup format',
    );
    final dataJson = readMap(envelope['data']);
    require(
      sha256.convert(utf8.encode(jsonEncode(dataJson))).toString() ==
          envelope['checksum'],
      'Backup checksum mismatch. The file may be damaged.',
    );
    final app = AppData.fromJson(dataJson);
    validateData(app);
    return BackupPreview(app, DateTime.parse(envelope['createdAt'] as String));
  }
}
