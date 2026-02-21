import 'package:flutter_test/flutter_test.dart';
import 'package:fakestore_shop/core/cache/cache_entry.dart';

void main() {
  test('CacheEntry freshness respects ttl', () {
    final now = DateTime(2026, 2, 21, 12, 0);

    final fresh = CacheEntry<List<int>>(
      data: const [1, 2, 3],
      cachedAt: now.subtract(const Duration(minutes: 5)),
    );
    final stale = CacheEntry<List<int>>(
      data: const [1, 2, 3],
      cachedAt: now.subtract(const Duration(minutes: 30)),
    );

    expect(fresh.isFresh(const Duration(minutes: 20), now), isTrue);
    expect(stale.isFresh(const Duration(minutes: 20), now), isFalse);
  });
}
