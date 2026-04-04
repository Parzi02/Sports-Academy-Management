import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(DatabaseService());
});

class StorageService {
  final DatabaseService _databaseService;

  StorageService(this._databaseService);

  Future<void> save(String key, dynamic value) async {
    final String jsonValue = jsonEncode(value);
    await _databaseService.saveCache(key, jsonValue);
  }

  Future<dynamic> get(String key) async {
    final String? jsonValue = await _databaseService.getCache(key);
    if (jsonValue != null) {
      return jsonDecode(jsonValue);
    }
    return null;
  }

  Future<void> remove(String key) async {
    await _databaseService.clearCache(key);
  }

  Future<void> clearAll() async {
    await _databaseService.clearAllCache();
  }
}
