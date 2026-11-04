import 'package:paisaclone/core/data/local_store.dart';
import 'package:paisaclone/core/data/seed.dart';
import 'package:paisaclone/core/models/models.dart';

class MemoryRepository implements AppRepository {
  @override
  final AppData initial;
  AppData? persisted;
  bool failNext = false;
  int writes = 0;
  MemoryRepository(this.initial);
  @override
  Future<void> save(AppData data) async {
    await Future<void>.delayed(Duration.zero);
    if (failNext) {
      failNext = false;
      throw StateError('Simulated full disk');
    }
    persisted = data;
    writes++;
  }
}

ProfileData fixture() => seedProfile(
  name: 'Test',
  currency: 'USD',
  accountName: 'Everyday',
  openingMinor: 100000,
  clock: DateTime(2026, 1, 1),
);
AppData appFor(
  ProfileData data, {
  AppSettings settings = const AppSettings(),
}) => AppData(
  profiles: [data],
  activeProfileId: data.profile.id,
  settings: settings,
);
MoneyTransaction expense(
  ProfileData data, {
  String id = 'expense',
  int amount = 1250,
  DateTime? date,
  String type = 'expense',
}) => MoneyTransaction(
  id: id,
  name: type == 'expense' ? 'Coffee' : 'Salary',
  type: type,
  amountMinor: amount,
  accountId: data.accounts.first.id,
  categoryId: data.categories.firstWhere((item) => item.type == type).id,
  date: date ?? DateTime(2026, 1, 5),
);
