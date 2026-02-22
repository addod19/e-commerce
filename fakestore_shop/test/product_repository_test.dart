import 'package:flutter_test/flutter_test.dart';
import 'package:fakestore_shop/core/cache/cache_entry.dart';
import 'package:fakestore_shop/core/cache/local_cache.dart';
import 'package:fakestore_shop/features/products/data/api_client.dart';
import 'package:fakestore_shop/features/products/data/products_repository.dart';
import 'package:fakestore_shop/features/products/domain/products_failure.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

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

  group('ProductsRepository error matrix', () {
    late _MockDio dio;
    late Box box;
    late DateTime now;

    ProductsRepository buildRepository({
      required Future<bool> Function() isOnline,
    }) {
      return ProductsRepository(
        api: ApiClient(dio),
        cache: LocalCache(box),
        isOnline: isOnline,
        now: () => now,
      );
    }

    setUp(() async {
      await setUpTestHive();
      box = await Hive.openBox('products_repository_test_box');
      dio = _MockDio();
      now = DateTime(2026, 2, 21, 12, 0);
    });

    tearDown(() async {
      await box.close();
      await tearDownTestHive();
    });

    test('maps HTTP 500 to server failure', () async {
      when(() => dio.get('/products')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/products'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/products'),
            statusCode: 500,
          ),
        ),
      );

      final repo = buildRepository(isOnline: () async => true);

      try {
        await repo.getProducts();
        fail('Expected server failure');
      } catch (error) {
        expect(error, isA<ProductsFailure>());
        expect((error as ProductsFailure).type, ProductsFailureType.server);
      }
    });

    test('maps timeout to slow network failure', () async {
      when(() => dio.get('/products')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/products'),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      final repo = buildRepository(isOnline: () async => true);

      try {
        await repo.getProducts();
        fail('Expected slow network failure');
      } catch (error) {
        expect(error, isA<ProductsFailure>());
        expect(
          (error as ProductsFailure).type,
          ProductsFailureType.slowNetwork,
        );
      }
    });

    test(
      'returns empty list without throwing when API returns no products',
      () async {
        when(() => dio.get('/products')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/products'),
            data: <dynamic>[],
          ),
        );

        final repo = buildRepository(isOnline: () async => true);
        final products = await repo.getProducts();

        expect(products, isEmpty);
      },
    );

    test(
      'throws cache corrupted failure when cached data is invalid and offline',
      () async {
        await box.put('products_all', {
          'data': [
            {'title': 'Missing required fields'},
          ],
          'cachedAt': now.millisecondsSinceEpoch,
        });

        final repo = buildRepository(isOnline: () async => false);

        try {
          await repo.getProducts();
          fail('Expected cache corruption failure');
        } catch (error) {
          expect(error, isA<ProductsFailure>());
          expect(
            (error as ProductsFailure).type,
            ProductsFailureType.cacheCorrupted,
          );
        }
      },
    );
  });
}
