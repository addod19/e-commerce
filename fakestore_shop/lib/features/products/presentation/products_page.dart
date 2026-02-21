import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cart/presentation/cart_page.dart';
import '../../cart/state/cart_notifier.dart';
import '../state/providers.dart';
import '../state/products_notifier.dart';
import 'products_error_presentation.dart';
import 'product_detail_page.dart';
import 'widgets/error_view.dart';
import 'widgets/product_card.dart';
import 'widgets/slow_aware_loading_view.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  static const _loadMoreThreshold = 240.0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
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
    _searchController.dispose();
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

  void _onCategoryChanged(String? category) {
    _loadTriggeredNearBottom = false;
    ref.read(productsNotifierProvider.notifier).setCategory(category);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _onSearchChanged(String query) {
    _loadTriggeredNearBottom = false;
    ref.read(productsNotifierProvider.notifier).setSearchQuery(query);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _clearFilters() {
    _loadTriggeredNearBottom = false;
    _searchController.clear();
    ref.read(productsNotifierProvider.notifier).clearFilters();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Widget _buildFilters(ProductsState state) {
    if (_searchController.text != state.searchQuery) {
      _searchController.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    final hasActiveFilters =
        state.selectedCategory != null || state.searchQuery.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey(state.selectedCategory ?? '__all__'),
                    initialValue: state.selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...state.categories.map(
                        (category) => DropdownMenuItem<String?>(
                          value: category,
                          child: Text(category),
                        ),
                      ),
                    ],
                    onChanged: _onCategoryChanged,
                  ),
                ),
                if (hasActiveFilters)
                  IconButton(
                    tooltip: 'Clear filters',
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Search by name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () => _onSearchChanged(''),
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: _onSearchChanged,
            ),
          ],
        ),
      ),
    );
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
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
          ),
        ],
      ),
      body: async.when(
        loading: () => const SlowAwareLoadingView(label: 'Loading products...'),
        error: (e, _) {
          final details = presentProductsError(e);
          return ErrorView(
            title: details.title,
            message: details.message,
            icon: details.icon,
            onRetry: _refreshProducts,
          );
        },
        data: (state) {
          final hasNoResults = state.filtered.isEmpty;
          final itemCount =
              1 +
              (hasNoResults
                  ? 1
                  : state.visible.length + (state.hasMore ? 0 : 1));

          return RefreshIndicator(
            onRefresh: _refreshProducts,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: itemCount,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFilters(state);
                }

                if (hasNoResults) {
                  if (state.all.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No products found')),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('No products match your filters'),
                    ),
                  );
                }

                final productIndex = index - 1;
                if (productIndex < state.visible.length) {
                  final p = state.visible[productIndex];
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
