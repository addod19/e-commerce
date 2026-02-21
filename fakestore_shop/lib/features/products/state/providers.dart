import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/cache/local_cache.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/network/dio_provider.dart';
import '../data/api_client.dart';
import '../data/products_repository.dart';
import 'products_notifier.dart';
import 'product_detail_notifier.dart';
import 'categories_notifier.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(ref.read(connectivityProvider));
});

final cacheBoxProvider = Provider<Box>((ref) {
  // This is set up in main() after Hive init (see main.dart)
  throw UnimplementedError('Override cacheBoxProvider in main()');
});

final localCacheProvider = Provider<LocalCache>((ref) {
  return LocalCache(ref.read(cacheBoxProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(dioProvider));
});

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final connectivity = ref.read(connectivityServiceProvider);
  return ProductsRepository(
    api: ref.read(apiClientProvider),
    cache: ref.read(localCacheProvider),
    isOnline: connectivity.isOnline,
    now: DateTime.now,
  );
});

// Notifiers
final productsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ProductsNotifier, ProductsState>(ProductsNotifier.new);

final productDetailProvider =
    AutoDisposeAsyncNotifierProviderFamily<ProductDetailNotifier, ProductDetailState, int>(
        ProductDetailNotifier.new);

final categoriesProvider =
    AutoDisposeAsyncNotifierProvider<CategoriesNotifier, CategoriesState>(CategoriesNotifier.new);
