import 'package:flutter/material.dart';
import '../domain/products_failure.dart';

class ProductsErrorPresentation {
  const ProductsErrorPresentation({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;
}

ProductsErrorPresentation presentProductsError(Object error) {
  final failure = ProductsFailure.from(error);

  switch (failure.type) {
    case ProductsFailureType.server:
      return ProductsErrorPresentation(
        title: failure.title,
        message: failure.message,
        icon: Icons.dns_outlined,
      );
    case ProductsFailureType.slowNetwork:
      return ProductsErrorPresentation(
        title: failure.title,
        message: failure.message,
        icon: Icons.hourglass_bottom_rounded,
      );
    case ProductsFailureType.offline:
      return ProductsErrorPresentation(
        title: failure.title,
        message: failure.message,
        icon: Icons.wifi_off_rounded,
      );
    case ProductsFailureType.cacheCorrupted:
      return ProductsErrorPresentation(
        title: failure.title,
        message: failure.message,
        icon: Icons.storage_outlined,
      );
    case ProductsFailureType.malformedResponse:
      return ProductsErrorPresentation(
        title: failure.title,
        message: failure.message,
        icon: Icons.data_object_rounded,
      );
    case ProductsFailureType.unknown:
      return ProductsErrorPresentation(
        title: failure.title,
        message: failure.message,
        icon: Icons.error_outline_rounded,
      );
  }
}
