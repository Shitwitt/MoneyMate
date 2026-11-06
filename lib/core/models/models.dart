// Explicit JSON models: no generated adapters, platform types, or floating-point money.
// Monetary values are integer minor units in the associated account/profile currency.
import '../utils/constants.dart' show defaultHomeCards;

typedef Json = Map<String, dynamic>;

Json readMap(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object');
  return Map<String, dynamic>.from(value);
}

String readString(Object? value, [String fallback = '']) =>
    value == null ? fallback : value as String;
int readInt(Object? value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is! int) {
    throw const FormatException('Expected an integer minor-unit value');
  }
  return value;
}

double readDouble(Object? value, [double fallback = 0]) =>
    value == null ? fallback : (value as num).toDouble();
bool readBool(Object? value, [bool fallback = false]) =>
    value == null ? fallback : value as bool;
DateTime readDate(Object? value) {
  final text = value as String;
  final parts = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.\d{1,6})?)?(?:Z|[+-]\d{2}:?\d{2})?)?$',
  ).firstMatch(text);
  if (parts == null) {
    throw const FormatException('Use an ISO date (YYYY-MM-DD)');
  }
  final year = int.parse(parts[1]!),
      month = int.parse(parts[2]!),
      day = int.parse(parts[3]!);
  final calendar = DateTime.utc(year, month, day);
  if (calendar.year != year ||
      calendar.month != month ||
      calendar.day != day ||
      int.parse(parts[4] ?? '0') > 23 ||
      int.parse(parts[5] ?? '0') > 59 ||
      int.parse(parts[6] ?? '0') > 59) {
    throw const FormatException('Invalid calendar date or time');
  }
  return DateTime.parse(text);
}

DateTime? readOptionalDate(Object? value) =>
    value == null ? null : readDate(value);
List<String> readStrings(Object? value, [List<String> fallback = const []]) =>
    value == null ? List.of(fallback) : List<String>.from(value as List);
List<T> readModels<T>(Object? value, T Function(Json) parse) => value == null
    ? []
    : (value as List).map((item) => parse(readMap(item))).toList();

class Profile {
  final String id;
  final String name;
  final String currency;
  final DateTime createdAt;
  final int color;

  const Profile({
    required this.id,
    required this.name,
    required this.currency,
    required this.createdAt,
    this.color = 0xff916cff,
  });

  factory Profile.fromJson(Json json) => Profile(
    id: readString(json['id']),
    name: readString(json['name']),
    currency: readString(json['currency']),
    createdAt: readDate(json['createdAt']),
    color: readInt(json['color'], 0xff916cff),
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'currency': currency,
    'createdAt': createdAt.toIso8601String(),
    'color': color,
  };

  Profile copyWith({
    String? id,
    String? name,
    String? currency,
    DateTime? createdAt,
    int? color,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    createdAt: createdAt ?? this.createdAt,
    color: color ?? this.color,
  );
}

class Account {
  final String id;
  final String name;
  final String currency;
  final String type;
  final int openingMinor;
  final int color;
  final String icon;
  final String notes;
  final String holderName, lastDigits, parentId;
  final bool excluded;
  final bool archived;
  final String imageBase64;
  final String cardStyle;

  const Account({
    required this.id,
    required this.name,
    required this.currency,
    this.type = 'bank',
    this.openingMinor = 0,
    this.color = 0xff916cff,
    this.icon = 'bank',
    this.notes = '',
    this.holderName = '',
    this.lastDigits = '',
    this.parentId = '',
    this.excluded = false,
    this.archived = false,
    this.imageBase64 = '',
    this.cardStyle = 'auto',
  });

  factory Account.fromJson(Json json) => Account(
    id: readString(json['id']),
    name: readString(json['name']),
    currency: readString(json['currency']),
    type: readString(json['type'], 'bank'),
    openingMinor: readInt(json['openingMinor'], 0),
    color: readInt(json['color'], 0xff916cff),
    icon: readString(json['icon'], 'bank'),
    notes: readString(json['notes'], ''),
    holderName: readString(json['holderName'], ''),
    lastDigits: readString(json['lastDigits'], ''),
    parentId: readString(json['parentId'], ''),
    excluded: readBool(json['excluded'], false),
    archived: readBool(json['archived'], false),
    imageBase64: readString(json['imageBase64'], ''),
    cardStyle: readString(json['cardStyle'], 'auto'),
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'currency': currency,
    'type': type,
    'openingMinor': openingMinor,
    'color': color,
    'icon': icon,
    'notes': notes,
    'holderName': holderName,
    'lastDigits': lastDigits,
    'parentId': parentId,
    'excluded': excluded,
    'archived': archived,
    'imageBase64': imageBase64,
    'cardStyle': cardStyle,
  };

  Account copyWith({
    String? id,
    String? name,
    String? currency,
    String? type,
    int? openingMinor,
    int? color,
    String? icon,
    String? notes,
    String? holderName,
    String? lastDigits,
    String? parentId,
    bool? excluded,
    bool? archived,
    String? imageBase64,
    String? cardStyle,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    type: type ?? this.type,
    openingMinor: openingMinor ?? this.openingMinor,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    notes: notes ?? this.notes,
    holderName: holderName ?? this.holderName,
    lastDigits: lastDigits ?? this.lastDigits,
    parentId: parentId ?? this.parentId,
    excluded: excluded ?? this.excluded,
    archived: archived ?? this.archived,
    imageBase64: imageBase64 ?? this.imageBase64,
    cardStyle: cardStyle ?? this.cardStyle,
  );
}

class Category {
  final String id;
  final String name;
  final String type;
  final String icon;
  final String parentId;
  final int color;
  final bool hidden;
  final int order;

