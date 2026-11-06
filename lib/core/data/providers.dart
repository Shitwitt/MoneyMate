import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import 'achievements.dart';
import 'ledger.dart';
import 'local_store.dart';
import 'seed.dart';
import 'validation.dart';

final repositoryProvider = Provider<AppRepository>(
  (ref) => throw StateError('Repository must be initialized before runApp'),
);
final appProvider = StateNotifierProvider<AppController, AppData>(
  (ref) => AppController(ref.watch(repositoryProvider)),
);
final profileProvider = Provider<ProfileData?>((ref) {
  final data = ref.watch(appProvider);
  return data.profiles
      .where((profile) => profile.profile.id == data.activeProfileId)
      .firstOrNull;
});
final ledgerProvider = Provider<Ledger?>((ref) {
  final profile = ref.watch(profileProvider);
  return profile == null
      ? null
      : Ledger(profile, ref.watch(appProvider.select((data) => data.settings)));
});

class PremiumRequired implements Exception {
  final String feature;
  const PremiumRequired(this.feature);
  @override
  String toString() => 'Unlock Pro for $feature';
}

class AppController extends StateNotifier<AppData> {
  final AppRepository repository;
  Future<void> _tail = Future.value();
  AppData? _beforeDemo;
  AppRepository? _demoRepository;
  AppController(this.repository) : super(repository.initial);
  AppData get snapshot => state;

  /// Serializes ALL read/modify/write operations, including imports and recurrence.
  /// State becomes visible only after the durable write succeeds; errors do not
  /// poison the queue and a failed operation never exposes a partial transfer.
  Future<void> mutate(AppData Function(AppData) change) {
    final work = _tail.then((_) async {
      var next = change(state);
      next = next.copyWith(
        profiles: next.profiles
            .map((profile) => unlockAchievements(profile, next.settings))
            .toList(),
      );
      if (_demoRepository != null) next = next.copyWith(isDemo: true);
      validateData(next);
      await (_demoRepository ?? repository).save(next);
      if (mounted) state = next;
    });
    _tail = work.then<void>(
      (_) {},
      onError: (Object error, StackTrace trace) {},
    );
    return work;
  }

  /// Demo has its own in-memory repository. No financial/settings writes leak to disk.
  Future<void> startDemo({String currency = 'USD', DateTime? clock}) {
    final work = _tail.then((_) async {
      if (_beforeDemo != null) return;
      final settings = state.settings.copyWith(
        theme: 'dark',
        accent: 0xffffb59a,
        isPro: true,
        notificationsEnabled: false,
        allowSilentAdds: false,
        lockMode: 'none',
        pinHash: '',
        pinSalt: '',
        homeCards: defaultHomeCards,
        hiddenCards: const [],
        navTabs: const ['home', 'accounts', 'reports', 'search'],
      );
      final profile = unlockAchievements(
        seedProfile(
          name: 'Demo User',
          currency: currency,
          accountName: 'Cash',
          demo: true,
          clock: clock,
        ),
        settings,
      );
      final demo = AppData(
        isDemo: true,
        profiles: [profile],
        activeProfileId: profile.profile.id,
        settings: settings,
      );
      validateData(demo);
      _beforeDemo = state;
      _demoRepository = _DemoRepository(demo);
      if (mounted) state = demo;
    });
    _tail = work.then<void>(
      (_) {},
      onError: (Object error, StackTrace trace) {},
    );
    return work;
  }

  Future<void> exitDemo() {
    final work = _tail.then((_) async {
      final previous = _beforeDemo;
      if (previous == null) return;
      _demoRepository = null;
      _beforeDemo = null;
      if (mounted) state = previous;
    });
    _tail = work.then<void>(
      (_) {},
      onError: (Object error, StackTrace trace) {},
    );
    return work;
  }

