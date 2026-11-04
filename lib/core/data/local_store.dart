import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'validation.dart';

/// One durable snapshot is the atomic unit. In particular, transfers and split
/// settlements are never persisted as independent debits and credits.
abstract class AppRepository {
  AppData get initial;
  Future<void> save(AppData data);
}

class LocalStore implements AppRepository {
  final Box<String> box;
  @override
  final AppData initial;
  LocalStore(this.box, this.initial);
  static Future<LocalStore> open({bool recoverPrevious = false}) async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>('paisaclone_v1');
    final raw = box.get(recoverPrevious ? 'previous' : 'state');
    if (recoverPrevious && raw == null) {
      throw const FormatException('No previous snapshot is available');
    }
    final data = raw == null
        ? const AppData()
        : AppData.fromJson(readMap(jsonDecode(raw)));
    validateData(data);
    if (recoverPrevious) await box.put('state', raw!);
    return LocalStore(box, data);
  }

  @override
  Future<void> save(AppData data) async {
    validateData(data);
    final raw = jsonEncode(data.toJson());
    final previous = box.get('state');
    if (previous != null) await box.put('previous', previous);
    await box.put('state', raw);
    await box.flush();
  }
}