  const Category({
    required this.id,
    required this.name,
    this.type = 'expense',
    this.icon = 'category',
    this.parentId = '',
    this.color = 0xff916cff,
    this.hidden = false,
    this.order = 0,
  });

  factory Category.fromJson(Json json) => Category(
    id: readString(json['id']),
    name: readString(json['name']),
    type: readString(json['type'], 'expense'),
    icon: readString(json['icon'], 'category'),
    parentId: readString(json['parentId'], ''),
    color: readInt(json['color'], 0xff916cff),
    hidden: readBool(json['hidden'], false),
    order: readInt(json['order'], 0),
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'icon': icon,
    'parentId': parentId,
    'color': color,
    'hidden': hidden,
    'order': order,
  };

  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    String? parentId,
    int? color,
    bool? hidden,
    int? order,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    icon: icon ?? this.icon,
    parentId: parentId ?? this.parentId,
    color: color ?? this.color,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
  );
}

class Receipt {
  final String id;
  final String name;
  final String mime;
  final String data;

  const Receipt({
    required this.id,
    required this.name,
    required this.mime,
    required this.data,
  });

  factory Receipt.fromJson(Json json) => Receipt(
    id: readString(json['id']),
    name: readString(json['name']),
    mime: readString(json['mime']),
    data: readString(json['data']),
  );

  Json toJson() => {'id': id, 'name': name, 'mime': mime, 'data': data};

  Receipt copyWith({String? id, String? name, String? mime, String? data}) =>
      Receipt(
        id: id ?? this.id,
        name: name ?? this.name,
        mime: mime ?? this.mime,
        data: data ?? this.data,
      );
}

class MoneyTransaction {
  final String id;
  final String name;
  final String type;
  final int amountMinor;
  final String accountId;
  final DateTime date;
  final String categoryId;
  final String toAccountId;
  final int toAmountMinor;
  final String notes;
  final List<String> labelIds;
  final List<String> personIds;
  final String placeId;
  final String goalId;
  final String loanId;
  final List<Receipt> receipts;
  final String recurringId;
  final String budgetId;
  final DateTime? createdAt;

  const MoneyTransaction({
    required this.id,
    required this.name,
    required this.type,
    required this.amountMinor,
    required this.accountId,
    required this.date,
    this.categoryId = '',
    this.toAccountId = '',
    this.toAmountMinor = 0,
    this.notes = '',
    this.labelIds = const [],
    this.personIds = const [],
    this.placeId = '',
    this.goalId = '',
    this.loanId = '',
    this.receipts = const [],
    this.recurringId = '',
    this.budgetId = '',
    this.createdAt,
  });

  factory MoneyTransaction.fromJson(Json json) => MoneyTransaction(
    id: readString(json['id']),
    name: readString(json['name']),
    type: readString(json['type']),
    amountMinor: readInt(json['amountMinor']),
    accountId: readString(json['accountId']),
    date: readDate(json['date']),
    categoryId: readString(json['categoryId'], ''),
    toAccountId: readString(json['toAccountId'], ''),
    toAmountMinor: readInt(json['toAmountMinor'], 0),
    notes: readString(json['notes'], ''),
    labelIds: readStrings(json['labelIds'], const []),
    personIds: readStrings(json['personIds'], const []),
    placeId: readString(json['placeId'], ''),
    goalId: readString(json['goalId'], ''),
    loanId: readString(json['loanId'], ''),
    receipts: readModels(json['receipts'], Receipt.fromJson),
    recurringId: readString(json['recurringId'], ''),
    budgetId: readString(json['budgetId'], ''),
    createdAt: readOptionalDate(json['createdAt']),
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'amountMinor': amountMinor,
    'accountId': accountId,
    'date': date.toIso8601String(),
    'categoryId': categoryId,
    'toAccountId': toAccountId,
    'toAmountMinor': toAmountMinor,
    'notes': notes,
    'labelIds': labelIds,
    'personIds': personIds,
    'placeId': placeId,
    'goalId': goalId,
    'loanId': loanId,
    'receipts': receipts.map((item) => item.toJson()).toList(),
    'recurringId': recurringId,
    'budgetId': budgetId,
    'createdAt': createdAt?.toIso8601String(),
  };

  MoneyTransaction copyWith({
    String? id,
    String? name,
    String? type,
    int? amountMinor,
    String? accountId,
    DateTime? date,
    String? categoryId,
    String? toAccountId,
    int? toAmountMinor,
    String? notes,
    List<String>? labelIds,
    List<String>? personIds,
    String? placeId,
    String? goalId,
    String? loanId,
    List<Receipt>? receipts,
    String? recurringId,
    String? budgetId,
    DateTime? createdAt,
  }) => MoneyTransaction(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    amountMinor: amountMinor ?? this.amountMinor,
    accountId: accountId ?? this.accountId,
    date: date ?? this.date,
    categoryId: categoryId ?? this.categoryId,
    toAccountId: toAccountId ?? this.toAccountId,
    toAmountMinor: toAmountMinor ?? this.toAmountMinor,
    notes: notes ?? this.notes,
    labelIds: labelIds ?? this.labelIds,
    personIds: personIds ?? this.personIds,
    placeId: placeId ?? this.placeId,
    goalId: goalId ?? this.goalId,
    loanId: loanId ?? this.loanId,
    receipts: receipts ?? this.receipts,
    recurringId: recurringId ?? this.recurringId,
    budgetId: budgetId ?? this.budgetId,
    createdAt: createdAt ?? this.createdAt,
  );
}

class Budget {
  final String id, name, period, transactionType, mode, icon;
  final int limitMinor, color;
  final DateTime start;
  final DateTime? end;
  final List<String> categoryIds;
  final bool rollover, excludeCategories, includeSubcategories, showOnHome;

