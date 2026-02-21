import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/cache/local_cache.dart';
import '../domain/product.dart';
import '../domain/products_failure.dart';
import 'api_client.dart';

typedef NowFn = DateTime Function();

class _CorruptedDataException implements Exception {}

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
  static const _productsAllKey = 'products_all';
  static const _categoriesKey = 'categories';

  Future<List<Product>> getProducts() async {
    return _dedup(_productsAllKey, () async {
      final cached = await cache.getList(_productsAllKey);
      final online = await isOnline();
      final n = now();

      if (cached != null) {
        final cachedProducts = _tryDecodeProductsList(cached.data);
        if (cachedProducts == null) {
          await cache.delete(_productsAllKey);
          if (!online) throw ProductsFailure.cacheCorrupted();
        } else {
          if (!cached.isFresh(productsTtl, n) && online) {
            unawaited(_refreshProducts());
          }
          return cachedProducts;
        }
      }

      if (!online) throw ProductsFailure.offline();

      final fresh = await _runApi(api.getProducts);
      final decoded = _decodeProductsListOrFailure(fresh);
      await cache.putList(_productsAllKey, fresh, cachedAt: n);
      return decoded;
    });
  }

  Future<Product> getProduct(int id) async {
    return _dedup('product_$id', () async {
      final key = 'product_$id';
      final cached = await cache.getMap(key);
      final online = await isOnline();
      final n = now();

      if (cached != null) {
        final cachedProduct = _tryDecodeProduct(cached.data);
        if (cachedProduct == null) {
          await cache.delete(key);
          if (!online) throw ProductsFailure.cacheCorrupted();
        } else {
          if (!cached.isFresh(productTtl, n) && online) {
            unawaited(_refreshProduct(id));
          }
          return cachedProduct;
        }
      }

      if (!online) throw ProductsFailure.offline();
      final fresh = await _runApi(() => api.getProduct(id));
      final decoded = _decodeProductOrFailure(fresh);
      await cache.putMap(key, fresh, cachedAt: n);
      return decoded;
    });
  }

  Future<List<String>> getCategories() async {
    return _dedup(_categoriesKey, () async {
      final cached = await cache.getList(_categoriesKey);
      final online = await isOnline();
      final n = now();

      if (cached != null) {
        final decoded = _tryDecodeCategories(cached.data);
        if (decoded == null) {
          await cache.delete(_categoriesKey);
          if (!online) throw ProductsFailure.cacheCorrupted();
        } else {
          if (!cached.isFresh(categoriesTtl, n) && online) {
            unawaited(_refreshCategories());
          }
          return decoded;
        }
      }

      if (!online) throw ProductsFailure.offline();
      final fresh = await _runApi(api.getCategories);
      final decoded = _decodeCategoriesOrFailure(fresh);
      await cache.putList(_categoriesKey, fresh, cachedAt: n);
      return decoded;
    });
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final key = 'products_category_$category';
    return _dedup(key, () async {
      final cached = await cache.getList(key);
      final online = await isOnline();
      final n = now();

      if (cached != null) {
        final cachedProducts = _tryDecodeProductsList(cached.data);
        if (cachedProducts == null) {
          await cache.delete(key);
          if (!online) throw ProductsFailure.cacheCorrupted();
        } else {
          if (!cached.isFresh(productsTtl, n) && online) {
            unawaited(_refreshProductsByCategory(category));
          }
          return cachedProducts;
        }
      }

      if (!online) throw ProductsFailure.offline();
      final fresh = await _runApi(() => api.getProductsByCategory(category));
      final decoded = _decodeProductsListOrFailure(fresh);
      await cache.putList(key, fresh, cachedAt: n);
      return decoded;
    });
  }

  Future<void> _refreshProducts() async {
    try {
      final n = now();
      final fresh = await _runApi(api.getProducts);
      _decodeProductsListOrFailure(fresh);
      await cache.putList(_productsAllKey, fresh, cachedAt: n);
    } catch (_) {
      // Background refresh failures should not crash foreground flows.
    }
  }

  Future<void> _refreshProduct(int id) async {
    try {
      final n = now();
      final fresh = await _runApi(() => api.getProduct(id));
      _decodeProductOrFailure(fresh);
      await cache.putMap('product_$id', fresh, cachedAt: n);
    } catch (_) {
      // Background refresh failures should not crash foreground flows.
    }
  }

  Future<void> _refreshCategories() async {
    try {
      final n = now();
      final fresh = await _runApi(api.getCategories);
      _decodeCategoriesOrFailure(fresh);
      await cache.putList(_categoriesKey, fresh, cachedAt: n);
    } catch (_) {
      // Background refresh failures should not crash foreground flows.
    }
  }

  Future<void> _refreshProductsByCategory(String category) async {
    try {
      final n = now();
      final fresh = await _runApi(() => api.getProductsByCategory(category));
      _decodeProductsListOrFailure(fresh);
      await cache.putList('products_category_$category', fresh, cachedAt: n);
    } catch (_) {
      // Background refresh failures should not crash foreground flows.
    }
  }

  List<Product>? _tryDecodeProductsList(dynamic raw) {
    try {
      return _decodeProductsList(raw);
    } on _CorruptedDataException {
      return null;
    }
  }

  Product? _tryDecodeProduct(dynamic raw) {
    try {
      return _decodeProduct(raw);
    } on _CorruptedDataException {
      return null;
    }
  }

  List<String>? _tryDecodeCategories(dynamic raw) {
    try {
      return _decodeCategories(raw);
    } on _CorruptedDataException {
      return null;
    }
  }

  List<Product> _decodeProductsList(dynamic raw) {
    if (raw is! List) {
      throw _CorruptedDataException();
    }

    try {
      return raw
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (_) {
      throw _CorruptedDataException();
    }
  }

  List<Product> _decodeProductsListOrFailure(dynamic raw) {
    try {
      return _decodeProductsList(raw);
    } on _CorruptedDataException {
      throw ProductsFailure.malformedResponse();
    }
  }

  Product _decodeProduct(dynamic raw) {
    if (raw is! Map) {
      throw _CorruptedDataException();
    }

    try {
      return Product.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      throw _CorruptedDataException();
    }
  }

  Product _decodeProductOrFailure(dynamic raw) {
    try {
      return _decodeProduct(raw);
    } on _CorruptedDataException {
      throw ProductsFailure.malformedResponse();
    }
  }

  List<String> _decodeCategories(dynamic raw) {
    if (raw is! List) {
      throw _CorruptedDataException();
    }

    try {
      return raw.map((e) => e as String).toList(growable: false);
    } catch (_) {
      throw _CorruptedDataException();
    }
  }

  List<String> _decodeCategoriesOrFailure(dynamic raw) {
    try {
      return _decodeCategories(raw);
    } on _CorruptedDataException {
      throw ProductsFailure.malformedResponse();
    }
  }

  Future<T> _runApi<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on TypeError {
      throw ProductsFailure.malformedResponse();
    } on FormatException {
      throw ProductsFailure.malformedResponse();
    } on _CorruptedDataException {
      throw ProductsFailure.malformedResponse();
    } catch (_) {
      throw ProductsFailure.unknown();
    }
  }

  ProductsFailure _mapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ProductsFailure.slowNetwork();
    }

    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return ProductsFailure.offline();
    }

    if (error.type == DioExceptionType.badResponse) {
      final code = error.response?.statusCode;
      if (code != null && code >= 500) {
        return ProductsFailure.server(statusCode: code);
      }
      return ProductsFailure.unknown();
    }

    return ProductsFailure.unknown();
  }

  Future<T> _dedup<T>(String key, Future<T> Function() fn) {
    final existing = _inFlight[key];
    if (existing != null) return existing as Future<T>;
    final f = fn();
    _inFlight[key] = f;
    f.then<void>(
      (_) {
        _inFlight.remove(key);
      },
      onError: (error, stackTrace) {
        _inFlight.remove(key);
      },
    );
    return f;
  }
}
