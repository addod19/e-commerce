import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'widgets/error_view.dart';

class ProductDetailPage extends ConsumerWidget {
  final int productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => ErrorView(
          title: 'Couldn’t load product',
          message: e.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
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
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                ),
              ),
              const SizedBox(height: 16),
              Text(p.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(p.category, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              Text('\$${p.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(p.description),
            ],
          );
        },
      ),
    );
  }
}