  const Budget({
    required this.id,
    required this.name,
    required this.limitMinor,
    required this.start,
    this.categoryIds = const [],
    this.period = 'monthly',
    this.end,
    this.rollover = false,
    this.color = 0xff916cff,
    this.transactionType = 'expense',
    this.mode = 'automatic',
    this.excludeCategories = false,
    this.includeSubcategories = true,
    this.showOnHome = true,
    this.icon = 'savings',
  });

  bool get overall => excludeCategories || categoryIds.isEmpty;
  bool get income => transactionType == 'income';

  factory Budget.fromJson(Json json) => Budget(
    id: readString(json['id']),
    name: readString(json['name']),
    limitMinor: readInt(json['limitMinor']),
    start: readDate(json['start']),
    categoryIds: readStrings(json['categoryIds'], const []),
    period: readString(json['period'], 'monthly'),
    end: readOptionalDate(json['end']),
    rollover: readBool(json['rollover'], false),
    color: readInt(json['color'], 0xff916cff),
    transactionType: readString(json['transactionType'], 'expense'),
    mode: readString(json['mode'], 'automatic'),
    excludeCategories: readBool(json['excludeCategories'], false),
    includeSubcategories: readBool(json['includeSubcategories'], true),
    showOnHome: readBool(json['showOnHome'], true),
    icon: readString(json['icon'], 'savings'),
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'limitMinor': limitMinor,
    'start': start.toIso8601String(),
    'categoryIds': categoryIds,
    'period': period,
    'end': end?.toIso8601String(),
    'rollover': rollover,
    'color': color,
    'transactionType': transactionType,
    'mode': mode,
    'excludeCategories': excludeCategories,
    'includeSubcategories': includeSubcategories,
    'showOnHome': showOnHome,
    'icon': icon,
  };

  Budget copyWith({
    String? id,
    String? name,
    int? limitMinor,
    DateTime? start,
    List<String>? categoryIds,
    String? period,
    DateTime? end,
    bool? rollover,
    int? color,
    String? transactionType,
    String? mode,
    bool? excludeCategories,
    bool? includeSubcategories,
    bool? showOnHome,
    String? icon,
  }) => Budget(
    id: id ?? this.id,
    name: name ?? this.name,
    limitMinor: limitMinor ?? this.limitMinor,
    start: start ?? this.start,
    categoryIds: categoryIds ?? this.categoryIds,
    period: period ?? this.period,
    end: end ?? this.end,
    rollover: rollover ?? this.rollover,
    color: color ?? this.color,
    transactionType: transactionType ?? this.transactionType,
    mode: mode ?? this.mode,
    excludeCategories: excludeCategories ?? this.excludeCategories,
    includeSubcategories: includeSubcategories ?? this.includeSubcategories,
    showOnHome: showOnHome ?? this.showOnHome,
    icon: icon ?? this.icon,
  );
}

class MoneyEvent {
  final String id;
  final int amountMinor;
  final DateTime date;
  final String note;
  final String transactionId;

  const MoneyEvent({
    required this.id,
    required this.amountMinor,
    required this.date,
    this.note = '',
    this.transactionId = '',
  });

  factory MoneyEvent.fromJson(Json json) => MoneyEvent(
    id: readString(json['id']),
    amountMinor: readInt(json['amountMinor']),
    date: readDate(json['date']),
    note: readString(json['note'], ''),
    transactionId: readString(json['transactionId'], ''),
  );

  Json toJson() => {
    'id': id,
    'amountMinor': amountMinor,
    'date': date.toIso8601String(),
    'note': note,
    'transactionId': transactionId,
  };

  MoneyEvent copyWith({
    String? id,
    int? amountMinor,
    DateTime? date,
    String? note,
    String? transactionId,
  }) => MoneyEvent(
    id: id ?? this.id,
    amountMinor: amountMinor ?? this.amountMinor,
    date: date ?? this.date,
    note: note ?? this.note,
    transactionId: transactionId ?? this.transactionId,
  );
}

class Goal {
  final String id;
  final String name;
  final int targetMinor;
  final DateTime deadline;
  final DateTime? start;
  final bool archived;
  final String accountId;
  final String icon;
  final String photoBase64;
  final int color;
  final List<MoneyEvent> contributions;

  const Goal({
    required this.id,
    required this.name,
    required this.targetMinor,
    required this.deadline,
    this.start,
    this.archived = false,
    this.accountId = '',
    this.icon = 'goal',
    this.photoBase64 = '',
    this.color = 0xffb2a4e7,
    this.contributions = const [],
  });

  factory Goal.fromJson(Json json) => Goal(
    id: readString(json['id']),
    name: readString(json['name']),
    targetMinor: readInt(json['targetMinor']),
    deadline: readDate(json['deadline']),
    start: readOptionalDate(json['start']),
    archived: readBool(json['archived']),
    accountId: readString(json['accountId'], ''),
    icon: readString(json['icon'], 'goal'),
    photoBase64: readString(json['photoBase64'], ''),
    color: readInt(json['color'], 0xffb2a4e7),
    contributions: readModels(json['contributions'], MoneyEvent.fromJson),
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'targetMinor': targetMinor,
    'deadline': deadline.toIso8601String(),
    'start': start?.toIso8601String(),
    'archived': archived,
    'accountId': accountId,
    'icon': icon,
    'photoBase64': photoBase64,
    'color': color,
    'contributions': contributions.map((item) => item.toJson()).toList(),
  };

