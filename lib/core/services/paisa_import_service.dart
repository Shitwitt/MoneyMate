// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Tink contributors
// The decoder used here adapts Paisa's GPL-licensed 6.3.6 JSON model factories.

import 'dart:convert';
import 'dart:typed_data';

import '../data/seed.dart';
import '../data/validation.dart';
import '../models/models.dart';
import '../utils/money.dart';
import '../utils/constants.dart';
import 'paisa_legacy_decoder.dart';

export '../utils/constants.dart' show maxLegacyImportBytes;

enum LegacyDebtMapping { debitIsBorrowed, debitIsLent }

class PaisaImportPreview {
  final ProfileData profile;
  final int sourceCategories, repayments, roundedAmounts;
  final List<String> warnings;
  const PaisaImportPreview({
    required this.profile,
    required this.sourceCategories,
    required this.repayments,
    required this.roundedAmounts,
    required this.warnings,
  });
}

/// Validation and conversion only. No storage, deletion, notifications or I/O.
class PaisaImportService {
  static Paisa636Data decode(Uint8List bytes) {
    require(
      bytes.isNotEmpty && bytes.length <= maxLegacyImportBytes,
      'Choose an uncompressed Paisa 6.3.6 JSON file up to 10 MiB.',
    );
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const FormatException(
        'The file is not valid UTF-8 JSON. No data was changed.',
      );
    }
    require(decoded is Map<String, dynamic>, 'Expected a legacy JSON object.');
    return Paisa636Data.fromJson(decoded as Map<String, dynamic>);
  }

  static PaisaImportPreview inspect(
    Uint8List bytes, {
    required String name,
    required String currency,
    LegacyDebtMapping? debtMapping,
    bool keepOriginal = true,
  }) {
    require(
      currencySymbols.containsKey(currency),
      'Choose the original backup currency.',
    );
    final source = decode(bytes);
    require(source.accounts.isNotEmpty, 'The legacy backup has no accounts.');
    require(
      source.debts.every((debt) => debt.type == 'goal') || debtMapping != null,
      'Confirm how the old Debt and Credit labels map to Borrowed and Lent.',
    );
    final prefix = uuid.v4();
    String id(String kind, int legacy) => '$prefix-$kind-$legacy';
    void unique(Iterable<int> ids, String kind) {
      final values = ids.toList();
      require(
        values.toSet().length == values.length,
        'Duplicate legacy $kind IDs. No data was changed.',
      );
    }

    unique(source.accounts.map((v) => v.id), 'account');
    unique(source.categories.map((v) => v.id), 'category');
    unique(source.transactions.map((v) => v.id), 'transaction');
    unique(source.debts.map((v) => v.id), 'debt/goal');
    unique(source.payments.map((v) => v.id), 'repayment');
    var rounded = 0;
    var grossMinor = 0;
    int minor(num value, {bool positive = false, bool signed = false}) {
      require(
        signed || value >= 0,
        'A negative legacy transaction or repayment needs manual review.',
      );
      final result = toMinor(value, currency);
      require(
        grossMinor <= 9007199254740991 - result.abs(),
        'Combined legacy amounts exceed the exact-integer safety limit. Import smaller, reviewed history instead.',
      );
      grossMinor += result.abs();
      require(
        !positive || result > 0,
        'A legacy amount is zero after currency rounding. Check the selected currency.',
      );
      if ((fromMinor(result, currency) - value).abs() > .00000001) rounded++;
      return result;
    }

    final accountsById = {for (final value in source.accounts) value.id: value};
    final categoriesById = {
      for (final value in source.categories) value.id: value,
    };
    final debtsById = {for (final value in source.debts) value.id: value};
    for (final event in source.payments) {
      final parent = debtsById[event.parentId];
      require(
        parent != null && (parent.type == 'goal') == (event.type == 'goal'),
        'A legacy repayment has a missing or mismatched parent.',
      );
    }
    final categories = <Category>[
      for (final value in source.categories)
        Category(
          id: id('category', value.id),
          name: value.name,
          type: value.type,
          color: value.color,
          icon: value.type == 'income' ? 'income' : 'category',
        ),
    ];
    final typedCategories = <String, String>{
      for (final value in source.categories)
        '${value.id}:${value.type}': id('category', value.id),
    };
    var splitCategories = 0;
    String category(int legacyId, String type) {
      final value = categoriesById[legacyId];
      require(
        value != null,
        'A legacy transaction refers to a missing category.',
      );
      final key = '$legacyId:$type';
      if (typedCategories.containsKey(key)) return typedCategories[key]!;
      final categoryId = '$prefix-category-$legacyId-$type';
      categories.add(
        Category(
          id: categoryId,
          name: '${value!.name} ($type)',
          type: type,
          color: value.color,
        ),
      );
      typedCategories[key] = categoryId;
      splitCategories++;
      return categoryId;
    }

    final transactions = <MoneyTransaction>[];
    for (final value in source.transactions) {
      final transfer = value.type == 'transfer';
      final from = transfer ? value.fromAccountId : value.accountId;
      require(
        accountsById.containsKey(from),
        'A legacy transaction refers to a missing account.',
      );
      if (transfer) {
        require(
          accountsById.containsKey(value.toAccountId) &&
              from != value.toAccountId,
          'A legacy transfer needs two different saved accounts.',
        );
      }
      final amount = minor(value.amount, positive: true);
      transactions.add(
        MoneyTransaction(
          id: id('transaction', value.id),
          name: value.name,
          type: value.type,
          amountMinor: amount,
          accountId: id('account', from!),
          date: value.date,
          categoryId: transfer ? '' : category(value.categoryId, value.type),
          toAccountId: transfer ? id('account', value.toAccountId!) : '',
          toAmountMinor: transfer ? amount : 0,
          notes: value.description,
        ),
      );
    }
    for (final type in ['expense', 'income']) {
      if (!categories.any((category) => category.type == type)) {
        categories.add(
          Category(
            id: '$prefix-fallback-$type',
            name: 'Imported $type',
            type: type,
          ),
        );
      }
    }
    List<MoneyEvent> events(LegacyDebt debt) => [
      for (final value in source.payments.where(
        (event) => event.parentId == debt.id,
      ))
        MoneyEvent(
          id: id('payment', value.id),
          amountMinor: minor(value.amount),
          date: value.date,
          note: 'Imported legacy record; no new cash transaction was created.',
        ),
    ];
    final profile =
        seedProfile(
          name: name.trim(),
          currency: currency,
          accountName: 'Import',
        ).copyWith(
          profile: Profile(
            id: '$prefix-profile',
            name: name.trim(),
            currency: currency,
            createdAt: DateTime.now(),
          ),
          accounts: [
            for (final value in source.accounts)
              Account(
                id: id('account', value.id),
                name: value.name,
                currency: currency,
                type: value.type,
                openingMinor: minor(value.opening, signed: true),
                color: value.color,
                excluded: value.excluded,
                icon: value.type == 'cash' ? 'cash' : 'bank',
                notes: value.bankName.isEmpty
                    ? ''
                    : 'Legacy bank label: ${value.bankName}',
              ),
          ],
          categories: categories,
          transactions: transactions,
          goals: [
            for (final value in source.debts.where(
              (debt) => debt.type == 'goal',
            ))
              Goal(
                id: id('goal', value.id),
                name: value.name,
                targetMinor: minor(value.amount, positive: true),
                deadline: value.end,
                start: value.start,
                color: value.color,
                archived: value.completed,
                contributions: events(value),
              ),
          ],
          loans: [
            for (final value in source.debts.where(
              (debt) => debt.type != 'goal',
            ))
              Loan(
                id: id('loan', value.id),
                personName: value.name,
                principalMinor: minor(value.amount, positive: true),
                due: value.end,
                start: value.start,
                color: value.color,
                completed: value.completed,
                direction:
                    (value.type == 'debit') ==
                        (debtMapping == LegacyDebtMapping.debitIsBorrowed)
                    ? 'borrowed'
                    : 'lent',
                notes: value.description,
                repayments: events(value),
              ),
          ],
          legacyImportJson: keepOriginal ? utf8.decode(bytes) : '',
        );
    validateProfile(profile);
    return PaisaImportPreview(
      profile: profile,
      sourceCategories: source.categories.length,
      repayments: source.payments.length,
      roundedAmounts: rounded,
      warnings: [
        'Every account uses $currency: this legacy schema stored no per-account currency. Transfers keep the same amount on both sides; no FX rate is invented.',
        'Only a NEW profile is created. Existing profiles and the app lock stay intact. Silent link posting and notifications are switched off for review.',
        'Legacy payment/contribution records are imported as history only, not new cash transactions. Completed loans stay manually closed; completed legacy goals become archived.',
        'Old icon codes are replaced by Tink icons. Category descriptions, icon codes and other original fields ${keepOriginal ? 'are retained in the downloadable original JSON stored with this profile' : 'remain only in your original file; keep it safe'}.',
        if (source.categories.any((v) => v.isBudget || v.budget != 0))
          'Legacy category caps are not activated as Tink budgets: the export did not specify their date windows. Recreate them after review; original values are retained in your source file.',
        if (splitCategories > 0)
          '$splitCategories category/type combinations were split so income and expense history remain valid.',
        if (rounded > 0)
          '$rounded amounts were rounded to the selected currency’s minor-unit precision. Review the totals before importing.',
        'This is compatibility with the verified 6.3.6 export schema, not a claim to import official 2026 Paisa backups, attachments, cloud data or settings.',
      ],
    );
  }
}
