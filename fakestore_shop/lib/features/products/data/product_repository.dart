import 'dart:async';
import '../../../core/cache/local_cache.dart';
import '../domain/product.dart';
import 'api_client.dart';

typedef NowFn = DateTime Function();

class OfflineException implements Exception {
  final String message;
  OfflineException(this.message);
  @override
  String toString() => message;
}

class ProductsRepository {
  ProductsRepository({
    required this.api,
    required this.cache,
    required this.isOnline,
    required this.now,
  });

  final ApiClient api;
  final LocalCache cache;
  final Future<bool> Function() isOnline;
  final NowFn now;

  final _inFlight = <String, Future<dynamic>>{};

  // TTLs (adjustable)
  static const productsTtl = Duration(minutes: 20);
  static const productTtl = Duration(minutes: 45);
  static const categoriesTtl = Duration(hours: 24);

  Future<List<Product>> getProducts() async {
    return _dedup('products_all', () async {
      final cached = await cache.getList('products_all');
      final online = await isOnline();
      final n = now();

      if (cached != null) {
        if (!cached.isFresh(productsTtl, n) && online) {
          unawaited(_refreshProducts());
        }
        return cached.data
            .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      if (!online) throw OfflineException('You are offline and no cached products exist.');
      final fresh = await api.getProducts();
      await cache.putList('products_all', fresh, cachedAt: n);
      return fresh.map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    });
  }

  Future<Product> getProduct(int id) async {
    return _dedup('product_$id', () async {
      final cached = await cache.getMap('product_$id');
      final online = await isOnline();
      final n = now();

      if (cached != null) {
        if (!cached.isFresh(productTtl, n) && online) {
          unawaited(_refreshProduct(id));
        }
        return Product.fromJson(cached.data);
      }

      if (!online) throw OfflineException('You are offline and no cached product exists.');
      final fresh = await api.getProduct(id);
      await cache.putMap('product_$id', fresh, cachedAt: n);
      return Product.fromJson(fresh);
    });
  }

  Future<List<String>> getCategories() async {
    return _dedup('categories', () async {
      final cached = await cache.getList('categories');
      final online = await isOnline();
      final n = now();

      if (cached != null) {
        if (!cached.isFresh(categoriesTtl, n) && online) {
          unawaited(_refreshCategories());
        }
        return cached.data.cast<String>();
      }

      if (!online) throw OfflineException('You are offline and no cached categories exist.');
      final fresh = await api.getCategories();
      await cache.putList('categories', fresh, cachedAt: n);
      return fresh.cast<String>();
    });
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final key = 'products_category_$category';
    return _dedup(key, () async {
      final cached = await cache.getList(key);
      final online = await isOnline();
      final n = now();

      if (cached != null) {
        if (!cached.isFresh(productsTtl, n) && online) {
          unawaited(_refreshProductsByCategory(category));
        }
        return cached.data
            .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      if (!online) throw OfflineException('You are offline and no cached data exists for this category.');
      final fresh = await api.getProductsByCategory(category);
      await cache.putList(key, fresh, cachedAt: n);
      return fresh.map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    });
  }

  Future<void> _refreshProducts() async {
    final n = now();
    final fresh = await api.getProducts();
    await cache.putList('products_all', fresh, cachedAt: n);
  }

  Future<void> _refreshProduct(int id) async {
    final n = now();
    final fresh = await api.getProduct(id);
    await cache.putMap('product_$id', fresh, cachedAt: n);
  }

  Future<void> _refreshCategories() async {
    final n = now();
    final fresh = await api.getCategories();
    await cache.putList('categories', fresh, cachedAt: n);
  }

  Future<void> _refreshProductsByCategory(String category) async {
    final n = now();
    final fresh = await api.getProductsByCategory(category);
    await cache.putList('products_category_$category', fresh, cachedAt: n);
  }

  Future<T> _dedup<T>(String key, Future<T> Function() fn) {
    final existing = _inFlight[key];
    if (existing != null) return existing as Future<T>;
    final f = fn();
    _inFlight[key] = f;
    f.whenComplete(() => _inFlight.remove(key));
    return f;
  }
}