  Goal copyWith({
    String? id,
    String? name,
    int? targetMinor,
    DateTime? deadline,
    DateTime? start,
    bool? archived,
    String? accountId,
    String? icon,
    String? photoBase64,
    int? color,
    List<MoneyEvent>? contributions,
  }) => Goal(
    id: id ?? this.id,
    name: name ?? this.name,
    targetMinor: targetMinor ?? this.targetMinor,
    deadline: deadline ?? this.deadline,
    start: start ?? this.start,
    archived: archived ?? this.archived,
    accountId: accountId ?? this.accountId,
    icon: icon ?? this.icon,
    photoBase64: photoBase64 ?? this.photoBase64,
    color: color ?? this.color,
    contributions: contributions ?? this.contributions,
  );
}

class Loan {
  final DateTime? start;
  final String icon, accountId, categoryId;
  final int color;
  final bool completed;
  final String id;
  final String personName;
  final int principalMinor;
  final DateTime due;
  final String direction;
  final String personId;
  final double interestPercent;
  final String notes;
  final List<MoneyEvent> repayments;

  const Loan({
    required this.id,
    required this.personName,
    required this.principalMinor,
    required this.due,
    this.start,
    this.icon = 'loan',
    this.accountId = '',
    this.categoryId = '',
    this.color = 0xffe991a7,
    this.completed = false,
    this.direction = 'lent',
    this.personId = '',
    this.interestPercent = 0,
    this.notes = '',
    this.repayments = const [],
  });

  factory Loan.fromJson(Json json) => Loan(
    id: readString(json['id']),
    personName: readString(json['personName']),
    principalMinor: readInt(json['principalMinor']),
    due: readDate(json['due']),
    start: readOptionalDate(json['start']),
    icon: readString(json['icon'], 'loan'),
    accountId: readString(json['accountId'], ''),
    categoryId: readString(json['categoryId'], ''),
    color: readInt(json['color'], 0xffe991a7),
    completed: readBool(json['completed']),
    direction: readString(json['direction'], 'lent'),
    personId: readString(json['personId'], ''),
    interestPercent: readDouble(json['interestPercent'], 0),
    notes: readString(json['notes'], ''),
    repayments: readModels(json['repayments'], MoneyEvent.fromJson),
  );

  Json toJson() => {
    'id': id,
    'personName': personName,
    'principalMinor': principalMinor,
    'due': due.toIso8601String(),
    'start': start?.toIso8601String(),
    'icon': icon,
    'accountId': accountId,
    'categoryId': categoryId,
    'color': color,
    'completed': completed,
    'direction': direction,
    'personId': personId,
    'interestPercent': interestPercent,
    'notes': notes,
    'repayments': repayments.map((item) => item.toJson()).toList(),
  };

  Loan copyWith({
    String? id,
    String? personName,
    int? principalMinor,
    DateTime? due,
    DateTime? start,
    String? icon,
    String? accountId,
    String? categoryId,
    int? color,
    bool? completed,
    String? direction,
    String? personId,
    double? interestPercent,
    String? notes,
    List<MoneyEvent>? repayments,
  }) => Loan(
    id: id ?? this.id,
    personName: personName ?? this.personName,
    principalMinor: principalMinor ?? this.principalMinor,
    due: due ?? this.due,
    start: start ?? this.start,
    icon: icon ?? this.icon,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    color: color ?? this.color,
    completed: completed ?? this.completed,
    direction: direction ?? this.direction,
    personId: personId ?? this.personId,
    interestPercent: interestPercent ?? this.interestPercent,
    notes: notes ?? this.notes,
    repayments: repayments ?? this.repayments,
  );
}

class Recurring {
  final String id, name, accountId, categoryId, type, frequency, notes;
  final int amountMinor, interval, reminderDays;
  final DateTime start, nextDue;
  final DateTime? end;
  final bool autoPost, enabled, archived;
  final String budgetId, placeId;
  final List<String> labelIds, personIds;

  const Recurring({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.accountId,
    required this.categoryId,
    required this.start,
    required this.nextDue,
    this.type = 'expense',
    this.frequency = 'monthly',
    this.interval = 1,
    this.end,
    this.autoPost = true,
    this.enabled = true,
    this.archived = false,
    this.notes = '',
    this.reminderDays = 0,
    this.budgetId = '',
    this.placeId = '',
    this.labelIds = const [],
    this.personIds = const [],
  });
  factory Recurring.fromJson(Json json) => Recurring(
    id: readString(json['id']),
    name: readString(json['name']),
    amountMinor: readInt(json['amountMinor']),
    accountId: readString(json['accountId']),
    categoryId: readString(json['categoryId']),
    start: readDate(json['start']),
    nextDue: readDate(json['nextDue']),
    type: readString(json['type'], 'expense'),
    frequency: readString(json['frequency'], 'monthly'),
    interval: readInt(json['interval'], 1),
    end: readOptionalDate(json['end']),
    autoPost: readBool(json['autoPost'], true),
    enabled: readBool(json['enabled'], true),
    archived: readBool(json['archived'], false),
    notes: readString(json['notes'], ''),
    reminderDays: readInt(json['reminderDays']),
    budgetId: readString(json['budgetId'], ''),
    placeId: readString(json['placeId'], ''),
    labelIds: readStrings(json['labelIds'], const []),
    personIds: readStrings(json['personIds'], const []),
  );
  Json toJson() => {
    'id': id,
    'name': name,
    'amountMinor': amountMinor,
    'accountId': accountId,
    'categoryId': categoryId,
    'start': start.toIso8601String(),
    'nextDue': nextDue.toIso8601String(),
    'type': type,
    'frequency': frequency,
    'interval': interval,
    'end': end?.toIso8601String(),
    'autoPost': autoPost,
    'enabled': enabled,
    'archived': archived,
    'notes': notes,
    'reminderDays': reminderDays,
    'budgetId': budgetId,
    'placeId': placeId,
    'labelIds': labelIds,
    'personIds': personIds,
  };
  Recurring copyWith({
    String? id,
    String? name,
    int? amountMinor,
    String? accountId,
    String? categoryId,
    DateTime? start,
    DateTime? nextDue,
    String? type,
    String? frequency,
    int? interval,
    DateTime? end,
    bool clearEnd = false,
    bool? autoPost,
    bool? enabled,
    bool? archived,
    String? notes,
    int? reminderDays,
    String? budgetId,
    String? placeId,
    List<String>? labelIds,
    List<String>? personIds,
  }) => Recurring(
    id: id ?? this.id,
    name: name ?? this.name,
    amountMinor: amountMinor ?? this.amountMinor,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    start: start ?? this.start,
    nextDue: nextDue ?? this.nextDue,
    type: type ?? this.type,
    frequency: frequency ?? this.frequency,
    interval: interval ?? this.interval,
    end: clearEnd ? null : end ?? this.end,
    autoPost: autoPost ?? this.autoPost,
    enabled: enabled ?? this.enabled,
    archived: archived ?? this.archived,
    notes: notes ?? this.notes,
    reminderDays: reminderDays ?? this.reminderDays,
    budgetId: budgetId ?? this.budgetId,
    placeId: placeId ?? this.placeId,
    labelIds: labelIds ?? this.labelIds,
    personIds: personIds ?? this.personIds,
  );
}

class Asset {
  final String id;
  final String name;
  final int valueMinor;
  final String type;
  final int purchaseMinor;
  final DateTime? purchaseDate;
  final String notes;
  final String icon;
  final int color;
  final List<MoneyEvent> history;

