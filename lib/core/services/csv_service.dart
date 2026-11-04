import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';

import '../data/ledger.dart';
import '../models/models.dart';
import '../utils/money.dart';

class CsvPreview {
  final List<MoneyTransaction> valid;
  final List<String> errors;
  final int duplicates;
  const CsvPreview(this.valid, this.errors, this.duplicates);
}

class CsvDocument {
  final List<String> headers;
  final List<List<dynamic>> rows;
  const CsvDocument(this.headers, this.rows);
  static CsvDocument parse(Uint8List bytes) {
    final text = utf8.decode(bytes).replaceFirst('\ufeff', '');
    final delimiter =
        text.split('\n').first.contains(';') &&
            !text.split('\n').first.contains(',')
        ? ';'
        : ',';
    final rows = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: text.contains('\r\n') ? '\r\n' : '\n',
      shouldParseNumbers: false,
      allowInvalid: false,
    ).convert(text);
    if (rows.length < 2 || rows.length > 50001) {
      throw const FormatException('CSV needs a header and 1–50,000 rows');
    }
    return CsvDocument(
      rows.first.map((item) => item.toString().trim()).toList(),
      rows
          .skip(1)
          .where((row) => row.any((item) => item.toString().trim().isNotEmpty))
          .toList(),
    );
  }

  CsvPreview preview(ProfileData data, Map<String, int> mapping) {
    final valid = <MoneyTransaction>[], errors = <String>[];
    final seen = data.transactions.map((entry) => entry.id).toSet();
    var duplicates = 0;
    String value(List<dynamic> row, String key) {
      final index = mapping[key];
      return index == null || index < 0 || index >= row.length
          ? ''
          : row[index].toString().trim();
    }

    for (var i = 0; i < rows.length; i++) {
      try {
        final row = rows[i];
        final type = value(row, 'type').toLowerCase();
        if (type != 'income' && type != 'expense') {
          throw const FormatException(
            'type must be income or expense (transfers must be entered in-app)',
          );
        }
        final name = value(row, 'name');
        if (name.isEmpty) throw const FormatException('name is required');
        final accountName = value(row, 'account');
        final account = accountName.isEmpty
            ? data.accounts.first
            : data.accounts.firstWhere(
                (item) =>
                    item.name.toLowerCase() == accountName.toLowerCase() ||
                    item.id == accountName,
                orElse: () =>
                    throw FormatException('unknown account "$accountName"'),
              );
        final code = value(row, 'currency');
        if (code.isNotEmpty && code != account.currency) {
          throw FormatException(
            'currency must match account (${account.currency})',
          );
        }
        final categoryName = value(row, 'category');
        final category = data.categories.firstWhere(
          (item) =>
              item.type == type &&
              (categoryName.isEmpty ||
                  item.name.toLowerCase() == categoryName.toLowerCase() ||
                  item.id == categoryName),
          orElse: () =>
              throw FormatException('unknown $type category "$categoryName"'),
        );
        final number = num.tryParse(value(row, 'amount').replaceAll(',', ''));
        if (number == null || !number.isFinite || number <= 0) {
          throw const FormatException('amount must be a positive decimal');
        }
        final date = readDate(value(row, 'date')).toLocal();
        if (date.year < 1970 || date.year > 2200) {
          throw const FormatException('date must use ISO format (YYYY-MM-DD)');
        }
        final amount = toMinor(number, account.currency);
        if (amount <= 0) throw const FormatException('amount rounds to zero');
        final suppliedId = value(row, 'id');
        final id = suppliedId.isNotEmpty
            ? suppliedId
            : 'csv-${sha256.convert(utf8.encode('${date.toIso8601String()}|$type|$name|$amount|${account.id}')).toString().substring(0, 24)}';
        if (!seen.add(id)) {
          duplicates++;
          continue;
        }
        valid.add(
          MoneyTransaction(
            id: id,
            name: name,
            type: type,
            amountMinor: amount,
            accountId: account.id,
            categoryId: category.id,
            date: date,
            notes: value(row, 'notes'),
          ),
        );
      } catch (error) {
        errors.add(
          'Row ${i + 2}: ${error.toString().replaceFirst('FormatException: ', '')}',
        );
      }
    }
    return CsvPreview(valid, errors, duplicates);
  }
}

class CsvService {
  // Protect spreadsheet users from formula injection in untrusted merchant names.
  static String safeCell(String text) =>
      RegExp(r'^[=+\-@\t\r]').hasMatch(text) ? "'$text" : text;
  static Uint8List export(Ledger ledger, List<MoneyTransaction> entries) {
    final rows = <List<dynamic>>[
      [
        'id',
        'date',
        'type',
        'name',
        'amount',
        'currency',
        'account',
        'category',
        'to_account',
        'to_amount',
        'notes',
        'labels',
        'people',
        'place',
        'receipts',
      ],
      for (final entry in entries)
        [
          entry.id,
          entry.date.toIso8601String(),
          entry.type,
          safeCell(entry.name),
          fromMinor(
            entry.amountMinor,
            ledger.account(entry.accountId).currency,
          ).toStringAsFixed(
            decimalsFor(ledger.account(entry.accountId).currency),
          ),
          ledger.account(entry.accountId).currency,
          safeCell(ledger.account(entry.accountId).name),
          safeCell(ledger.category(entry.categoryId)?.name ?? ''),
          entry.toAccountId.isEmpty
              ? ''
              : safeCell(ledger.account(entry.toAccountId).name),
          entry.toAccountId.isEmpty
              ? ''
              : fromMinor(
                  entry.toAmountMinor,
                  ledger.account(entry.toAccountId).currency,
                ).toStringAsFixed(
                  decimalsFor(ledger.account(entry.toAccountId).currency),
                ),
          safeCell(entry.notes),
          safeCell(
            ledger.data.entities
                .where((item) => entry.labelIds.contains(item.id))
                .map((item) => item.name)
                .join('|'),
          ),
          safeCell(
            ledger.data.entities
                .where((item) => entry.personIds.contains(item.id))
                .map((item) => item.name)
                .join('|'),
          ),
          safeCell(
            ledger.data.entities
                .where((item) => item.id == entry.placeId)
                .map((item) => item.name)
                .join(),
          ),
          entry.receipts.length,
        ],
    ];
    return Uint8List.fromList(
      utf8.encode('\ufeff${const ListToCsvConverter().convert(rows)}'),
    );
  }
}
