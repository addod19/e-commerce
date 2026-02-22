import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

class CategoriesState {
  final List<String> categories;
  const CategoriesState(this.categories);
}

class CategoriesNotifier extends AutoDisposeAsyncNotifier<CategoriesState> {
  @override
  Future<CategoriesState> build() async {
    final repo = ref.read(productsRepositoryProvider);
    final cats = await repo.getCategories();
    return CategoriesState(cats);
  }
}
