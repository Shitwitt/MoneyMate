import 'dart:convert';

import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/image_headers.dart';

void require(bool condition, String message) {
  if (!condition) throw FormatException(message);
}

void validateData(AppData app) {
  require(
    app.schemaVersion == 1,
    'This backup requires a different app version',
  );
  require(app.profiles.length <= 50, 'Too many profiles');
  final profileIds = <String>{};
  for (final profile in app.profiles) {
    require(
      profileIds.add(profile.profile.id) && profile.profile.id.isNotEmpty,
      'Duplicate or missing profile ID',
    );
    validateProfile(profile);
  }
  require(
    app.profiles.isEmpty || profileIds.contains(app.activeProfileId),
    'Active profile is missing',
  );
  final settings = app.settings;
  require(languageNames.containsKey(settings.locale), 'Unsupported language');
  require(
    ['international', 'indian'].contains(settings.numberFormat),
    'Invalid number format',
  );
  require(
    settings.hiddenCards.every(homeCardNames.containsKey),
    'Invalid hidden home card',
  );
  require(
    ['system', 'light', 'dark', 'black'].contains(settings.theme),
    'Invalid theme',
  );
  require(
    settings.weekStart >= 1 && settings.weekStart <= 7,
    'Invalid first day of week',
  );
  require(
    settings.monthStart >= 1 && settings.monthStart <= 31,
    'Invalid financial month',
  );
  require(
    settings.fontScale >= .8 && settings.fontScale <= 1.6,
    'Invalid font scale',
  );
  require(
    settings.navTabs.length >= 3 &&
        settings.navTabs.length <= 5 &&
        settings.navTabs.toSet().length == settings.navTabs.length &&
        settings.navTabs.every(
          [
            'home',
            'accounts',
            'transactions',
            'plans',
            'reports',
            'more',
          ].contains,
        ) &&
        settings.navTabs.contains('more'),
    'Navigation must have 3–5 unique tabs, including More',
  );
  require(
    settings.homeCards.toSet().length == settings.homeCards.length &&
        settings.homeCards.every(homeCardNames.containsKey),
    'Invalid home layout',
  );
  require(
    ['none', 'pin', 'biometric'].contains(settings.lockMode),
    'Invalid lock mode',
  );
}