  Future<void> updateProfile(
    ProfileData Function(ProfileData, AppData) change,
  ) => mutate(
    (app) => app.copyWith(
      profiles: [
        for (final profile in app.profiles)
          if (profile.profile.id == app.activeProfileId)
            change(profile, app)
          else
            profile,
      ],
    ),
  );
  Future<void> settings(AppSettings Function(AppSettings) change) =>
      mutate((app) => app.copyWith(settings: change(app.settings)));
  Future<void> createProfile({
    required String name,
    required String currency,
    required String accountName,
    int openingMinor = 0,
    bool demo = false,
  }) => mutate((app) {
    final profile = seedProfile(
      name: name.trim(),
      currency: currency,
      accountName: accountName.trim(),
      openingMinor: openingMinor,
      demo: demo,
    );
    return app.copyWith(
      profiles: [...app.profiles, profile],
      activeProfileId: profile.profile.id,
      settings: app.profiles.isEmpty
          ? app.settings.copyWith(
              numberFormat: currency == 'INR' ? 'indian' : 'international',
            )
          : app.settings,
    );
  });
  Future<void> switchProfile(String id) => mutate((app) {
    require(
      app.profiles.any((item) => item.profile.id == id),
      'Profile not found',
    );
    return app.copyWith(activeProfileId: id);
  });
  Future<void> deleteProfile(String id) => mutate((app) {
    require(app.profiles.length > 1, 'Keep at least one profile');
    final remaining = app.profiles
        .where((item) => item.profile.id != id)
        .toList();
    return app.copyWith(
      profiles: remaining,
      activeProfileId: app.activeProfileId == id
          ? remaining.first.profile.id
          : app.activeProfileId,
    );
  });
  Future<void> renameProfile(String name) => updateProfile(
    (profile, app) =>
        profile.copyWith(profile: profile.profile.copyWith(name: name.trim())),
  );
  Future<void> restore(AppData backup) => mutate(
    (app) => backup.copyWith(
      settings: backup.settings.copyWith(
        lockMode: app.settings.lockMode,
        pinHash: app.settings.pinHash,
        pinSalt: app.settings.pinSalt,
        allowSilentAdds: false,
        notificationsEnabled: false,
      ),
    ),
  );
  Future<void> upsertAccount(Account item) => updateProfile((profile, app) {
    final existing = profile.accounts
        .where((account) => account.id == item.id)
        .firstOrNull;
    require(
      existing == null ||
          existing.currency == item.currency ||
          !profile.transactions.any(
            (entry) =>
                entry.accountId == item.id || entry.toAccountId == item.id,
          ),
      'An account with transactions cannot change currency. Create another account instead.',
    );
    return profile.copyWith(
      accounts: replace(profile.accounts, item, (item) => item.id),
    );
  });
  Future<void> deleteAccount(String id) => updateProfile((profile, app) {
    require(profile.accounts.length > 1, 'Keep at least one account');
    require(
      !profile.accounts.any((account) => account.parentId == id) &&
          !profile.transactions.any(
            (entry) => entry.accountId == id || entry.toAccountId == id,
          ) &&
          !profile.goals.any((goal) => goal.accountId == id) &&
          !profile.loans.any((loan) => loan.accountId == id) &&
          !profile.recurrings.any((rule) => rule.accountId == id) &&
          !profile.templates.any((template) => template.accountId == id),
      'This account is in use. Archive it instead.',
    );
    return profile.copyWith(
      accounts: profile.accounts.where((item) => item.id != id).toList(),
    );
  });
  Future<void> upsertCategory(Category item) => updateProfile((profile, app) {
    final old = profile.categories.where((c) => c.id == item.id).firstOrNull;
    require(
      old == null ||
          old.type == item.type ||
          (!profile.transactions.any((e) => e.categoryId == item.id) &&
              !profile.loans.any((l) => l.categoryId == item.id) &&
              !profile.recurrings.any((r) => r.categoryId == item.id)),
      'This category is in use. Keep its type or create a new category.',
    );
    return profile.copyWith(
      categories: replace(profile.categories, item, (c) => c.id),
    );
  });
  Future<void> reorderCategories(List<Category> categories) => updateProfile(
    (profile, app) => profile.copyWith(
      categories: [
        for (var i = 0; i < categories.length; i++)
          categories[i].copyWith(order: i),
      ],
    ),
  );
  Future<void> deleteCategory(String id) => updateProfile((profile, app) {
    require(
      !profile.categories.any((category) => category.parentId == id) &&
          !profile.transactions.any((entry) => entry.categoryId == id) &&
          !profile.budgets.any((budget) => budget.categoryIds.contains(id)) &&
          !profile.recurrings.any((rule) => rule.categoryId == id) &&
          !profile.templates.any((template) => template.categoryId == id),
      'This category is in use. Hide it instead.',
    );
    return profile.copyWith(
      categories: profile.categories.where((item) => item.id != id).toList(),
    );
  });
  Future<void> saveTransaction(
    MoneyTransaction item, {
    bool asTemplate = false,
  }) => updateProfile((profile, app) {
    var next = _syncLoanEntries(
      profile,
      replace(profile.transactions, item, (item) => item.id),
      app.settings,
      changedId: item.id,
    );
    if (asTemplate) {
      require(item.type != 'transfer', 'Transfer templates are not supported');
      next = next.copyWith(
        templates: [
          ...next.templates,
          TransactionTemplate(
            id: uuid.v4(),
            name: item.name,
            type: item.type,
            amountMinor: item.amountMinor,
            accountId: item.accountId,
            categoryId: item.categoryId,
            notes: item.notes,
            labelIds: item.labelIds,
          ),
        ],
      );
    }
    return next;
  });
  Future<void> deleteTransactions(Set<String> ids) => updateProfile(
    (profile, app) => _syncLoanEntries(
      profile,
      profile.transactions.where((item) => !ids.contains(item.id)).toList(),
      app.settings,
    ),
  );
  Future<void> saveTemplate(TransactionTemplate item) => updateProfile(
    (profile, app) => profile.copyWith(
      templates: replace(profile.templates, item, (item) => item.id),
    ),
  );
  Future<void> deleteTemplate(String id) => updateProfile(
    (profile, app) => profile.copyWith(
      templates: profile.templates.where((item) => item.id != id).toList(),
    ),
  );
  Future<void> applyTemplate(TransactionTemplate template) => saveTransaction(
    MoneyTransaction(
      id: uuid.v4(),
      name: template.name,
      type: template.type,
      amountMinor: template.amountMinor,
      accountId: template.accountId,
      categoryId: template.categoryId,
      date: DateTime.now(),
      notes: template.notes,
      labelIds: template.labelIds,
    ),
  );
  Future<void> upsertBudget(Budget item) => updateProfile((profile, app) {
    if (!app.settings.isPro &&
        !profile.budgets.any((budget) => budget.id == item.id) &&
        profile.budgets.length >= freeBudgetLimit) {
      throw const PremiumRequired('unlimited budgets');
    }
    return profile.copyWith(
      budgets: replace(profile.budgets, item, (item) => item.id),
    );
  });
  Future<void> deleteBudget(String id) => updateProfile(
    (profile, app) => profile.copyWith(
      budgets: profile.budgets.where((item) => item.id != id).toList(),
      recurrings: [
        for (final rule in profile.recurrings)
          if (rule.budgetId == id) rule.copyWith(budgetId: '') else rule,
      ],
      transactions: [
        for (final entry in profile.transactions)
          if (entry.budgetId == id) entry.copyWith(budgetId: '') else entry,
      ],
    ),
  );
  Future<void> upsertGoal(Goal item) => updateProfile((profile, app) {
    if (!app.settings.isPro &&
        !profile.goals.any((goal) => goal.id == item.id) &&
        profile.goals.length >= freeGoalLimit) {
      throw const PremiumRequired('unlimited savings goals');
    }
    return profile.copyWith(
      goals: replace(profile.goals, item, (item) => item.id),
    );
  });
  Future<void> contribute(String id, int amount, String note) =>
      updateProfile((profile, app) {
        require(amount > 0, 'Contribution must be positive');
        return profile.copyWith(
          goals: [
            for (final goal in profile.goals)
              if (goal.id == id)
                goal.copyWith(
                  contributions: [
                    ...goal.contributions,
                    MoneyEvent(
                      id: uuid.v4(),
                      amountMinor: amount,
                      date: DateTime.now(),
                      note: note,
                    ),
                  ],
                )
              else
                goal,
          ],
        );
      });
  Future<void> deleteGoal(String id) => updateProfile(
    (profile, app) => profile.copyWith(
      goals: profile.goals.where((item) => item.id != id).toList(),
      transactions: [
        for (final item in profile.transactions)
          if (item.goalId == id) item.copyWith(goalId: '') else item,
      ],
    ),
  );
  Future<void> upsertLoan(Loan item, {String disburseAccountId = ''}) =>
      updateProfile((profile, app) {
        final old = profile.loans.where((l) => l.id == item.id).firstOrNull;
        require(
          old == null ||
              old.repayments.isEmpty ||
              old.direction == item.direction,
          'A loan with payments cannot change direction. Create a new loan instead.',
        );
        final entries = [...profile.transactions];
        if (disburseAccountId.isNotEmpty &&
            !profile.loans.any((loan) => loan.id == item.id)) {
          final account = profile.accounts.firstWhere(
            (a) => a.id == disburseAccountId,
          );
          final type = item.direction == 'lent' ? 'expense' : 'income';
          entries.add(
            MoneyTransaction(
              id: uuid.v4(),
              name: 'Loan · ${item.personName}',
              type: type,
              amountMinor: convertMinor(
                item.principalMinor,
                profile.profile.currency,
                account.currency,
                profile.rates,
              ),
              accountId: account.id,
              categoryId: item.categoryId.isNotEmpty
                  ? item.categoryId
                  : profile.categories.firstWhere((c) => c.type == type).id,
              date: item.start ?? DateTime.now(),
              createdAt: DateTime.now(),
              loanId: item.id,
              notes: item.notes,
              personIds: item.personId.isEmpty ? [] : [item.personId],
            ),
          );
        }
        return profile.copyWith(
          loans: replace(profile.loans, item, (l) => l.id),
          transactions: entries,
        );
      });
  Future<void> repayLoan(
    String id,
    int amount,
    String note, {
    String accountId = '',
  }) => updateProfile((profile, app) {
    final loan = profile.loans.firstWhere((l) => l.id == id);
    require(
      !loan.completed,
      'Reopen this loan before recording another payment',
    );
    require(
      amount > 0 && amount <= Ledger(profile, app.settings).loanRemaining(loan),
      'Repayment must be positive and not exceed the outstanding balance',
    );
    final now = DateTime.now(),
        transactionId = accountId.isEmpty ? '' : uuid.v4();
    final updated = loan.copyWith(
      repayments: [
        ...loan.repayments,
        MoneyEvent(
          id: uuid.v4(),
          amountMinor: amount,
          date: now,
          note: note,
          transactionId: transactionId,
        ),
      ],
    );
    final entries = [...profile.transactions];
    if (accountId.isNotEmpty) {
      final account = profile.accounts.firstWhere((a) => a.id == accountId);
      final type = loan.direction == 'lent' ? 'income' : 'expense';
      entries.add(
        MoneyTransaction(
          id: transactionId,
          name: 'Repayment · ${loan.personName}',
          type: type,
          amountMinor: convertMinor(
            amount,
            profile.profile.currency,
            account.currency,
            profile.rates,
          ),
          accountId: account.id,
          categoryId: profile.categories.firstWhere((c) => c.type == type).id,
          date: now,
          createdAt: now,
          loanId: id,
          notes: note,
          personIds: loan.personId.isEmpty ? [] : [loan.personId],
        ),
      );
    }
    return profile.copyWith(
      loans: replace(profile.loans, updated, (l) => l.id),
      transactions: entries,
    );
  });
  Future<void> setLoanCompleted(String id, bool completed) => updateProfile(
    (profile, app) => profile.copyWith(
      loans: [
        for (final loan in profile.loans)
          if (loan.id == id) loan.copyWith(completed: completed) else loan,
      ],
    ),
  );
  Future<void> deleteLoan(String id) => updateProfile(
    (profile, app) => profile.copyWith(
      loans: profile.loans.where((item) => item.id != id).toList(),
      transactions: [
        for (final item in profile.transactions)
          if (item.loanId == id) item.copyWith(loanId: '') else item,
      ],
    ),
  );
  Future<void> upsertAsset(Asset item) => updateProfile(
    (profile, app) => profile.copyWith(
      assets: replace(profile.assets, item, (item) => item.id),
    ),
  );
  Future<void> valueAsset(String id, int amount, String note) =>
      updateProfile((profile, app) {
        require(amount >= 0, 'Value cannot be negative');
        return profile.copyWith(
          assets: [
            for (final asset in profile.assets)
              if (asset.id == id)
                asset.copyWith(
                  valueMinor: amount,
                  history: [
                    ...asset.history,
                    MoneyEvent(
                      id: uuid.v4(),
                      amountMinor: amount,
                      date: DateTime.now(),
                      note: note,
                    ),
                  ],
                )
              else
                asset,
          ],
        );
      });
  Future<void> deleteAsset(String id) => updateProfile(
    (profile, app) => profile.copyWith(
      assets: profile.assets.where((item) => item.id != id).toList(),
    ),
  );
  Future<void> upsertEntity(NamedEntity item) => updateProfile((profile, app) {
    if (!app.settings.isPro &&
        !profile.entities.any((entity) => entity.id == item.id) &&
        profile.entities.where((entity) => entity.kind == item.kind).length >=
            freeEntityLimit) {
      throw PremiumRequired('unlimited ${item.kind}s');
    }
    return profile.copyWith(
      entities: replace(profile.entities, item, (item) => item.id),
    );
  });
  Future<void> deleteEntity(String id) => updateProfile(
    (profile, app) => profile.copyWith(
      entities: profile.entities.where((item) => item.id != id).toList(),
      transactions: [
        for (final entry in profile.transactions)
          entry.copyWith(
            labelIds: entry.labelIds.where((value) => value != id).toList(),
            personIds: entry.personIds.where((value) => value != id).toList(),
            placeId: entry.placeId == id ? '' : entry.placeId,
          ),
      ],
      recurrings: [
        for (final rule in profile.recurrings)
          rule.copyWith(
            labelIds: rule.labelIds.where((value) => value != id).toList(),
            personIds: rule.personIds.where((value) => value != id).toList(),
            placeId: rule.placeId == id ? '' : rule.placeId,
          ),
      ],
      templates: [
        for (final template in profile.templates)
          template.copyWith(
            labelIds: template.labelIds.where((value) => value != id).toList(),
          ),
      ],
      loans: [
        for (final loan in profile.loans)
          if (loan.personId == id) loan.copyWith(personId: '') else loan,
      ],
    ),
  );
  Future<void> upsertRecurring(Recurring item) => updateProfile(
    (profile, app) => profile.copyWith(
      recurrings: replace(profile.recurrings, item, (item) => item.id),
    ),
  );
  Future<void> deleteRecurring(String id) => updateProfile(
    (profile, app) => profile.copyWith(
      recurrings: profile.recurrings.where((item) => item.id != id).toList(),
    ),
  );
  Future<void> processRecurring({DateTime? clock, String? recordNowId}) =>
      updateProfile((profile, app) {
        final now = clock ?? DateTime.now();
        final entries = [...profile.transactions];
        final existing = entries.map((entry) => entry.id).toSet();
        final rules = <Recurring>[];
        for (final rule in profile.recurrings) {
          var due = rule.nextDue;
          var enabled = rule.enabled && !rule.archived;
          var count = 0;
          while (enabled &&
              (rule.autoPost || rule.id == recordNowId) &&
              !due.isAfter(now) &&
              (rule.end == null || !due.isAfter(rule.end!)) &&
              count < 1000) {
            final id = '${rule.id}@${due.toIso8601String()}';
            if (existing.add(id)) {
              entries.add(
                MoneyTransaction(
                  id: id,
                  name: rule.name,
                  type: rule.type,
                  amountMinor: rule.amountMinor,
                  accountId: rule.accountId,
                  categoryId: rule.categoryId,
                  date: due,
                  recurringId: rule.id,
                  notes: rule.notes,
                  budgetId: rule.budgetId,
                  labelIds: rule.labelIds,
                  personIds: rule.personIds,
                  placeId: rule.placeId,
                ),
              );
            }
            due = nextOccurrence(rule, due);
            count++;
            if (!rule.autoPost) break;
          }
          if (rule.end != null && due.isAfter(rule.end!)) enabled = false;
          rules.add(rule.copyWith(nextDue: due, enabled: enabled));
        }
        return profile.copyWith(transactions: entries, recurrings: rules);
      });

