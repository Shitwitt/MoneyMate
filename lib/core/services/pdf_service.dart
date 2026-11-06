import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/ledger.dart';
import '../models/models.dart';
import '../utils/money.dart';

class PdfService {
  static Future<Uint8List> report(
    Ledger ledger,
    List<MoneyTransaction> entries,
    String title, {
    String? scopeNote,
  }) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final fallbacks = <pw.Font>[];
    for (final script in [
      'Devanagari',
      'Arabic',
      'Bengali',
      'Gurmukhi',
      'Gujarati',
      'Tamil',
      'Telugu',
    ]) {
      fallbacks.add(
        pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoSans$script-Regular.ttf'),
        ),
      );
    }
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: font,
        fontFallback: fallbacks,
      ),
    );
    String amount(int value) =>
        '${ledger.currency} ${fromMinor(value, ledger.currency).toStringAsFixed(decimalsFor(ledger.currency))}';
    final income = entries
        .where((entry) => entry.type == 'income')
        .fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry));
    final expense = entries
        .where((entry) => entry.type == 'expense')
        .fold<int>(0, (sum, entry) => sum + ledger.entryValue(entry));
    final savings = income > 0
        ? '${((income - expense) / income * 100).toStringAsFixed(1)}%'
        : 'Unavailable (no recorded income)';
    final categories = ledger.breakdown(
      entries.where((entry) => entry.type == 'expense'),
      'category',
    );
    doc.addPage(
      pw.MultiPage(
        maxPages: 1000,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TINK / PRIVATE FINANCE',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              ledger.data.profile.name,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated locally · ${DateFormat.yMMMd().format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                '${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 24),
          pw.Text(title, style: const pw.TextStyle(fontSize: 28)),
          pw.Text(
            '${entries.length} transactions · Reference currency: ${ledger.currency}',
            style: const pw.TextStyle(fontSize: 11),
          ),
          if (scopeNote != null && scopeNote.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 12),
              child: pw.Text(
                scopeNote,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EDE7FF'),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Income: ${amount(income)}'),
                pw.Text('Expenses: ${amount(expense)}'),
                pw.Text('Net cash flow: ${amount(income - expense)}'),
                pw.Text('Savings rate: $savings'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Where your money went',
            style: const pw.TextStyle(fontSize: 18),
          ),
          pw.SizedBox(height: 12),
          for (final category in categories.entries)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(category.key),
                      pw.Text(
                        '${amount(category.value)} · ${expense > 0 ? (category.value / expense * 100).toStringAsFixed(1) : '0'}%',
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    height: 6,
                    width: expense > 0 ? 470 * category.value / expense : 0,
                    color: PdfColor.fromHex('#916CFF'),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Chart interpretation: bars show each category’s proportion of filtered spending. Transfers are excluded from income and expenses. Conversion uses your manually maintained reference rates.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Transaction ledger',
            style: const pw.TextStyle(fontSize: 18),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: const pw.TextStyle(fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(6),
            headers: [
              'Date',
              'Description / account',
              'Type',
              'Amount (${ledger.currency})',
            ],
            data: [
              for (final entry in entries)
                [
                  DateFormat('yyyy-MM-dd').format(entry.date),
                  '${entry.name}\n${ledger.account(entry.accountId).name}',
                  entry.type,
                  fromMinor(
                    ledger.entryValue(entry),
                    ledger.currency,
                  ).toStringAsFixed(decimalsFor(ledger.currency)),
                ],
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }
}
