import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final cacheBoxProvider = Provider<Box>((ref) {
  // This is set up in main() after Hive init.
  throw UnimplementedError('Override cacheBoxProvider in main()');
});
