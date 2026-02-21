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
  final List<Product> visible;
  final int pageIndex;
  final bool hasMore;

  const ProductsState({
    required this.all,
    required this.visible,
    required this.pageIndex,
    required this.hasMore,
  });

  factory ProductsState.initial() => const ProductsState(all: [], visible: [], pageIndex: 0, hasMore: true);
}

class ProductsNotifier extends AutoDisposeAsyncNotifier<ProductsState> {
  static const pageSize = 10;

  @override
  Future<ProductsState> build() async {
    final repo = ref.read(productsRepositoryProvider);
    final all = await repo.getProducts();

    final paginator = Paginator<Product>(items: all, pageSize: pageSize);
    final first = paginator.page(0);

    return ProductsState(
      all: all,
      visible: first,
      pageIndex: 0,
      hasMore: paginator.page(1).isNotEmpty,
    );
  }

  void loadMore() {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    final paginator = Paginator<Product>(items: current.all, pageSize: pageSize);
    final nextIndex = current.pageIndex + 1;
    final next = paginator.page(nextIndex);

    state = AsyncData(
      ProductsState(
        all: current.all,
        visible: [...current.visible, ...next],
        pageIndex: nextIndex,
        hasMore: paginator.page(nextIndex + 1).isNotEmpty,
      ),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}
