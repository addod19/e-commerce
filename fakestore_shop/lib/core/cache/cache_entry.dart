class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;

  CacheEntry({required this.data, required this.cachedAt});

  bool isFresh(Duration ttl, DateTime now) => now.difference(cachedAt) < ttl;
}