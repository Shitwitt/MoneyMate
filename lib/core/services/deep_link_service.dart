import '../data/seed.dart';
import '../models/models.dart';
import '../utils/money.dart';

class DeepLinkRequest {
  final MoneyTransaction? transaction;
  final bool silent;
  const DeepLinkRequest(this.transaction, this.silent);
}

class DeepLinkService {
  static DeepLinkRequest parse(Uri uri, ProfileData data) {
    final action = uri.scheme == 'paisa'
        ? uri.host
        : uri.path.replaceFirst('/', '');
    if (uri.scheme != 'paisa' && !(uri.scheme == 'https' && action == 'add')) {
      throw const FormatException('Unsupported finance link');
    }
    if (action == 'quick_add') return const DeepLinkRequest(null, false);
    if (!['add', 'silent_add'].contains(action)) {
      throw const FormatException('Unknown link action');
    }
    final query = uri.queryParameters;
    final type = query['type'] ?? 'expense';
    if (!['expense', 'income'].contains(type)) {
      throw const FormatException(
        'Automation supports expense or income. Enter transfers in the app.',
      );
    }
    Account resolveAccount(String? name) => name == null
        ? data.accounts.firstWhere((account) => !account.archived)
        : data.accounts.firstWhere(
            (account) =>
                account.id == name ||
                account.name.toLowerCase() == name.toLowerCase(),
            orElse: () => throw FormatException('Unknown account: $name'),
          );
    final account = resolveAccount(query['account']);
    final categoryName = query['category'];
    final category = data.categories.firstWhere(
      (category) =>
          category.type == type &&
          (categoryName == null ||
              category.id == categoryName ||
              category.name.toLowerCase() == categoryName.toLowerCase()),
      orElse: () =>
          throw const FormatException('Unknown or mismatched category'),
    );
    final amount = toMinor(
      evaluateAmount(query['amount'] ?? ''),
      account.currency,
    );
    final name = (query['name'] ?? 'Quick $type').trim();
    if (name.isEmpty || name.length > 200 || amount <= 0) {
      throw const FormatException('Invalid link name or amount');
    }
    final date = query['date'] == null
        ? DateTime.now()
        : readDate(query['date']!).toLocal();
    if (date.year < 1970 || date.year > 2200) {
      throw const FormatException('Invalid ISO date');
    }
    return DeepLinkRequest(
      MoneyTransaction(
        id: uuid.v4(),
        name: name,
        type: type,
        amountMinor: amount,
        accountId: account.id,
        categoryId: category.id,
        date: date,
        notes: query['notes'] ?? '',
      ),
      action == 'silent_add',
    );
  }
}
