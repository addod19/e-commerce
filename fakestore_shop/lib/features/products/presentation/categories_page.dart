import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cart/state/cart_notifier.dart';
import '../state/providers.dart';
import '../domain/product.dart';
import 'product_detail_page.dart';
import 'widgets/error_view.dart';
import 'widgets/product_card.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  static const _pageSize = 10;

  String? selected;
  int _pageIndex = 0;
  AsyncValue<List<Product>> productsAsync = const AsyncValue.data([]);

  Future<void> _loadCategory(String category) async {
    setState(() {
      _pageIndex = 0;
      productsAsync = const AsyncValue.loading();
    });
    try {
      final repo = ref.read(productsRepositoryProvider);
      final products = await repo.getProductsByCategory(category);
      if (!mounted) return;
      setState(() => productsAsync = AsyncValue.data(products));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => productsAsync = AsyncValue.error(e, st));
    }
  }

  List<Product> _visibleProducts(List<Product> allProducts) {
    final end = ((_pageIndex + 1) * _pageSize).clamp(0, allProducts.length);
    return allProducts.sublist(0, end);
  }

  bool _hasMoreProducts(List<Product> allProducts) {
    return (_pageIndex + 1) * _pageSize < allProducts.length;
  }

  void _loadMoreProducts(List<Product> allProducts) {
    if (!_hasMoreProducts(allProducts)) return;
    setState(() => _pageIndex += 1);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categories.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => ErrorView(
          title: 'Couldn’t load categories',
          message: e.toString(),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'Select category',
                  ),
                  items: state.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => selected = v);
                    _loadCategory(v);
                  },
                ),
              ),
              Expanded(
                child: productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (e, _) => ErrorView(
                    title: 'Couldn’t load category products',
                    message: e.toString(),
                    onRetry: () {
                      final c = selected;
                      if (c != null) _loadCategory(c);
                    },
                  ),
                  data: (products) {
                    if (selected == null) {
                      return const Center(
                        child: Text('Pick a category to view products'),
                      );
                    }
                    if (products.isEmpty) {
                      return const Center(child: Text('No products found'));
                    }
                    final visibleProducts = _visibleProducts(products);
                    final hasMore = _hasMoreProducts(products);
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: visibleProducts.length + 1,
                      itemBuilder: (itemContext, i) {
                        if (i < visibleProducts.length) {
                          final product = visibleProducts[i];
                          return ProductCard(
                            product: product,
                            onTap: () => Navigator.of(itemContext).push(
                              MaterialPageRoute(
                                builder: (routeContext) =>
                                    ProductDetailPage(productId: product.id),
                              ),
                            ),
                            onAddToCart: () {
                              ref.read(cartProvider.notifier).add(product);
                              ScaffoldMessenger.of(itemContext)
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

                        if (!hasMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text('No more products')),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: FilledButton(
                              onPressed: () => _loadMoreProducts(products),
                              child: const Text('Load more'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
