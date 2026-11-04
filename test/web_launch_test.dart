import 'package:flutter_test/flutter_test.dart';
import 'package:paisaclone/core/services/deep_link_service.dart';

void main() {
  test('Ordinary browser startup addresses are not finance intents', () {
    expect(
      DeepLinkService.isWebFinanceLink(Uri.parse('http://127.0.0.1:8080/')),
      isFalse,
    );
    expect(
      DeepLinkService.isWebFinanceLink(Uri.parse('https://host/project/')),
      isFalse,
    );
    expect(
      DeepLinkService.isWebFinanceLink(Uri.parse('https://host/?amount=1')),
      isFalse,
    );
    expect(
      DeepLinkService.isWebFinanceLink(Uri.parse('https://host/add?amount=1')),
      isTrue,
    );
    expect(
      DeepLinkService.isWebFinanceLink(Uri.parse('paisa://quick_add')),
      isTrue,
    );
    expect(
      DeepLinkService.isWebFinanceLink(Uri.parse('paisa://add?amount=1')),
      isTrue,
    );
  });
}
