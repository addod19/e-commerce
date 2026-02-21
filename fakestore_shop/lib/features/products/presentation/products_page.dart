import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'product_detail_page.dart';
import 'categories_page.dart';
import 'widgets/error_view.dart';
import 'widgets/product_card.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FakeStore Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(productsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => ErrorView(
          title: 'Couldn’t load products',
          message: e.toString(),
          onRetry: () => ref.read(productsNotifierProvider.notifier).refresh(),
        ),
        data: (state) {
          return RefreshIndicator(
            onRefresh: () => ref.read(productsNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.visible.length + 1,
              itemBuilder: (context, index) {
                if (index < state.visible.length) {
                  final p = state.visible[index];
                  return ProductCard(
                    product: p,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailPage(productId: p.id)),
                    ),
                  );
                }

                if (!state.hasMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No more products')),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: FilledButton(
                      onPressed: () => ref.read(productsNotifierProvider.notifier).loadMore(),
                      child: const Text('Load more'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
