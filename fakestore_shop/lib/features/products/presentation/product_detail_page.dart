import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cart/state/cart_notifier.dart';
import '../state/providers.dart';
import 'products_error_presentation.dart';
import 'widgets/error_view.dart';
import 'widgets/slow_aware_loading_view.dart';

class ProductDetailPage extends ConsumerWidget {
  final int productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(productId));
    final loadedProduct = async.valueOrNull?.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          if (loadedProduct != null)
            IconButton(
              tooltip: 'Add to cart',
              icon: const Icon(Icons.add_shopping_cart_outlined),
              onPressed: () {
                ref.read(cartProvider.notifier).add(loadedProduct);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Added to cart'),
                      duration: Duration(seconds: 1),
                    ),
                  );
              },
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
              AspectRatio(
                aspectRatio: 1.2,
                child: Image.network(
                  p.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
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
              const SizedBox(height: 16),
              Text(p.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(p.category, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              Text(
                '\$${p.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(p.description),
            ],
          );
        },
      ),
    );
  }
}
