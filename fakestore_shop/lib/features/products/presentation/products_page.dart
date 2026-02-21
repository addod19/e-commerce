import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cart/presentation/cart_page.dart';
import '../../cart/state/cart_notifier.dart';
import '../state/providers.dart';
import 'product_detail_page.dart';
import 'categories_page.dart';
import 'widgets/error_view.dart';
import 'widgets/product_card.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  static const _loadMoreThreshold = 240.0;
  final ScrollController _scrollController = ScrollController();
  bool _loadTriggeredNearBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final state = ref.read(productsNotifierProvider).valueOrNull;
    if (state == null || !state.hasMore) return;

    final shouldLoadMore =
        _scrollController.position.extentAfter < _loadMoreThreshold;

    if (shouldLoadMore && !_loadTriggeredNearBottom) {
      _loadTriggeredNearBottom = true;
      ref.read(productsNotifierProvider.notifier).loadMore();
      return;
    }

    if (!shouldLoadMore && _loadTriggeredNearBottom) {
      _loadTriggeredNearBottom = false;
    }
  }

  Future<void> _refreshProducts() async {
    _loadTriggeredNearBottom = false;
    await ref.read(productsNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _refreshProducts,
          ),
        ],
      ),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => ErrorView(
          title: 'Couldn’t load products',
          message: e.toString(),
          onRetry: _refreshProducts,
        ),
        data: (state) {
          return RefreshIndicator(
            onRefresh: _refreshProducts,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: state.visible.length + (state.hasMore ? 0 : 1),
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

                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No more products')),
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
