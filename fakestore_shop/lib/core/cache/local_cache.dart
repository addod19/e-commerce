import 'package:hive/hive.dart';
import 'cache_entry.dart';

class LocalCache {
  LocalCache(this._box);

  final Box _box;

  Future<CacheEntry<List<dynamic>>?> getList(String key) async {
    final raw = _box.get(key);
    if (raw is Map) {
      final data = raw['data'];
      final cachedAtMs = raw['cachedAt'] as int?;
      if (data is List && cachedAtMs != null) {
        return CacheEntry<List<dynamic>>(
          data: data,
          cachedAt: DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
        );
      }
    }
    return null;
  }

  Future<CacheEntry<Map<String, dynamic>>?> getMap(String key) async {
    final raw = _box.get(key);
    if (raw is Map) {
      final data = raw['data'];
      final cachedAtMs = raw['cachedAt'] as int?;
      if (data is Map && cachedAtMs != null) {
        return CacheEntry<Map<String, dynamic>>(
          data: Map<String, dynamic>.from(data),
          cachedAt: DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
        );
      }
    }
    return null;
  }

  Future<void> putList(String key, List<dynamic> data, {required DateTime cachedAt}) async {
    await _box.put(key, {
      'data': data,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
    });
  }

  Future<void> putMap(String key, Map<String, dynamic> data, {required DateTime cachedAt}) async {
    await _box.put(key, {
      'data': data,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
    });
  }

  Future<void> delete(String key) => _box.delete(key);
  Future<void> clear() => _box.clear();
}