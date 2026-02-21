import 'package:fakestore_shop/features/cart/state/cart_notifier.dart';
import 'package:fakestore_shop/features/products/data/products_repository.dart';
import 'package:fakestore_shop/features/products/domain/product.dart';
import 'package:fakestore_shop/features/products/domain/products_failure.dart';
import 'package:fakestore_shop/features/products/presentation/products_page.dart';
import 'package:fakestore_shop/features/products/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductsRepository extends Mock implements ProductsRepository {}

Product _product({
  required int id,
  required String title,
  required String category,
  double price = 20,
}) {
  return Product(
    id: id,
    title: title,
    price: price,
    description: 'Description $id',
    category: category,
    image: 'https://example.com/$id.png',
  );
}

Future<void> _pumpProductsPage(
  WidgetTester tester, {
  required ProductsRepository repository,
  Map<int, CartItem>? cartState,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productsRepositoryProvider.overrideWithValue(repository),
        cartProvider.overrideWith(
          (ref) => CartNotifier(initialState: cartState ?? const {}),
        ),
      ],
      child: const MaterialApp(home: ProductsPage()),
    ),
  );

  await tester.pump();
  await tester.pump();
}

void main() {
  group('ProductsPage', () {
    testWidgets(
      'renders products and applies search + category filters together',
      (tester) async {
        final repo = _MockProductsRepository();
        final products = [
          _product(id: 1, title: 'Laptop Pro', category: 'electronics'),
          _product(id: 2, title: 'Lamp Stand', category: 'home'),
          _product(id: 3, title: 'Running Shoes', category: 'fashion'),
        ];

        when(() => repo.getProducts()).thenAnswer((_) async => products);

        await _pumpProductsPage(
          tester,
          repository: repo,
          cartState: {
            99: CartItem(
              product: _product(
                id: 99,
                title: 'In cart',
                category: 'misc',
                price: 5,
              ),
              quantity: 3,
            ),
          },
        );

        expect(find.text('FakeStore Shop'), findsOneWidget);
        expect(find.text('3'), findsOneWidget); // cart badge
        expect(find.text('Search by name'), findsOneWidget);
        expect(find.text('All categories'), findsOneWidget);
        expect(find.text('Laptop Pro'), findsOneWidget);
        expect(find.text('Lamp Stand'), findsOneWidget);
        expect(find.text('Running Shoes'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'la');
        await tester.pump();

        expect(find.text('Laptop Pro'), findsOneWidget);
        expect(find.text('Lamp Stand'), findsOneWidget);
        expect(find.text('Running Shoes'), findsNothing);

        await tester.tap(find.byType(DropdownButtonFormField<String?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('home').last);
        await tester.pumpAndSettle();

        expect(find.text('la'), findsOneWidget); // search is preserved
        expect(find.text('Lamp Stand'), findsOneWidget);
        expect(find.text('Laptop Pro'), findsNothing);
        expect(find.text('Running Shoes'), findsNothing);
      },
    );

    testWidgets('shows empty state when repository returns no products', (
      tester,
    ) async {
      final repo = _MockProductsRepository();
      when(() => repo.getProducts()).thenAnswer((_) async => []);

      await _pumpProductsPage(tester, repository: repo);

      expect(find.text('No products found'), findsOneWidget);
      expect(find.text('Search by name'), findsOneWidget);
      expect(find.text('All categories'), findsOneWidget);
    });

    testWidgets('shows mapped server error state when load fails with 500', (
      tester,
    ) async {
      final repo = _MockProductsRepository();
      when(
        () => repo.getProducts(),
      ).thenThrow(ProductsFailure.server(statusCode: 500));

      await _pumpProductsPage(tester, repository: repo);

      expect(find.text('Server error'), findsOneWidget);
      expect(
        find.text(
          'The server failed to process the request (HTTP 500). Please retry.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.dns_outlined), findsOneWidget);
    });
  });
}
