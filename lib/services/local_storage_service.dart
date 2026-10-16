import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService(this._preferences);

  final SharedPreferences _preferences;

  static const String watchedRepositoriesKey = 'local_watched_repositories';

  bool hasCollection(String key) => _preferences.containsKey(key);

  List<Map<String, dynamic>> readCollection(String key) {
    final raw = _preferences.getStringList(key);
    if (raw == null) return [];
    return raw.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  Future<void> writeCollection(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final encoded = items.map(jsonEncode).toList();
    await _preferences.setStringList(key, encoded);
  }
}
