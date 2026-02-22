import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product.dart';
import 'providers.dart';

class ProductDetailState {
  final Product product;
  const ProductDetailState(this.product);
}

class ProductDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<ProductDetailState, int> {
  @override
  Future<ProductDetailState> build(int id) async {
    final repo = ref.read(productsRepositoryProvider);
    final product = await repo.getProduct(id);
    return ProductDetailState(product);
  }
}
