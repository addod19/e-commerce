class ApiPaths {
  static const baseUrl = 'https://fakestoreapi.com';

  static const products = '/products';
  static String product(int id) => '/products/$id';

  static const categories = '/products/categories';
  static String productsByCategory(String category) => '/products/category/$category';
}
