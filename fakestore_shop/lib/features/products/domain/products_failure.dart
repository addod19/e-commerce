enum ProductsFailureType {
  server,
  slowNetwork,
  offline,
  cacheCorrupted,
  malformedResponse,
  unknown,
}

class ProductsFailure implements Exception {
  const ProductsFailure._({
    required this.type,
    required this.title,
    required this.message,
    this.statusCode,
  });

  final ProductsFailureType type;
  final String title;
  final String message;
  final int? statusCode;

  factory ProductsFailure.server({int? statusCode}) => ProductsFailure._(
    type: ProductsFailureType.server,
    title: 'Server error',
    message: statusCode == null
        ? 'The server failed to process the request. Please retry.'
        : 'The server failed to process the request (HTTP $statusCode). Please retry.',
    statusCode: statusCode,
  );

  factory ProductsFailure.slowNetwork() => const ProductsFailure._(
    type: ProductsFailureType.slowNetwork,
    title: 'Slow network',
    message:
        'The request timed out. Please check your connection and try again.',
  );

  factory ProductsFailure.offline() => const ProductsFailure._(
    type: ProductsFailureType.offline,
    title: 'You are offline',
    message: 'No internet connection and no usable cached data is available.',
  );

  factory ProductsFailure.cacheCorrupted() => const ProductsFailure._(
    type: ProductsFailureType.cacheCorrupted,
    title: 'Corrupted local data',
    message:
        'Saved data is corrupted. Reconnect to the internet and retry to rebuild cache.',
  );

  factory ProductsFailure.malformedResponse() => const ProductsFailure._(
    type: ProductsFailureType.malformedResponse,
    title: 'Invalid data received',
    message: 'The server returned invalid data. Please try again.',
  );

  factory ProductsFailure.unknown() => const ProductsFailure._(
    type: ProductsFailureType.unknown,
    title: 'Unexpected error',
    message: 'Something went wrong. Please try again.',
  );

  static ProductsFailure from(Object error) {
    if (error is ProductsFailure) return error;
    return ProductsFailure.unknown();
  }

  @override
  String toString() => message;
}
