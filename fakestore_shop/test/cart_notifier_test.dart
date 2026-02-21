import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fakestore_shop/features/cart/state/cart_notifier.dart';
import 'package:fakestore_shop/features/products/domain/product.dart';

Product _product(int id, {double price = 10, String? title}) {
  return Product(
    id: id,
    title: title ?? 'Product $id',
    price: price,
    description: 'Description $id',
    category: 'category',
    image: 'https://example.com/$id.png',
  );
}

void main() {
  group('CartNotifier duplicate logic', () {
    test(
      'adding same product id merges into one item and increments quantity',
      () {
        final notifier = CartNotifier();
        final p = _product(1, price: 29.99);

        notifier.add(p);
        notifier.add(p);

        expect(notifier.state.length, 1);
        expect(notifier.state[1]?.quantity, 2);
        expect(notifier.state[1]?.product.id, 1);
      },
    );

    test(
      'adding same id keeps a single entry and updates latest product payload',
      () {
        final notifier = CartNotifier();
        final original = _product(7, title: 'Old title', price: 20);
        final updated = _product(7, title: 'New title', price: 25);

        notifier.add(original);
        notifier.add(updated);

        expect(notifier.state.length, 1);
        expect(notifier.state[7]?.quantity, 2);
        expect(notifier.state[7]?.product.title, 'New title');
        expect(notifier.state[7]?.product.price, 25);
      },
    );

    test('decrement removes item when quantity reaches zero', () {
      final notifier = CartNotifier();
      final p = _product(3);

      notifier.add(p);
      notifier.decrement(3);

      expect(notifier.state, isEmpty);
    });
  });

  group('Cart providers', () {
    test(
      'cartCountProvider and cartTotalProvider are correct with merged items',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(cartProvider.notifier);
        notifier.add(_product(1, price: 5));
        notifier.add(_product(1, price: 5));
        notifier.add(_product(2, price: 12.5));

        expect(container.read(cartCountProvider), 3);
        expect(container.read(cartItemsProvider).length, 2);
        expect(container.read(cartTotalProvider), closeTo(22.5, 0.0001));
      },
    );
  });
}
