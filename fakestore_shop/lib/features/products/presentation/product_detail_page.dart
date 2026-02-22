import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cart/state/cart_notifier.dart';
import '../domain/product.dart';
import '../state/providers.dart';
import 'products_error_presentation.dart';
import 'widgets/error_view.dart';
import 'widgets/slow_aware_loading_view.dart';

class ProductDetailPage extends ConsumerWidget {
  final int productId;
  const ProductDetailPage({super.key, required this.productId});

  void _addToCart(BuildContext context, WidgetRef ref, Product product) {
    ref.read(cartProvider.notifier).add(product);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Added to cart'),
          duration: Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(productId));
    final loadedProduct = async.valueOrNull?.product;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Favorite',
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
          if (loadedProduct != null)
            IconButton(
              tooltip: 'Add to cart',
              icon: const Icon(Icons.add_shopping_cart_outlined),
              onPressed: () => _addToCart(context, ref, loadedProduct),
            ),
        ],
      ),
      body: async.when(
        loading: () =>
            const SlowAwareLoadingView(label: 'Loading product details...'),
        error: (e, _) {
          final details = presentProductsError(e);
          return ErrorView(
            title: details.title,
            message: details.message,
            icon: details.icon,
            onRetry: () => ref.invalidate(productDetailProvider(productId)),
          );
        },
        data: (state) {
          final p = state.product;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFECE9E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Image.network(
                      p.image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.broken_image_outlined, size: 42),
                            SizedBox(height: 6),
                            Text('Image unavailable'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      p.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '\$${p.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFFF8A1F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFF9B21), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '4.5 (15 Review)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFFF9B21),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                p.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withValues(alpha: 0.55),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Color:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  _ColorSwatch(color: Colors.black),
                  SizedBox(width: 10),
                  _ColorSwatch(color: Color(0xFFEAA033)),
                  SizedBox(width: 10),
                  _ColorSwatch(color: Color(0xFF2F76C9)),
                  SizedBox(width: 10),
                  _ColorSwatch(color: Color(0xFFFF6B00)),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Size:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 170,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'CHOOSE SIZE',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: Colors.black54),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.black45),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _addToCart(context, ref, p),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
