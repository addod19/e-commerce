import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/cache/cache_providers.dart';
import '../../products/domain/product.dart';

const _cartStorageKey = 'cart_items_v1';

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get subtotal => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartNotifier extends StateNotifier<Map<int, CartItem>> {
  CartNotifier({
    Future<void> Function(Map<int, CartItem> cart)? persist,
    Map<int, CartItem>? initialState,
  }) : _persist = persist ?? _noopPersist,
       super(initialState ?? const {});

  final Future<void> Function(Map<int, CartItem> cart) _persist;
  Future<void> _persistQueue = Future<void>.value();

  static Future<void> _noopPersist(Map<int, CartItem> cart) async {}

  Future<void> _persistSafe(Map<int, CartItem> next) async {
    try {
      await _persist(next);
    } catch (_) {
      // Persistence should not block in-memory cart updates.
    }
  }

  void _setStateAndPersist(Map<int, CartItem> next) {
    state = next;
    _persistQueue = _persistQueue.then((_) => _persistSafe(next));
  }

  Future<void> waitForPendingPersists() => _persistQueue;

  void add(Product product) {
    final existing = state[product.id];
    if (existing == null) {
      _setStateAndPersist({
        ...state,
        product.id: CartItem(product: product, quantity: 1),
      });
      return;
    }

    _setStateAndPersist({
      ...state,
      product.id: existing.copyWith(
        product: product,
        quantity: existing.quantity + 1,
      ),
    });
  }

  void decrement(int productId) {
    final existing = state[productId];
    if (existing == null) return;

    if (existing.quantity <= 1) {
      remove(productId);
      return;
    }

    _setStateAndPersist({
      ...state,
      productId: existing.copyWith(quantity: existing.quantity - 1),
    });
  }

  void remove(int productId) {
    if (!state.containsKey(productId)) return;
    final next = Map<int, CartItem>.from(state);
    next.remove(productId);
    _setStateAndPersist(next);
  }

  void clear() {
    _setStateAndPersist(const {});
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<int, CartItem>>((
  ref,
) {
  final box = ref.read(cacheBoxProvider);
  return CartNotifier(
    initialState: _decodeCartState(box.get(_cartStorageKey)),
    persist: (cart) => _persistCartState(box, cart),
  );
});

final cartItemsProvider = Provider<List<CartItem>>((ref) {
  final items = ref.watch(cartProvider).values.toList();
  items.sort((a, b) => a.product.id.compareTo(b.product.id));
  return items;
});

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.values.fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.values.fold(0, (sum, item) => sum + item.subtotal);
});

Future<void> _persistCartState(Box box, Map<int, CartItem> state) async {
  await box.put(_cartStorageKey, _encodeCartState(state));
  await box.flush();
}

List<Map<String, dynamic>> _encodeCartState(Map<int, CartItem> state) {
  return state.values
      .map(
        (item) => <String, dynamic>{
          'product': item.product.toJson(),
          'quantity': item.quantity,
        },
      )
      .toList(growable: false);
}

Map<int, CartItem> _decodeCartState(dynamic raw) {
  if (raw is! List) return const {};

  final decoded = <int, CartItem>{};

  for (final item in raw) {
    if (item is! Map) continue;
    final productRaw = item['product'];
    if (productRaw is! Map) continue;

    final quantityRaw = item['quantity'];
    final quantity = quantityRaw is int
        ? quantityRaw
        : (quantityRaw is num ? quantityRaw.toInt() : 0);
    if (quantity <= 0) continue;

    try {
      final product = Product.fromJson(Map<String, dynamic>.from(productRaw));
      final existing = decoded[product.id];
      if (existing == null) {
        decoded[product.id] = CartItem(product: product, quantity: quantity);
      } else {
        decoded[product.id] = existing.copyWith(
          product: product,
          quantity: existing.quantity + quantity,
        );
      }
    } catch (_) {
      // Ignore malformed persisted item and continue decoding.
    }
  }

  return decoded;
}
