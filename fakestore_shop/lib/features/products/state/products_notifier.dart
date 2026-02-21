import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product.dart';
import 'providers.dart';

class Paginator<T> {
  final List<T> items;
  final int pageSize;
  const Paginator({required this.items, required this.pageSize});

  List<T> page(int pageIndex) {
    final start = pageIndex * pageSize;
    if (start >= items.length) return [];
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }
}

class ProductsState {
  final List<Product> all;
  final List<String> categories;
  final String? selectedCategory;
  final String searchQuery;
  final List<Product> filtered;
  final List<Product> visible;
  final int pageIndex;
  final bool hasMore;

  const ProductsState({
    required this.all,
    required this.categories,
    required this.selectedCategory,
    required this.searchQuery,
    required this.filtered,
    required this.visible,
    required this.pageIndex,
    required this.hasMore,
  });

  factory ProductsState.initial() => const ProductsState(
    all: [],
    categories: [],
    selectedCategory: null,
    searchQuery: '',
    filtered: [],
    visible: [],
    pageIndex: 0,
    hasMore: false,
  );

  ProductsState copyWith({
    List<Product>? all,
    List<String>? categories,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    String? searchQuery,
    List<Product>? filtered,
    List<Product>? visible,
    int? pageIndex,
    bool? hasMore,
  }) {
    return ProductsState(
      all: all ?? this.all,
      categories: categories ?? this.categories,
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      filtered: filtered ?? this.filtered,
      visible: visible ?? this.visible,
      pageIndex: pageIndex ?? this.pageIndex,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ProductsNotifier extends AutoDisposeAsyncNotifier<ProductsState> {
  static const pageSize = 10;

  @override
  Future<ProductsState> build() async {
    final repo = ref.read(productsRepositoryProvider);
    final all = await repo.getProducts();
    return _buildFilteredState(
      all: all,
      selectedCategory: null,
      searchQuery: '',
    );
  }

  void loadMore() {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    final paginator = Paginator<Product>(
      items: current.filtered,
      pageSize: pageSize,
    );
    final nextIndex = current.pageIndex + 1;
    final next = paginator.page(nextIndex);

    state = AsyncData(
      current.copyWith(
        visible: [...current.visible, ...next],
        pageIndex: nextIndex,
        hasMore: paginator.page(nextIndex + 1).isNotEmpty,
      ),
    );
  }

  void setCategory(String? category) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      _buildFilteredState(
        all: current.all,
        selectedCategory: _normalizeCategory(category),
        searchQuery: current.searchQuery,
      ),
    );
  }

  void setSearchQuery(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      _buildFilteredState(
        all: current.all,
        selectedCategory: current.selectedCategory,
        searchQuery: query,
      ),
    );
  }

  void clearFilters() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      _buildFilteredState(
        all: current.all,
        selectedCategory: null,
        searchQuery: '',
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final selectedCategory = current?.selectedCategory;
    final searchQuery = current?.searchQuery ?? '';

    state = const AsyncLoading();
    final repo = ref.read(productsRepositoryProvider);
    final all = await repo.getProducts();
    state = AsyncData(
      _buildFilteredState(
        all: all,
        selectedCategory: selectedCategory,
        searchQuery: searchQuery,
      ),
    );
  }

  ProductsState _buildFilteredState({
    required List<Product> all,
    required String? selectedCategory,
    required String searchQuery,
  }) {
    final categories = _deriveCategories(all);
    final effectiveCategory = categories.contains(selectedCategory)
        ? selectedCategory
        : null;
    final filtered = _filterProducts(
      all: all,
      selectedCategory: effectiveCategory,
      searchQuery: searchQuery,
    );

    final paginator = Paginator<Product>(items: filtered, pageSize: pageSize);
    final first = paginator.page(0);

    return ProductsState(
      all: all,
      categories: categories,
      selectedCategory: effectiveCategory,
      searchQuery: searchQuery,
      filtered: filtered,
      visible: first,
      pageIndex: 0,
      hasMore: paginator.page(1).isNotEmpty,
    );
  }

  List<String> _deriveCategories(List<Product> all) {
    final categories =
        all
            .map((product) => product.category)
            .where((category) => category.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return categories;
  }

  List<Product> _filterProducts({
    required List<Product> all,
    required String? selectedCategory,
    required String searchQuery,
  }) {
    final trimmedQuery = searchQuery.trim().toLowerCase();

    return all
        .where((product) {
          final matchesCategory =
              selectedCategory == null || product.category == selectedCategory;
          if (!matchesCategory) return false;

          if (trimmedQuery.isEmpty) return true;
          return product.title.toLowerCase().contains(trimmedQuery);
        })
        .toList(growable: false);
  }

  String? _normalizeCategory(String? category) {
    final normalized = category?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
