import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product.dart';
import 'providers.dart';

class ProductDetailState {
  final Product product;
  const ProductDetailState(this.product);
}

class ProductDetailNotifier extends AutoDisposeAsyncNotifier<ProductDetailState> {
  late final int productId;

  @override
  Future<ProductDetailState> build() async {
    throw UnimplementedError('Use the family provider');
  }

  Future<ProductDetailState> buildWithId(int id) async {
    productId = id;
    final repo = ref.read(productsRepositoryProvider);
    final product = await repo.getProduct(id);
    return ProductDetailState(product);
  }
}

// Riverpod family uses this hook:
extension ProductDetailFamily on ProductDetailNotifier {
  Future<ProductDetailState> build(int id) => buildWithId(id);
}
