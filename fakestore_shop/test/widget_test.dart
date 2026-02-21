import 'package:fakestore_shop/features/products/domain/product.dart';
import 'package:fakestore_shop/features/products/presentation/widgets/error_view.dart';
import 'package:fakestore_shop/features/products/presentation/widgets/product_card.dart';
import 'package:fakestore_shop/features/products/presentation/widgets/slow_aware_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Product _sampleProduct() {
  return const Product(
    id: 1,
    title: 'Widget Test Product',
    price: 29.99,
    description: 'A product used for widget tests',
    category: 'electronics',
    image: 'https://example.com/product.png',
  );
}

void main() {
  testWidgets('ProductCard renders data and triggers callbacks', (
    tester,
  ) async {
    var tapped = false;
    var addedToCart = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCard(
            product: _sampleProduct(),
            onTap: () => tapped = true,
            onAddToCart: () => addedToCart = true,
          ),
        ),
      ),
    );

    expect(find.text('Widget Test Product'), findsOneWidget);
    expect(find.text('electronics'), findsOneWidget);
    expect(find.text('\$29.99'), findsOneWidget);

    await tester.tap(find.text('Widget Test Product'));
    await tester.pump();
    expect(tapped, isTrue);

    await tester.tap(find.byIcon(Icons.add_shopping_cart_outlined));
    await tester.pump();
    expect(addedToCart, isTrue);
  });

  testWidgets('ErrorView shows content and retry action', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            title: 'Offline',
            message: 'No internet',
            icon: Icons.wifi_off_rounded,
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('No internet'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('SlowAwareLoadingView shows delayed network hint', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SlowAwareLoadingView(
            label: 'Loading products...',
            slowHintDelay: Duration(milliseconds: 250),
          ),
        ),
      ),
    );

    expect(find.text('Loading products...'), findsOneWidget);
    expect(
      find.text('This is taking longer than usual. Network may be slow.'),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('This is taking longer than usual. Network may be slow.'),
      findsOneWidget,
    );
  });
}
