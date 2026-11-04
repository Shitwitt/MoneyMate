import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paisaclone/core/data/local_store.dart';
import 'package:paisaclone/core/data/seed.dart';
import 'package:paisaclone/core/data/validation.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/services/backup_service.dart';
import 'package:paisaclone/core/services/csv_service.dart';
import 'package:paisaclone/core/services/deep_link_service.dart';
import 'package:paisaclone/core/services/security_service.dart';
import 'support.dart';

void main() {
  test('Every seeded model round trips, including two profiles', () {
    final first = seedProfile(
      name: 'Demo',
      currency: 'INR',
      accountName: 'Everyday',
      demo: true,
      clock: DateTime(2026, 11, 4),
    );
    final second = fixture();
    final app = appFor(first).copyWith(profiles: [first, second]);
    final restored = AppData.fromJson(
      readMap(jsonDecode(jsonEncode(app.toJson()))),
    );
    validateData(restored);
    expect(restored.toJson(), app.toJson());
  });
  test('JSON and ZIP backups retain data and receipts, omit PIN secrets', () {
    var data = fixture();
    const receipt = Receipt(
      id: 'receipt',
      name: 'tiny.png',
      mime: 'image/png',
      data:
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aG1cAAAAASUVORK5CYII=',
    );
    data = data.copyWith(
      transactions: [
        expense(data).copyWith(receipts: [receipt]),
      ],
    );
    final app = appFor(
      data,
      settings: const AppSettings(
        lockMode: 'pin',
        pinHash: 'private hash',
        pinSalt: 'private salt',
      ),
    );
    for (final zip in [false, true]) {
      final bytes = BackupService.export(app, zip: zip),
          preview = BackupService.inspect(
            BackupService.export(app, zip: zip),
            zip ? 'backup.zip' : 'backup.json',
          );
      expect(bytes, isNotEmpty);
      expect(preview.receipts, 1);
      expect(
        preview.data.profiles.first.transactions.single.receipts.single.data,
        receipt.data,
      );
      expect(preview.data.settings.pinHash, isEmpty);
      expect(preview.data.settings.pinSalt, isEmpty);
      expect(preview.data.settings.lockMode, 'none');
    }
  });
  test('Damaged checksums and future schemas cannot restore', () {
    final json = readMap(
      jsonDecode(
        utf8.decode(BackupService.export(appFor(fixture()), zip: false)),
      ),
    );
    json['checksum'] = 'tampered';
    expect(
      () => BackupService.inspect(
        Uint8List.fromList(utf8.encode(jsonEncode(json))),
        'backup.json',
      ),
      throwsFormatException,
    );
    expect(
      () => validateData(appFor(fixture()).copyWith(schemaVersion: 999)),
      throwsFormatException,
    );
  });
  test('A local Hive snapshot persists after closing and reopening', () async {
    final dir = await Directory.systemTemp.createTemp('paisa-test-');
    Hive.init(dir.path);
    final data = fixture();
    final app = appFor(data.copyWith(transactions: [expense(data)]));
    var box = await Hive.openBox<String>('test');
    await LocalStore(box, const AppData()).save(app);
    await box.close();
    box = await Hive.openBox<String>('test');
    final reloaded = AppData.fromJson(readMap(jsonDecode(box.get('state')!)));
    expect(reloaded.toJson(), app.toJson());
    await box.close();
    await dir.delete(recursive: true);
  });
  test('CSV mapper validates rows and deduplicates deterministic IDs', () {
    final data = fixture();
    final csv = CsvDocument.parse(
      Uint8List.fromList(
        utf8.encode(
          'date,type,name,amount,account,category\n2026-01-02,expense,Coffee,4.50,Everyday,Food & Dining\nwrong,expense,Bad,5,Everyday,Food & Dining\n2026-01-02,expense,Coffee,4.50,Everyday,Food & Dining\n',
        ),
      ),
    );
    final mapping = {
      for (var i = 0; i < csv.headers.length; i++) csv.headers[i]: i,
    };
    final result = csv.preview(data, mapping);
    expect(result.valid.length, 1);
    expect(result.errors.length, 1);
    expect(result.duplicates, 1);
    expect(
      csv.preview(data.copyWith(transactions: result.valid), mapping).valid,
      isEmpty,
    );
  });
  test('CSV export neutralizes spreadsheet formulas', () {
    expect(CsvService.safeCell('=IMPORTXML("bad")'), startsWith("'="));
    expect(CsvService.safeCell('Coffee'), 'Coffee');
  });
  test(
    'Deep links resolve names, validate types, and preserve silence request',
    () {
      final data = fixture();
      final request = DeepLinkService.parse(
        Uri.parse(
          'paisa://silent_add?amount=4.50&type=expense&name=Coffee&account=Everyday&category=Food%20%26%20Dining',
        ),
        data,
      );
      expect(request.silent, isTrue);
      expect(request.transaction!.amountMinor, 450);
      expect(
        DeepLinkService.parse(Uri.parse('paisa://quick_add'), data).transaction,
        isNull,
      );
      expect(
        () => DeepLinkService.parse(
          Uri.parse('paisa://add?amount=1&type=transfer'),
          data,
        ),
        throwsFormatException,
      );
      expect(
        () => DeepLinkService.parse(Uri.parse('paisa://add?amount=-5'), data),
        throwsA(anything),
      );
      expect(
        () => DeepLinkService.parse(
          Uri.parse('paisa://add?amount=1&account=Missing'),
          data,
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'PINs use independently salted PBKDF2 and constant-result verification',
    () async {
      final a = await SecurityService.createPin('123456');
      final b = await SecurityService.createPin('123456');
      expect(a.$1, isNot(b.$1));
      expect(a.$2, isNot(b.$2));
      expect(await SecurityService.verifyPin('123456', a.$1, a.$2), isTrue);
      expect(await SecurityService.verifyPin('123455', a.$1, a.$2), isFalse);
      expect(await SecurityService.verifyPin('123', a.$1, a.$2), isFalse);
    },
  );
}