  const Asset({
    required this.id,
    required this.name,
    required this.valueMinor,
    this.type = 'other',
    this.purchaseMinor = 0,
    this.purchaseDate,
    this.notes = '',
    this.icon = 'asset',
    this.color = 0xffe7be7d,
    this.history = const [],
  });

  factory Asset.fromJson(Json json) => Asset(
    id: readString(json['id']),
    name: readString(json['name']),
    valueMinor: readInt(json['valueMinor']),
    type: readString(json['type'], 'other'),
    purchaseMinor: readInt(json['purchaseMinor'], 0),
    purchaseDate: readOptionalDate(json['purchaseDate']),
    notes: readString(json['notes'], ''),
    icon: readString(json['icon'], 'asset'),
    color: readInt(json['color'], 0xffe7be7d),
    history: readModels(json['history'], MoneyEvent.fromJson),
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'valueMinor': valueMinor,
    'type': type,
    'purchaseMinor': purchaseMinor,
    'purchaseDate': purchaseDate?.toIso8601String(),
    'notes': notes,
    'icon': icon,
    'color': color,
    'history': history.map((item) => item.toJson()).toList(),
  };

  Asset copyWith({
    String? id,
    String? name,
    int? valueMinor,
    String? type,
    int? purchaseMinor,
    DateTime? purchaseDate,
    String? notes,
    String? icon,
    int? color,
    List<MoneyEvent>? history,
  }) => Asset(
    id: id ?? this.id,
    name: name ?? this.name,
    valueMinor: valueMinor ?? this.valueMinor,
    type: type ?? this.type,
    purchaseMinor: purchaseMinor ?? this.purchaseMinor,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    notes: notes ?? this.notes,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    history: history ?? this.history,
  );
}

class NamedEntity {
  final String id;
  final String name;
  final String kind;
  final String icon;
  final int color;
  final String notes;
  final String photoBase64;

  const NamedEntity({
    required this.id,
    required this.name,
    required this.kind,
    this.icon = '',
    this.color = 0xff9ac4dd,
    this.notes = '',
    this.photoBase64 = '',
  });

  factory NamedEntity.fromJson(Json json) => NamedEntity(
    id: readString(json['id']),
    name: readString(json['name']),
    kind: readString(json['kind']),
    icon: readString(json['icon'], ''),
    color: readInt(json['color'], 0xff9ac4dd),
    notes: readString(json['notes'], ''),
    photoBase64: readString(json['photoBase64'], ''),
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'icon': icon,
    'color': color,
    'notes': notes,
    'photoBase64': photoBase64,
  };

  NamedEntity copyWith({
    String? id,
    String? name,
    String? kind,
    String? icon,
    int? color,
    String? notes,
    String? photoBase64,
  }) => NamedEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    notes: notes ?? this.notes,
    photoBase64: photoBase64 ?? this.photoBase64,
  );
}

class TransactionTemplate {
  final String id;
  final String name;
  final String type;
  final int amountMinor;
  final String accountId;
  final String categoryId;
  final String notes;
  final List<String> labelIds;

  const TransactionTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.amountMinor,
    required this.accountId,
    required this.categoryId,
    this.notes = '',
    this.labelIds = const [],
  });

  factory TransactionTemplate.fromJson(Json json) => TransactionTemplate(
    id: readString(json['id']),
    name: readString(json['name']),
    type: readString(json['type']),
    amountMinor: readInt(json['amountMinor']),
    accountId: readString(json['accountId']),
    categoryId: readString(json['categoryId']),
    notes: readString(json['notes'], ''),
    labelIds: readStrings(json['labelIds'], const []),
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'amountMinor': amountMinor,
    'accountId': accountId,
    'categoryId': categoryId,
    'notes': notes,
    'labelIds': labelIds,
  };

  TransactionTemplate copyWith({
    String? id,
    String? name,
    String? type,
    int? amountMinor,
    String? accountId,
    String? categoryId,
    String? notes,
    List<String>? labelIds,
  }) => TransactionTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    amountMinor: amountMinor ?? this.amountMinor,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    notes: notes ?? this.notes,
    labelIds: labelIds ?? this.labelIds,
  );
}

class BillShare {
  final String personId;
  final String name;
  final int amountMinor;
  final bool settled;