  /// Advance exactly the occurrence that was displayed. Stale/double taps cannot
  /// skip a second payment or create duplicate debits under concurrent catch-up.
  Future<void> skipRecurringOccurrence(
    String id, {
    required DateTime expectedDue,
  }) => updateProfile((profile, app) {
    final rule = profile.recurrings.where((r) => r.id == id).firstOrNull;
    require(
      rule != null && rule.enabled && !rule.archived,
      'This schedule is no longer active',
    );
    require(
      rule!.nextDue == expectedDue,
      'The schedule changed. Review the next payment first.',
    );
    final next = nextOccurrence(rule, rule.nextDue);
    return profile.copyWith(
      recurrings: replace(
        profile.recurrings,
        rule.copyWith(
          nextDue: next,
          enabled: rule.end == null || !next.isAfter(rule.end!),
        ),
        (r) => r.id,
      ),
    );
  });
  Future<void> processRecurringOccurrence(
    String id, {
    required DateTime expectedDue,
    DateTime? clock,
  }) => updateProfile((profile, app) {
    final rule = profile.recurrings.where((r) => r.id == id).firstOrNull;
    require(
      rule != null && rule.enabled && !rule.archived,
      'This schedule is no longer active',
    );
    require(
      rule!.nextDue == expectedDue,
      'The schedule changed. Review the next payment first.',
    );
    require(
      !rule.nextDue.isAfter(clock ?? DateTime.now()),
      'This payment is not due yet',
    );
    require(
      rule.end == null || !rule.nextDue.isAfter(rule.end!),
      'This schedule has ended',
    );
    final occurrenceId = '${rule.id}@${rule.nextDue.toIso8601String()}';
    final next = nextOccurrence(rule, rule.nextDue);
    final entry = MoneyTransaction(
      id: occurrenceId,
      name: rule.name,
      type: rule.type,
      amountMinor: rule.amountMinor,
      accountId: rule.accountId,
      categoryId: rule.categoryId,
      date: rule.nextDue,
      recurringId: rule.id,
      notes: rule.notes,
      budgetId: rule.budgetId,
      labelIds: rule.labelIds,
      personIds: rule.personIds,
      placeId: rule.placeId,
    );
    return profile.copyWith(
      transactions: profile.transactions.any((e) => e.id == occurrenceId)
          ? profile.transactions
          : [...profile.transactions, entry],
      recurrings: replace(
        profile.recurrings,
        rule.copyWith(
          nextDue: next,
          enabled: rule.end == null || !next.isAfter(rule.end!),
        ),
        (r) => r.id,
      ),
    );
  });
  Future<void> upsertBill(Bill item) => updateProfile((profile, app) {
    final previous = profile.bills
        .where((bill) => bill.id == item.id)
        .firstOrNull;
    if (previous != null &&
        previous.shares.any(
          (share) => share.personId != previous.paidById && share.settled,
        )) {
      require(
        previous.totalMinor == item.totalMinor &&
            previous.paidById == item.paidById &&
            previous.shares.length == item.shares.length &&
            previous.shares.every(
              (old) => item.shares.any(
                (next) =>
                    old.personId == next.personId &&
                    old.amountMinor == next.amountMinor &&
                    (!old.settled || next.settled),
              ),
            ),
        'Keep participant amounts and payer unchanged after settlement. Add an adjustment bill instead.',
      );
    }
    if (!app.settings.isPro &&
        !profile.bills.any((bill) => bill.id == item.id) &&
        profile.bills.length >= freeBillLimit) {
      throw const PremiumRequired('unlimited split bills');
    }
    return profile.copyWith(
      bills: replace(profile.bills, item, (item) => item.id),
    );
  });
  Future<void> settleBill(
    String billId,
    String personId, {
    bool createLoan = false,
  }) => updateProfile((profile, app) {
    final bill = profile.bills.firstWhere((item) => item.id == billId);
    final share = bill.shares.firstWhere((item) => item.personId == personId);
    require(!share.settled, 'This share is already settled');
    require(
      !createLoan || bill.paidById == 'me' || personId == 'me',
      'Only personal debts can be added to your loan ledger',
    );
    final loans = [...profile.loans];
    final partnerId = bill.paidById == 'me' ? share.personId : bill.paidById;
    final linkedPerson =
        profile.entities.any(
          (item) => item.id == partnerId && item.kind == 'person',
        )
        ? partnerId
        : '';
    if (createLoan && share.amountMinor > 0 && personId != bill.paidById) {
      loans.add(
        Loan(
          id: uuid.v4(),
          personName: bill.paidById == 'me' ? share.name : bill.paidByName,
          personId: linkedPerson,
          principalMinor: share.amountMinor,
          due: DateTime.now().add(const Duration(days: 30)),
          direction: bill.paidById == 'me' ? 'lent' : 'borrowed',
          notes: 'Split bill: ${bill.title}',
        ),
      );
    }
    return profile.copyWith(
      loans: loans,
      bills: [
        for (final item in profile.bills)
          if (item.id == billId)
            item.copyWith(
              shares: [
                for (final participant in item.shares)
                  if (participant.personId == personId)
                    participant.copyWith(settled: true)
                  else
                    participant,
              ],
            )
          else
            item,
      ],
    );
  });
  Future<void> deleteBill(String id) => updateProfile(
    (profile, app) => profile.copyWith(
      bills: profile.bills.where((item) => item.id != id).toList(),
    ),
  );
  Future<void> setRate(ExchangeRate item) => updateProfile((profile, app) {
    require(
      item.code != 'USD' || item.perUsd == 1,
      'USD is the reference and must stay at 1',
    );
    return profile.copyWith(
      rates: [
        for (final rate in profile.rates)
          if (rate.code == item.code) item else rate,
      ],
    );
  });
  Future<void> importTransactions(List<MoneyTransaction> items) =>
      updateProfile((profile, app) {
        final ids = profile.transactions.map((entry) => entry.id).toSet();
        return profile.copyWith(
          transactions: [
            ...profile.transactions,
            ...items.where((entry) => ids.add(entry.id)),
          ],
        );
      });
  Future<void> markNotifications(List<String> marks) => updateProfile(
    (profile, app) => profile.copyWith(
      notificationMarks: {
        ...profile.notificationMarks,
        ...marks,
      }.toList().reversed.take(512).toList().reversed.toList(),
    ),
  );
}

