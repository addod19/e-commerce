import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/domain/product.dart';

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}

class CartNotifier extends StateNotifier<Map<int, CartItem>> {
  CartNotifier() : super(const {});

  void add(Product product) {
    final existing = state[product.id];
    if (existing == null) {
      state = {...state, product.id: CartItem(product: product, quantity: 1)};
      return;
    }

    state = {
      ...state,
      product.id: existing.copyWith(quantity: existing.quantity + 1),
    };
  }

  void decrement(int productId) {
    final existing = state[productId];
    if (existing == null) return;

    if (existing.quantity <= 1) {
      remove(productId);
      return;
    }

    state = {
      ...state,
      productId: existing.copyWith(quantity: existing.quantity - 1),
    };
  }

  void remove(int productId) {
    if (!state.containsKey(productId)) return;
    final next = Map<int, CartItem>.from(state);
    next.remove(productId);
    state = next;
  }

  void clear() {
    state = const {};
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<int, CartItem>>(
  (ref) => CartNotifier(),
);

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