  const BillShare({
    required this.personId,
    required this.name,
    required this.amountMinor,
    this.settled = false,
  });

  factory BillShare.fromJson(Json json) => BillShare(
    personId: readString(json['personId']),
    name: readString(json['name']),
    amountMinor: readInt(json['amountMinor']),
    settled: readBool(json['settled'], false),
  );

  Json toJson() => {
    'personId': personId,
    'name': name,
    'amountMinor': amountMinor,
    'settled': settled,
  };

  BillShare copyWith({
    String? personId,
    String? name,
    int? amountMinor,
    bool? settled,
  }) => BillShare(
    personId: personId ?? this.personId,
    name: name ?? this.name,
    amountMinor: amountMinor ?? this.amountMinor,
    settled: settled ?? this.settled,
  );
}

class Bill {
  final String id;
  final String title;
  final int totalMinor;
  final DateTime date;
  final String paidById;
  final String paidByName;
  final String method;
  final List<BillShare> shares;

  const Bill({
    required this.id,
    required this.title,
    required this.totalMinor,
    required this.date,
    required this.paidById,
    required this.paidByName,
    this.method = 'equally',
    this.shares = const [],
  });

  factory Bill.fromJson(Json json) => Bill(
    id: readString(json['id']),
    title: readString(json['title']),
    totalMinor: readInt(json['totalMinor']),
    date: readDate(json['date']),
    paidById: readString(json['paidById']),
    paidByName: readString(json['paidByName']),
    method: readString(json['method'], 'equally'),
    shares: readModels(json['shares'], BillShare.fromJson),
  );

  Json toJson() => {
    'id': id,
    'title': title,
    'totalMinor': totalMinor,
    'date': date.toIso8601String(),
    'paidById': paidById,
    'paidByName': paidByName,
    'method': method,
    'shares': shares.map((item) => item.toJson()).toList(),
  };

  Bill copyWith({
    String? id,
    String? title,
    int? totalMinor,
    DateTime? date,
    String? paidById,
    String? paidByName,
    String? method,
    List<BillShare>? shares,
  }) => Bill(
    id: id ?? this.id,
    title: title ?? this.title,
    totalMinor: totalMinor ?? this.totalMinor,
    date: date ?? this.date,
    paidById: paidById ?? this.paidById,
    paidByName: paidByName ?? this.paidByName,
    method: method ?? this.method,
    shares: shares ?? this.shares,
  );
}

class Achievement {
  final String id;
  final DateTime unlockedAt;

  const Achievement({required this.id, required this.unlockedAt});

  factory Achievement.fromJson(Json json) => Achievement(
    id: readString(json['id']),
    unlockedAt: readDate(json['unlockedAt']),
  );

  Json toJson() => {'id': id, 'unlockedAt': unlockedAt.toIso8601String()};

  Achievement copyWith({String? id, DateTime? unlockedAt}) =>
      Achievement(id: id ?? this.id, unlockedAt: unlockedAt ?? this.unlockedAt);
}

class ExchangeRate {
  final String code;
  final double perUsd;
  final DateTime updatedAt;

  const ExchangeRate({
    required this.code,
    required this.perUsd,
    required this.updatedAt,
  });

  factory ExchangeRate.fromJson(Json json) => ExchangeRate(
    code: readString(json['code']),
    perUsd: readDouble(json['perUsd']),
    updatedAt: readDate(json['updatedAt']),
  );

  Json toJson() => {
    'code': code,
    'perUsd': perUsd,
    'updatedAt': updatedAt.toIso8601String(),
  };

