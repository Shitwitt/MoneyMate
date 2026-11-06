import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/data/ledger.dart';
import 'package:paisaclone/core/data/providers.dart';
import 'package:paisaclone/core/data/validation.dart';
import 'package:paisaclone/core/models/models.dart';
import 'package:paisaclone/core/services/backup_service.dart';
import 'package:paisaclone/core/services/paisa_import_service.dart';

import 'fixtures/paisa_636.dart';
import 'support.dart';

PaisaImportPreview inspectLegacy({
  Json? data,
  String currency = 'USD',
  bool keepOriginal = true,
  LegacyDebtMapping? mapping = LegacyDebtMapping.debitIsBorrowed,
}) => PaisaImportService.inspect(
  legacyBytes(data),
  name: 'Imported history',
  currency: currency,
  debtMapping: mapping,
  keepOriginal: keepOriginal,
);

void main() {
  test(
    'Actual exporter key preserves all repayments, goals and signed balances',
    () {
      final preview = inspectLegacy();
      final data = preview.profile;
      final ledger = Ledger(data, const AppSettings());
      validateProfile(data);
      expect(data.accounts.length, 2);
      expect(
        data.transactions.length,
        3,
      ); // No duplicate cash entries for repayments.
      expect(data.loans.length, 2);
      expect(data.goals.length, 1);
      expect(preview.repayments, 3);
      expect(data.accounts[1].openingMinor, -500);
      expect(ledger.accountBalance(data.accounts[0].id), 10250);
      expect(ledger.accountBalance(data.accounts[1].id), 1000);
      expect(ledger.accountsTotal, 11250);
      expect(data.transactions.first.notes, 'A retained transaction note');
      expect(data.accounts.first.notes, contains('Local label'));
      final transfer = data.transactions.singleWhere(
        (e) => e.type == 'transfer',
      );
      expect(transfer.amountMinor, 1500);
      expect(transfer.toAmountMinor, 1500);
      final borrowed = data.loans.singleWhere(
        (loan) => loan.personName == 'Alex',
      );
      expect(borrowed.direction, 'borrowed');
      expect(borrowed.completed, isTrue);
      expect(borrowed.repayments.single.amountMinor, 2500);
      expect(borrowed.repayments.single.transactionId, isEmpty);
      expect(ledger.loanUnpaid(borrowed), 7500);
      expect(
        ledger.loanRemaining(borrowed),
        0,
      ); // Manual closure is not a fake payment.
      expect(data.goals.single.contributions.single.amountMinor, 5000);
      expect(
        data.budgets,
        isEmpty,
      ); // No guessed date window for old category caps.
      expect(preview.warnings.join(' '), contains('not activated'));
      expect(jsonDecode(data.legacyImportJson), legacy636Fixture());
      expect(preview.roundedAmounts, 0);
    },
  );

  test(
    'The old parser key also works, but simultaneous populated arrays fail',
    () {
      final data = legacy636Fixture();
      data['debitTransactions'] = data.remove('transactions');
      expect(inspectLegacy(data: data).repayments, 3);
      data['transactions'] = data['debitTransactions'];
      expect(() => inspectLegacy(data: data), throwsFormatException);
    },
  );

  test('Missing currency or loan-direction confirmation is not guessed', () {
    expect(() => inspectLegacy(currency: ''), throwsFormatException);
    expect(() => inspectLegacy(mapping: null), throwsFormatException);
    final opposite = inspectLegacy(
      mapping: LegacyDebtMapping.debitIsLent,
    ).profile;
    expect(
      opposite.loans.singleWhere((v) => v.personName == 'Alex').direction,
      'lent',
    );
    expect(
      opposite.loans.singleWhere((v) => v.personName == 'Jules').direction,
      'borrowed',
    );
    final goalsOnly = legacy636Fixture();
    goalsOnly['debts'] = (goalsOnly['debts'] as List)
        .where((d) => d['debtType'] == 'goal')
        .toList();
    goalsOnly['transactions'] = (goalsOnly['transactions'] as List)
        .where((p) => p['type'] == 'goal')
        .toList();
    expect(
      inspectLegacy(data: goalsOnly, mapping: null).profile.goals.length,
      1,
    );
  });

  test(
    'Repeated previews use fresh profile and entity IDs without mutating input',
    () {
      final source = legacy636Fixture(),
          original = jsonEncode(legacy636Fixture());
      final first = inspectLegacy(data: source).profile,
          second = inspectLegacy(data: source).profile;
      expect(first.profile.id, isNot(second.profile.id));
      expect(
        first.accounts
            .map((v) => v.id)
            .toSet()
            .intersection(second.accounts.map((v) => v.id).toSet()),
        isEmpty,
      );
      expect(jsonEncode(source), original);
    },
  );

  test('Optional original archive survives both Tink backup formats', () {
    final data = inspectLegacy().profile;
    for (final zip in [false, true]) {
      final bytes = BackupService.export(appFor(data), zip: zip);
      final restored = BackupService.inspect(
        bytes,
        zip ? 'backup.zip' : 'backup.json',
      ).data.profiles.single;
      expect(restored.toJson(), data.toJson());
      expect(restored.legacyImportJson, utf8.decode(legacyBytes()));
    }
    expect(
      inspectLegacy(keepOriginal: false).profile.legacyImportJson,
      isEmpty,
    );
    final oldSchema = fixture().toJson()..remove('legacyImportJson');
    expect(ProfileData.fromJson(oldSchema).legacyImportJson, isEmpty);
  });

  test(
    'Currency precision is disclosed and a rounded-to-zero transaction is rejected',
    () {
      final jpy = inspectLegacy(currency: 'JPY');
      expect(jpy.profile.transactions.first.amountMinor, 3);
      expect(jpy.roundedAmounts, 1);
      expect(jpy.warnings.join(' '), contains('rounded'));
      final data = legacy636Fixture();
      data['expenses'][0]['currency'] = .01;
      expect(
        () => inspectLegacy(data: data, currency: 'JPY'),
        throwsFormatException,
      );
    },
  );

  test(
    'Categories used for another record type split without losing either type',
    () {
      final data = legacy636Fixture();
      data['expenses'][1]['categoryId'] = 3;
      final converted = inspectLegacy(data: data).profile;
      final income = converted.transactions.singleWhere(
        (v) => v.type == 'income',
      );
      final expense = converted.transactions.singleWhere(
        (v) => v.type == 'expense',
      );
      expect(income.categoryId, isNot(expense.categoryId));
      expect(
        converted.categories.singleWhere((c) => c.id == income.categoryId).type,
        'income',
      );
      expect(
        converted.categories
            .singleWhere((c) => c.id == expense.categoryId)
            .type,
        'expense',
      );
      validateProfile(converted);
    },
  );

  final corruptions = <String, void Function(Json)>{
    'unsupported current version': (d) => d['version'] = 'v2026.03.04',
    'unknown collection': (d) => d['new2026Feature'] = [],
    'missing account': (d) => d['expenses'][0]['accountId'] = 999,
    'missing category': (d) => d['expenses'][0]['categoryId'] = 999,
    'same-account transfer': (d) => d['expenses'][2]['toAccountId'] = 0,
    'missing transfer source': (d) => d['expenses'][2]['fromAccountId'] = -1,
    'negative transaction': (d) => d['expenses'][0]['currency'] = -5,
    'zero transaction': (d) => d['expenses'][0]['currency'] = 0,
    'fractional ID': (d) => d['accounts'][0]['superId'] = .5,
    'missing ID': (d) => d['accounts'][0].remove('superId'),
    'duplicate account': (d) => d['accounts'].add(d['accounts'][0]),
    'duplicate category': (d) => d['categories'].add(d['categories'][0]),
    'duplicate transaction': (d) => d['expenses'].add(d['expenses'][0]),
    'duplicate debt': (d) => d['debts'].add(d['debts'][0]),
    'duplicate repayment': (d) => d['transactions'].add(d['transactions'][0]),
    'orphan repayment': (d) => d['transactions'][0]['parentId'] = 999,
    'goal/loan mismatch': (d) => d['transactions'][0]['type'] = 'goal',
    'negative repayment': (d) => d['transactions'][0]['amount'] = -2,
    'overpaid loan': (d) => d['transactions'][0]['amount'] = 101,
    'invalid calendar day': (d) =>
        d['expenses'][0]['time'] = '2026-02-31T10:00:00',
    'invalid clock hour': (d) =>
        d['expenses'][0]['time'] = '2026-01-05T25:00:00',
    'invalid timezone': (d) =>
        d['expenses'][0]['time'] = '2026-01-05T12:00:00+04:99',
    'unknown enum': (d) => d['expenses'][0]['type'] = 'refund',
    'wrong boolean type': (d) =>
        d['accounts'][0]['isAccountExcluded'] = 'false',
    'oversized numeric amount': (d) =>
        d['expenses'][0]['currency'] = 1000000000001,
  };
  for (final entry in corruptions.entries) {
    test('Reject ${entry.key} before a profile can be written', () {
      final data = legacy636Fixture();
      entry.value(data);
      expect(() => inspectLegacy(data: data), throwsFormatException);
    });
  }

  test('Combined amounts stay within exact web integer precision', () {
    final data = legacy636Fixture();
    data['expenses'] = [
      for (var i = 0; i < 100; i++)
        {
          ...(data['expenses'][0] as Map<String, dynamic>),
          'superId': i + 1000,
          'currency': 1000000000000,
        },
    ];
    expect(() => inspectLegacy(data: data), throwsFormatException);
  });

  test(
    'Malformed, empty, oversized and non-object JSON fail without content echo',
    () {
      for (final bytes in [
        Uint8List(0),
        Uint8List(maxLegacyImportBytes + 1),
        Uint8List.fromList([255, 254]),
        Uint8List.fromList(utf8.encode('{"private":"secret invalid json')),
        Uint8List.fromList(utf8.encode('[]')),
      ]) {
        expect(() => PaisaImportService.decode(bytes), throwsFormatException);
      }
      try {
        PaisaImportService.decode(
          Uint8List.fromList(utf8.encode('{"private":"secret invalid json')),
        );
      } on FormatException catch (error) {
        expect(error.message, isNot(contains('secret')));
      }
    },
  );

  test(
    'Import is durable-before-visible, retains old profile and lock, then rejects double save',
    () async {
      final before = appFor(
        fixture(),
        settings: const AppSettings(
          lockMode: 'pin',
          pinHash: 'retained hash',
          pinSalt: 'retained salt',
          allowSilentAdds: true,
          notificationsEnabled: true,
        ),
      );
      final repo = MemoryRepository(before);
      final app = AppController(repo);
      addTearDown(app.dispose);
      final preview = inspectLegacy();
      expect(repo.writes, 0);
      repo.failNext = true;
      await expectLater(
        app.importLegacyProfile(preview.profile),
        throwsStateError,
      );
      expect(app.snapshot, same(before));
      expect(repo.persisted, isNull);
      expect(repo.writes, 0);
      await app.importLegacyProfile(preview.profile);
      expect(app.snapshot.profiles.length, 2);
      expect(
        app.snapshot.profiles.first.toJson(),
        before.profiles.first.toJson(),
      );
      expect(app.snapshot.activeProfileId, preview.profile.profile.id);
      expect(app.snapshot.settings.pinHash, 'retained hash');
      expect(app.snapshot.settings.pinSalt, 'retained salt');
      expect(app.snapshot.settings.lockMode, 'pin');
      expect(app.snapshot.settings.allowSilentAdds, isFalse);
      expect(app.snapshot.settings.notificationsEnabled, isFalse);
      expect(repo.writes, 1);
      await expectLater(
        app.importLegacyProfile(preview.profile),
        throwsFormatException,
      );
      expect(repo.writes, 1);
      expect(app.snapshot.profiles.length, 2);
    },
  );

  test(
    'Invalid profiles and the profile-count limit cannot partially import',
    () async {
      final initial = appFor(fixture());
      final repo = MemoryRepository(initial);
      final controller = AppController(repo);
      addTearDown(controller.dispose);
      final data = inspectLegacy().profile;
      await expectLater(
        controller.importLegacyProfile(data.copyWith(accounts: [])),
        throwsFormatException,
      );
      expect(controller.snapshot, same(initial));
      expect(repo.writes, 0);
      final many = initial.copyWith(
        profiles: [
          initial.profiles.first,
          for (var i = 0; i < 49; i++)
            initial.profiles.first.copyWith(
              profile: initial.profiles.first.profile.copyWith(
                id: 'profile-$i',
              ),
            ),
        ],
      );
      final fullRepo = MemoryRepository(many);
      final full = AppController(fullRepo);
      addTearDown(full.dispose);
      await expectLater(full.importLegacyProfile(data), throwsFormatException);
      expect(full.snapshot, same(many));
      expect(fullRepo.writes, 0);
    },
  );
}
