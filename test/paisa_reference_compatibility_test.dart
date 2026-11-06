import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/services/deep_link_service.dart';

import 'support.dart';

void main() {
  test(
    'Tink and legacy links accept documented description and encoded names',
    () {
      final data = fixture();
      for (final scheme in ['tink', 'paisa']) {
        final uri = Uri(
          scheme: scheme,
          host: 'silent_add',
          queryParameters: {
            'amount': '4.50',
            'type': 'expense',
            'name': 'Coffee & lunch + tip',
            'account': 'Everyday',
            'category': 'Food & Dining',
            'description': 'Local notes & a + sign',
          },
        );
        expect(DeepLinkService.isWebFinanceLink(uri), isTrue);
        final request = DeepLinkService.parse(uri, data);
        expect(request.silent, isTrue);
        expect(request.transaction!.name, 'Coffee & lunch + tip');
        expect(request.transaction!.notes, 'Local notes & a + sign');
        expect(request.transaction!.amountMinor, 450);
        expect(request.transaction!.accountId, data.accounts.first.id);
      }
    },
  );

  test(
    'Existing notes parameter takes precedence over its description alias',
    () {
      final request = DeepLinkService.parse(
        Uri.parse('tink://add?amount=2&notes=Keep%20this&description=Other'),
        fixture(),
      );
      expect(request.transaction!.notes, 'Keep this');
      expect(request.silent, isFalse);
    },
  );

  test(
    'Both quick-add schemes open an unsaved form and never request silence',
    () {
      for (final scheme in ['tink', 'paisa']) {
        final request = DeepLinkService.parse(
          Uri.parse('$scheme://quick_add'),
          fixture(),
        );
        expect(request.transaction, isNull);
        expect(request.silent, isFalse);
      }
    },
  );

  test(
    'Reference website universal links are not claimed as Tink-owned links',
    () {
      final uri = Uri.parse('https://paisa-tracker.app/silent_add?amount=2');
      expect(DeepLinkService.isWebFinanceLink(uri), isFalse);
      expect(
        () => DeepLinkService.parse(uri, fixture()),
        throwsFormatException,
      );
      for (final scheme in ['tink', 'paisa']) {
        expect(
          () => DeepLinkService.parse(
            Uri.parse('$scheme://add?amount=2&type=transfer'),
            fixture(),
          ),
          throwsFormatException,
        );
      }
    },
  );
}
