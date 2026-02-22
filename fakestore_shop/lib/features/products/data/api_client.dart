import 'package:dio/dio.dart';
import '../../../core/network/api_paths.dart';

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<List<dynamic>> getProducts() async {
    final res = await _dio.get(ApiPaths.products);
    return (res.data as List).cast<dynamic>();
  }

  Future<Map<String, dynamic>> getProduct(int id) async {
    final res = await _dio.get(ApiPaths.product(id));
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<dynamic>> getCategories() async {
    final res = await _dio.get(ApiPaths.categories);
    return (res.data as List).cast<dynamic>();
  }

  Future<List<dynamic>> getProductsByCategory(String category) async {
    final res = await _dio.get(ApiPaths.productsByCategory(category));
    return (res.data as List).cast<dynamic>();
  }
}