void validateProfile(ProfileData data) {
  require(
    data.profile.name.trim().isNotEmpty && data.profile.name.length <= 100,
    'Enter a profile name (up to 100 characters)',
  );
  require(
    data.accounts.any((account) => !account.archived),
    'Keep at least one active account',
  );
  require(
    data.categories.any((item) => item.type == 'expense' && !item.hidden) &&
        data.categories.any((item) => item.type == 'income' && !item.hidden),
    'Keep at least one visible income and expense category',
  );
  require(
    data.transactions.length <= 200000,
    'Backup exceeds the 200,000 transaction safety limit',
  );
  void ids(Iterable<String> values) {
    final all = values.toList();
    require(
      all.every((id) => id.isNotEmpty && id.length <= 200) &&
          all.toSet().length == all.length,
      'Duplicate or invalid record IDs',
    );
  }

  for (final values in [
    data.accounts.map((item) => item.id),
    data.categories.map((item) => item.id),
    data.transactions.map((item) => item.id),
    data.budgets.map((item) => item.id),
    data.goals.map((item) => item.id),
    data.loans.map((item) => item.id),
    data.recurrings.map((item) => item.id),
    data.assets.map((item) => item.id),
    data.entities.map((item) => item.id),
    data.templates.map((item) => item.id),
    data.bills.map((item) => item.id),
  ]) {
    ids(values);
  }
  final accounts = {for (final item in data.accounts) item.id: item};
  final categories = {for (final item in data.categories) item.id: item};
  final rates = {for (final item in data.rates) item.code: item.perUsd};
  require(
    rates.length == data.rates.length &&
        (rates['USD'] ?? 0) == 1 &&
        rates.values.every(
          (rate) => rate.isFinite && rate > 0 && rate <= 1000000000,
        ),
    'Invalid exchange rates; USD must be 1',
  );
  require(
    rates.containsKey(data.profile.currency),
    'Profile currency needs an exchange rate',
  );
  bool validDate(DateTime date) => date.year >= 1970 && date.year <= 2200;
  bool validMoney(int value) => value.abs() <= 1000000000000000;
  for (final item in data.accounts) {
    require(
      item.name.trim().isNotEmpty && item.name.length <= 100,
      'Enter an account name',
    );
    require(
      rates.containsKey(item.currency) && validMoney(item.openingMinor),
      'Invalid account currency or opening balance',
    );
    require(accountTypes.contains(item.type), 'Invalid account type');
  }
  for (final category in data.categories) {
    require(
      category.name.trim().isNotEmpty &&
          ['expense', 'income'].contains(category.type),
      'Invalid category',
    );
  }
  final entityKinds = {for (final item in data.entities) item.id: item.kind};
  for (final entry in data.transactions) {
    require(
      ['income', 'expense', 'transfer'].contains(entry.type),
      'Invalid transaction type',
    );
    require(
      entry.name.trim().isNotEmpty && entry.name.length <= 200,
      'Enter a transaction name (up to 200 characters)',
    );
    require(
      entry.amountMinor > 0 &&
          validMoney(entry.amountMinor) &&
          validDate(entry.date),
      'Invalid transaction amount or date',
    );
    require(
      accounts.containsKey(entry.accountId),
      'Transaction account is missing',
    );
    if (entry.type == 'transfer') {
      require(
        entry.toAccountId != entry.accountId &&
            accounts.containsKey(entry.toAccountId) &&
            entry.toAmountMinor > 0 &&
            validMoney(entry.toAmountMinor),
        'Select two different accounts and a positive receiving amount',
      );
    } else {
      require(
        categories[entry.categoryId]?.type == entry.type,
        'Select a matching ${entry.type} category',
      );
    }
    require(
      entry.labelIds.every((id) => entityKinds[id] == 'label') &&
          entry.personIds.every((id) => entityKinds[id] == 'person') &&
          (entry.placeId.isEmpty || entityKinds[entry.placeId] == 'place'),
      'Transaction tags refer to missing records',
    );
    require(
      entry.goalId.isEmpty || data.goals.any((goal) => goal.id == entry.goalId),
      'Linked goal is missing',
    );
    require(
      entry.loanId.isEmpty || data.loans.any((loan) => loan.id == entry.loanId),
      'Linked loan is missing',
    );
    require(
      entry.receipts.length <= 5,
      'Maximum five receipts per transaction',
    );
    ids(entry.receipts.map((receipt) => receipt.id));
    for (final receipt in entry.receipts) {
      require(
        receipt.data.length <= maxReceiptBytes * 1.4,
        'Receipt is too large',
      );
      final bytes = base64Decode(receipt.data);
      require(
        bytes.length <= maxReceiptBytes &&
            receiptMime(bytes) == receipt.mime &&
            receipt.name.trim().isNotEmpty &&
            receipt.name.length <= 255,
        'Invalid receipt image',
      );
    }
  }
  for (final item in data.budgets) {
    require(
      item.name.trim().isNotEmpty &&
          item.limitMinor > 0 &&
          validMoney(item.limitMinor) &&
          periods.contains(item.period) &&
          validDate(item.start),
      'Invalid budget',
    );
    require(
      item.categoryIds.every((id) => categories[id]?.type == 'expense'),
      'Budget categories must be expenses',
    );
    require(
      item.period != 'custom' ||
          (item.end != null &&
              validDate(item.end!) &&
              !item.end!.isBefore(item.start)),
      'Choose a valid custom budget range',
    );
  }
  for (final goal in data.goals) {
    require(
      goal.name.trim().isNotEmpty &&
          goal.targetMinor > 0 &&
          validMoney(goal.targetMinor) &&
          validDate(goal.deadline),
      'Invalid goal',
    );
    require(
      goal.accountId.isEmpty || accounts.containsKey(goal.accountId),
      'Linked goal account is missing',
    );
    require(
      goal.contributions.every(
        (event) =>
            event.amountMinor >= 0 &&
            validMoney(event.amountMinor) &&
            validDate(event.date),
      ),
      'Invalid goal contribution',
    );
  }
  for (final loan in data.loans) {
    require(
      loan.personName.trim().isNotEmpty &&
          ['lent', 'borrowed'].contains(loan.direction) &&
          loan.principalMinor > 0 &&
          validMoney(loan.principalMinor) &&
          loan.interestPercent.isFinite &&
          loan.interestPercent >= 0 &&
          loan.interestPercent <= 1000 &&
          validDate(loan.due),
      'Invalid loan',
    );
    require(
      loan.repayments.every(
        (event) =>
            event.amountMinor >= 0 &&
            validMoney(event.amountMinor) &&
            validDate(event.date),
      ),
      'Invalid repayment',
    );
    require(
      loan.repayments.fold<int>(0, (sum, item) => sum + item.amountMinor) <=
          (loan.principalMinor * (1 + loan.interestPercent / 100)).round(),
      'Repayments exceed the loan total',
    );
  }
  for (final rule in data.recurrings) {
    require(
      rule.name.trim().isNotEmpty &&
          rule.amountMinor > 0 &&
          validMoney(rule.amountMinor) &&
          accounts.containsKey(rule.accountId) &&
          categories[rule.categoryId]?.type == rule.type &&
          frequencies.contains(rule.frequency) &&
          rule.interval > 0 &&
          rule.interval <= 365 &&
          validDate(rule.start) &&
          validDate(rule.nextDue),
      'Invalid recurring transaction',
    );
    require(
      rule.end == null ||
          (!rule.end!.isBefore(rule.start) && validDate(rule.end!)),
      'Recurring end must follow its start',
    );
  }
  for (final item in data.assets) {
    require(
      item.name.trim().isNotEmpty &&
          item.valueMinor >= 0 &&
          validMoney(item.valueMinor) &&
          assetTypes.contains(item.type),
      'Invalid asset',
    );
  }
  for (final item in data.entities) {
    require(
      ['label', 'person', 'place'].contains(item.kind) &&
          item.name.trim().isNotEmpty,
      'Invalid label, person or place',
    );
    require(
      item.photoBase64.length <= maxReceiptBytes * 1.4,
      'Photo is too large',
    );
  }
  for (final item in data.templates) {
    require(
      item.name.trim().isNotEmpty &&
          item.amountMinor > 0 &&
          validMoney(item.amountMinor) &&
          accounts.containsKey(item.accountId) &&
          categories[item.categoryId]?.type == item.type,
      'Invalid template',
    );
  }
  for (final bill in data.bills) {
    require(
      bill.title.trim().isNotEmpty &&
          bill.totalMinor > 0 &&
          validMoney(bill.totalMinor) &&
          bill.shares.isNotEmpty &&
          validDate(bill.date),
      'Invalid bill',
    );
    require(
      bill.shares.map((item) => item.personId).toSet().length ==
              bill.shares.length &&
          bill.shares.every(
            (item) => item.amountMinor >= 0 && item.name.trim().isNotEmpty,
          ) &&
          bill.shares.fold<int>(0, (sum, item) => sum + item.amountMinor) ==
              bill.totalMinor,
      'Bill shares must sum to its total',
    );
    require(
      bill.shares.any((item) => item.personId == bill.paidById),
      'Bill payer must be a participant',
    );
  }
}
