import '../data/seed.dart';
import '../models/models.dart';
import '../utils/money.dart';

class DeepLinkRequest {
  final MoneyTransaction? transaction;
  final bool silent;
  final String? destination;
  const DeepLinkRequest(this.transaction, this.silent, {this.destination});
}

class DeepLinkService {
  static const pages = {
    'home': 'Home',
    'accounts': 'Accounts',
    'activity': 'Activity',
    'search': 'Search',
    'plans': 'Plans',
    'reports': 'Reports',
    'analytics': 'Analytics',
    'health': 'Spending Health',
    'budgets': 'Budgets',
    'goals': 'Goals',
    'loans': 'Loans',
    'recurring': 'Subscriptions & recurring',
    'categories': 'Categories',
    'labels': 'Labels',
    'people': 'People',
    'places': 'Places',
    'assets': 'Assets',
    'net-worth': 'Net worth',
    'templates': 'Quick templates',
    'splitter': 'Bill splitter',
    'achievements': 'Achievements',
    'settings': 'Settings',
    'backup': 'Backup & transfer',
    'more': 'All tools',
  };

  static Uri pageUri(String destination) {
    if (!pages.containsKey(destination))
      throw const FormatException('Unknown page shortcut');
    return Uri(
      scheme: 'tink',
      host: 'open',
      queryParameters: {'page': destination},
    );
  }

  static bool isCustomScheme(Uri uri) => ['tink', 'paisa'].contains(uri.scheme);

  /// app_links also emits the ordinary browser address on startup.
  static bool isWebFinanceLink(Uri uri) =>
      isCustomScheme(uri) || (uri.scheme == 'https' && uri.path == '/add');

  static DeepLinkRequest parse(Uri uri, ProfileData data) {
    final action = isCustomScheme(uri)
        ? uri.host.toLowerCase()
        : uri.path.replaceFirst('/', '');
    if (!isCustomScheme(uri) && !(uri.scheme == 'https' && action == 'add')) {
      throw const FormatException('Unsupported finance link');
    }
    if (isCustomScheme(uri) &&
        (action == 'open' || action == 'page' || pages.containsKey(action))) {
      final String? target;
      if (action == 'open') {
        if (uri.pathSegments.isNotEmpty)
          throw const FormatException('Unknown page shortcut');
        target = uri.queryParameters['page']?.trim().toLowerCase();
      } else if (action == 'page') {
        target = uri.pathSegments.length == 1
            ? uri.pathSegments.single.toLowerCase()
            : null;
      } else {
        if (uri.pathSegments.isNotEmpty)
          throw const FormatException('Unknown page shortcut');
        target = action;
      }
      if (target == null || !pages.containsKey(target)) {
        throw const FormatException('Unknown page shortcut');
      }
      return DeepLinkRequest(null, false, destination: target);
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
        notes: query['notes'] ?? query['description'] ?? '',
      ),
      action == 'silent_add',
    );
  }
}