List<T> replace<T>(List<T> items, T item, String Function(T) key) =>
    items.any((existing) => key(existing) == key(item))
    ? [
        for (final existing in items)
          if (key(existing) == key(item)) item else existing,
      ]
    : [...items, item];

class _DemoRepository implements AppRepository {
  AppData data;
  _DemoRepository(this.data);
  @override
  AppData get initial => data;
  @override
  Future<void> save(AppData value) async {
    validateData(value);
    data = value;
  }
}

// Only repayments explicitly created by the repayment action have this link.
// Arbitrary loan-tagged purchases/disbursements must never become repayments.
ProfileData _syncLoanEntries(
  ProfileData profile,
  List<MoneyTransaction> entries,
  AppSettings settings, {
  String? changedId,
}) {
  final ledger = Ledger(profile.copyWith(transactions: entries), settings);
  final oldById = {for (final entry in profile.transactions) entry.id: entry};
  final byId = {for (final entry in entries) entry.id: entry};
  return profile.copyWith(
    transactions: entries,
    loans: [
      for (final loan in profile.loans)
        loan.copyWith(
          repayments: [
            for (final event in loan.repayments)
              if (event.transactionId.isEmpty)
                event
              else if (byId[event.transactionId] case final entry?
                  when entry.loanId == loan.id &&
                      entry.type ==
                          (loan.direction == 'lent' ? 'income' : 'expense'))
                if (entry.id != changedId)
                  event
                else
                  event.copyWith(
                    amountMinor:
                        oldById[entry.id]?.amountMinor == entry.amountMinor &&
                            oldById[entry.id]?.accountId == entry.accountId
                        ? event.amountMinor
                        : ledger.entryValue(entry),
                    date: entry.date,
                    note: entry.notes,
                  ),
          ],
        ),
    ],
  );
}
