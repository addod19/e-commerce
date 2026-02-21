import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cart/presentation/cart_page.dart';
import '../../cart/state/cart_notifier.dart';
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
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FakeStore Shop'),
        actions: [
          IconButton(
            tooltip: 'Cart',
            icon: _CartActionIcon(count: cartCount),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartPage())),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CategoriesPage())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(productsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => ErrorView(
          title: 'Couldn’t load products',
          message: e.toString(),
          onRetry: () => ref.read(productsNotifierProvider.notifier).refresh(),
        ),
        data: (state) {
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(productsNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.visible.length + 1,
              itemBuilder: (context, index) {
                if (index < state.visible.length) {
                  final p = state.visible[index];
                  return ProductCard(
                    product: p,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(productId: p.id),
                      ),
                    ),
                    onAddToCart: () {
                      ref.read(cartProvider.notifier).add(p);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Added to cart'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                    },
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
                      onPressed: () => ref
                          .read(productsNotifierProvider.notifier)
                          .loadMore(),
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

class _CartActionIcon extends StatelessWidget {
  const _CartActionIcon({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart_outlined),
        if (count > 0)
          Positioned(
            right: -7,
            top: -7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