  ExchangeRate copyWith({String? code, double? perUsd, DateTime? updatedAt}) =>
      ExchangeRate(
        code: code ?? this.code,
        perUsd: perUsd ?? this.perUsd,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

List<String> _restoreHomeLayout(Json json) {
  final saved = readStrings(json['homeCards'], defaultHomeCards);
  final revision = readInt(json['uiRevision']);
  if (revision >= 3) return saved;
  if (revision == 2)
    return [
      ...saved,
      ...[
        'heatmap',
        'trend',
        'trackedBudgets',
        'upcoming',
      ].where((id) => !saved.contains(id)),
    ];
  const oldDefault = [
    'balance',
    'cashflow',
    'accounts',
    'trend',
    'budgets',
    'goals',
    'recent',
    'templates',
    'recurring',
    'assets',
    'loans',
    'reports',
    'achievements',
    'premium',
  ];
  if (saved.join('|') == oldDefault.join('|')) return List.of(defaultHomeCards);
  return [...saved, ...defaultHomeCards.where((id) => !saved.contains(id))];
}

List<String> _restoreNavigation(Json json) {
  final saved = readStrings(json['navTabs'], const [
    'home',
    'accounts',
    'reports',
    'search',
  ]);
  if (readInt(json['uiRevision']) < 2 &&
      saved.join('|') == 'home|accounts|transactions|plans|more') {
    return ['home', 'accounts', 'reports', 'search'];
  }
  return saved;
}

class AppSettings {
  final String theme;
  final int accent;
  final bool dynamicColors;
  final String locale;
  final bool hideAmounts;
  final String numberFormat;
  final int weekStart;
  final int monthStart;
  final double fontScale;
  final bool isPro;
  final List<String> homeCards;
  final List<String> hiddenCards;
  final List<String> navTabs;
  final bool navLabels;
  final String lockMode;
  final String pinHash;
  final String pinSalt;
  final bool notificationsEnabled;
  final bool budgetNotifications;
  final bool recurringNotifications;
  final bool loanNotifications;
  final bool backupReminders;
  final bool allowSilentAdds;
  final DateTime? lastBackup;

  const AppSettings({
    this.theme = 'dark',
    this.accent = 0xffffb59a,
    this.dynamicColors = false,
    this.locale = 'en',
    this.hideAmounts = false,
    this.numberFormat = 'international',
    this.weekStart = 1,
    this.monthStart = 1,
    this.fontScale = 1,
    this.isPro = false,
    this.homeCards = const [
      'balance',
      'cashflow',
      'accounts',
      'reports',
      'budgets',
      'assets',
      'splits',
      'loans',
      'goals',
      'labels',
      'analytics',
      'recurring',
      'categories',
      'weekly',
      'last30',
      'places',
      'people',
      'score',
      'achievements',
      'recent',
      'templates',
      'heatmap',
      'trend',
      'trackedBudgets',
      'upcoming',
    ],
    this.hiddenCards = const [],
    this.navTabs = const ['home', 'accounts', 'reports', 'search'],
    this.navLabels = true,
    this.lockMode = 'none',
    this.pinHash = '',
    this.pinSalt = '',
    this.notificationsEnabled = false,
    this.budgetNotifications = true,
    this.recurringNotifications = true,
    this.loanNotifications = true,
    this.backupReminders = false,
    this.allowSilentAdds = false,
    this.lastBackup,
  });

  factory AppSettings.fromJson(Json json) => AppSettings(
    theme: readString(json['theme'], 'dark'),
    accent:
        readInt(json['uiRevision']) < 2 &&
            [
              0xff557c36,
              0xff916cff,
            ].contains(readInt(json['accent'], 0xffffb59a))
        ? 0xffffb59a
        : readInt(json['accent'], 0xffffb59a),
    dynamicColors:
        readInt(json['uiRevision']) < 2 &&
            readInt(json['accent'], 0xff916cff) == 0xff557c36
        ? false
        : readBool(json['dynamicColors'], false),
    locale: readString(json['locale'], 'en'),
    hideAmounts: readBool(json['hideAmounts'], false),
    numberFormat: readString(json['numberFormat'], 'international'),
    weekStart: readInt(json['weekStart'], 1),
    monthStart: readInt(json['monthStart'], 1),
    fontScale: readDouble(json['fontScale'], 1),
    isPro: readBool(json['isPro'], false),
    homeCards: _restoreHomeLayout(json),
    hiddenCards: readStrings(json['hiddenCards'], const []),
    navTabs: _restoreNavigation(json),
    navLabels: readBool(json['navLabels'], true),
    lockMode: readString(json['lockMode'], 'none'),
    pinHash: readString(json['pinHash'], ''),
    pinSalt: readString(json['pinSalt'], ''),
    notificationsEnabled: readBool(json['notificationsEnabled'], false),
    budgetNotifications: readBool(json['budgetNotifications'], true),
    recurringNotifications: readBool(json['recurringNotifications'], true),
    loanNotifications: readBool(json['loanNotifications'], true),
    backupReminders: readBool(json['backupReminders'], false),
    allowSilentAdds: readBool(json['allowSilentAdds'], false),
    lastBackup: readOptionalDate(json['lastBackup']),
  );

  Json toJson() => {
    'uiRevision': 3,
    'theme': theme,
    'accent': accent,
    'dynamicColors': dynamicColors,
    'locale': locale,
    'hideAmounts': hideAmounts,
    'numberFormat': numberFormat,
    'weekStart': weekStart,
    'monthStart': monthStart,
    'fontScale': fontScale,
    'isPro': isPro,
    'homeCards': homeCards,
    'hiddenCards': hiddenCards,
    'navTabs': navTabs,
    'navLabels': navLabels,
    'lockMode': lockMode,
    'pinHash': pinHash,
    'pinSalt': pinSalt,
    'notificationsEnabled': notificationsEnabled,
    'budgetNotifications': budgetNotifications,
    'recurringNotifications': recurringNotifications,
    'loanNotifications': loanNotifications,
    'backupReminders': backupReminders,
    'allowSilentAdds': allowSilentAdds,
    'lastBackup': lastBackup?.toIso8601String(),
  };

  AppSettings copyWith({
    String? theme,
    int? accent,
    bool? dynamicColors,
    String? locale,
    bool? hideAmounts,
    String? numberFormat,
    int? weekStart,
    int? monthStart,
    double? fontScale,
    bool? isPro,
    List<String>? homeCards,
    List<String>? hiddenCards,
    List<String>? navTabs,
    bool? navLabels,
    String? lockMode,
    String? pinHash,
    String? pinSalt,
    bool? notificationsEnabled,
    bool? budgetNotifications,
    bool? recurringNotifications,
    bool? loanNotifications,
    bool? backupReminders,
    bool? allowSilentAdds,
    DateTime? lastBackup,
  }) => AppSettings(
    theme: theme ?? this.theme,
    accent: accent ?? this.accent,
    dynamicColors: dynamicColors ?? this.dynamicColors,
    locale: locale ?? this.locale,
    hideAmounts: hideAmounts ?? this.hideAmounts,
    numberFormat: numberFormat ?? this.numberFormat,
    weekStart: weekStart ?? this.weekStart,
    monthStart: monthStart ?? this.monthStart,
    fontScale: fontScale ?? this.fontScale,
    isPro: isPro ?? this.isPro,
    homeCards: homeCards ?? this.homeCards,
    hiddenCards: hiddenCards ?? this.hiddenCards,
    navTabs: navTabs ?? this.navTabs,
    navLabels: navLabels ?? this.navLabels,
    lockMode: lockMode ?? this.lockMode,
    pinHash: pinHash ?? this.pinHash,
    pinSalt: pinSalt ?? this.pinSalt,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    budgetNotifications: budgetNotifications ?? this.budgetNotifications,
    recurringNotifications:
        recurringNotifications ?? this.recurringNotifications,
    loanNotifications: loanNotifications ?? this.loanNotifications,
    backupReminders: backupReminders ?? this.backupReminders,
    allowSilentAdds: allowSilentAdds ?? this.allowSilentAdds,
    lastBackup: lastBackup ?? this.lastBackup,
  );
}

class ProfileData {
  final Profile profile;
  final List<Account> accounts;
  final List<Category> categories;
  final List<MoneyTransaction> transactions;
  final List<Budget> budgets;
  final List<Goal> goals;
  final List<Loan> loans;
  final List<Recurring> recurrings;
  final List<Asset> assets;
  final List<NamedEntity> entities;
  final List<TransactionTemplate> templates;
  final List<Bill> bills;
  final List<Achievement> achievements;
  final List<ExchangeRate> rates;
  final List<String> notificationMarks;

  const ProfileData({
    required this.profile,
    this.accounts = const [],
    this.categories = const [],
    this.transactions = const [],
    this.budgets = const [],
    this.goals = const [],
    this.loans = const [],
    this.recurrings = const [],
    this.assets = const [],
    this.entities = const [],
    this.templates = const [],
    this.bills = const [],
    this.achievements = const [],
    this.rates = const [],
    this.notificationMarks = const [],
  });

  factory ProfileData.fromJson(Json json) => ProfileData(
    profile: Profile.fromJson(readMap(json['profile'])),
    accounts: readModels(json['accounts'], Account.fromJson),
    categories: readModels(json['categories'], Category.fromJson),
    transactions: readModels(json['transactions'], MoneyTransaction.fromJson),
    budgets: readModels(json['budgets'], Budget.fromJson),
    goals: readModels(json['goals'], Goal.fromJson),
    loans: readModels(json['loans'], Loan.fromJson),
    recurrings: readModels(json['recurrings'], Recurring.fromJson),
    assets: readModels(json['assets'], Asset.fromJson),
    entities: readModels(json['entities'], NamedEntity.fromJson),
    templates: readModels(json['templates'], TransactionTemplate.fromJson),
    bills: readModels(json['bills'], Bill.fromJson),
    achievements: readModels(json['achievements'], Achievement.fromJson),
    rates: readModels(json['rates'], ExchangeRate.fromJson),
    notificationMarks: readStrings(json['notificationMarks'], const []),
  );

  Json toJson() => {
    'profile': profile.toJson(),
    'accounts': accounts.map((item) => item.toJson()).toList(),
    'categories': categories.map((item) => item.toJson()).toList(),
    'transactions': transactions.map((item) => item.toJson()).toList(),
    'budgets': budgets.map((item) => item.toJson()).toList(),
    'goals': goals.map((item) => item.toJson()).toList(),
    'loans': loans.map((item) => item.toJson()).toList(),
    'recurrings': recurrings.map((item) => item.toJson()).toList(),
    'assets': assets.map((item) => item.toJson()).toList(),
    'entities': entities.map((item) => item.toJson()).toList(),
    'templates': templates.map((item) => item.toJson()).toList(),
    'bills': bills.map((item) => item.toJson()).toList(),
    'achievements': achievements.map((item) => item.toJson()).toList(),
    'rates': rates.map((item) => item.toJson()).toList(),
    'notificationMarks': notificationMarks,
  };

  ProfileData copyWith({
    Profile? profile,
    List<Account>? accounts,
    List<Category>? categories,
    List<MoneyTransaction>? transactions,
    List<Budget>? budgets,
    List<Goal>? goals,
    List<Loan>? loans,
    List<Recurring>? recurrings,
    List<Asset>? assets,
    List<NamedEntity>? entities,
    List<TransactionTemplate>? templates,
    List<Bill>? bills,
    List<Achievement>? achievements,
    List<ExchangeRate>? rates,
    List<String>? notificationMarks,
  }) => ProfileData(
    profile: profile ?? this.profile,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    transactions: transactions ?? this.transactions,
    budgets: budgets ?? this.budgets,
    goals: goals ?? this.goals,
    loans: loans ?? this.loans,
    recurrings: recurrings ?? this.recurrings,
    assets: assets ?? this.assets,
    entities: entities ?? this.entities,
    templates: templates ?? this.templates,
    bills: bills ?? this.bills,
    achievements: achievements ?? this.achievements,
    rates: rates ?? this.rates,
    notificationMarks: notificationMarks ?? this.notificationMarks,
  );
}

class AppData {
  final bool isDemo;
  final List<ProfileData> profiles;
  final String activeProfileId;
  final AppSettings settings;
  final int schemaVersion;

  const AppData({
    this.isDemo = false,
    this.profiles = const [],
    this.activeProfileId = '',
    this.settings = const AppSettings(),
    this.schemaVersion = 1,
  });

  factory AppData.fromJson(Json json) => AppData(
    profiles: readModels(json['profiles'], ProfileData.fromJson),
    activeProfileId: readString(json['activeProfileId'], ''),
    settings: json['settings'] == null
        ? const AppSettings()
        : AppSettings.fromJson(readMap(json['settings'])),
    schemaVersion: readInt(json['schemaVersion'], 1),
  );

  Json toJson() => {
    'profiles': profiles.map((item) => item.toJson()).toList(),
    'activeProfileId': activeProfileId,
    'settings': settings.toJson(),
    'schemaVersion': schemaVersion,
  };

  AppData copyWith({
    bool? isDemo,
    List<ProfileData>? profiles,
    String? activeProfileId,
    AppSettings? settings,
    int? schemaVersion,
  }) => AppData(
    isDemo: isDemo ?? this.isDemo,
    profiles: profiles ?? this.profiles,
    activeProfileId: activeProfileId ?? this.activeProfileId,
    settings: settings ?? this.settings,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
}
