import 'package:flutter_test/flutter_test.dart';
import 'package:fakestore_shop/features/products/state/products_notifier.dart';

void main() {
  test('Paginator returns expected pages', () {
    const paginator = Paginator<int>(items: [1, 2, 3, 4, 5], pageSize: 2);

    expect(paginator.page(0), [1, 2]);
    expect(paginator.page(1), [3, 4]);
    expect(paginator.page(2), [5]);
    expect(paginator.page(3), isEmpty);
  });
}
