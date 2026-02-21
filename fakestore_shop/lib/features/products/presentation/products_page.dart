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

  Future<void> _openCart() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CartPage()));
  }

  Widget _buildHeader(int cartCount) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi Shopper!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Good Morning!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openCart,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.shopping_bag_outlined),
                ),
              ),
            ),
            if (cartCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  child: Text(
                    cartCount > 99 ? '99+' : '$cartCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchRow(ProductsState state) {
    if (_searchController.text != state.searchQuery) {
      _searchController.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
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
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 48,
          width: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _onSearchChanged(_searchController.text),
            child: const Icon(Icons.search),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(ProductsState state) {
    final chipLabels = ['All categories', ...state.categories];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chipLabels.length; i++) ...[
            _CategoryChip(
              label: i == 0 ? 'All' : chipLabels[i],
              selected: i == 0
                  ? state.selectedCategory == null
                  : state.selectedCategory == chipLabels[i],
              onTap: () => _onCategoryChanged(i == 0 ? null : chipLabels[i]),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ProductsState state) {
    final message = state.all.isEmpty
        ? 'No products found'
        : 'No products match your filters';
    return SizedBox(
      height: 260,
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.black.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFFF8A1F),
      unselectedItemColor: Colors.black.withValues(alpha: 0.35),
      onTap: (index) {
        if (index == 2) {
          _openCart();
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          label: 'Shop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productsNotifierProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: _buildBottomNav(),
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

          return RefreshIndicator(
            onRefresh: _refreshProducts,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  sliver: SliverToBoxAdapter(child: _buildHeader(cartCount)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  sliver: SliverToBoxAdapter(child: _buildSearchRow(state)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  sliver: SliverToBoxAdapter(child: _buildCategoryChips(state)),
                ),
                if (hasNoResults)
                  SliverToBoxAdapter(child: _buildEmptyState(state))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.62,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final p = state.visible[index];
                        return ProductCard(
                          product: p,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailPage(productId: p.id),
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
                      }, childCount: state.visible.length),
                    ),
                  ),
                if (!hasNoResults && !state.hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Center(
                        child: Text(
                          'No more products',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? null
                : Border.all(color: Colors.black.withValues(alpha: 0.15)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.black.withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
