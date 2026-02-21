import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool visible;
  const OfflineBanner({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return MaterialBanner(
      content: const Text('Offline mode: showing cached data.'),
      leading: const Icon(Icons.wifi_off),
      actions: const [SizedBox(width: 8)],
    );
  }
}
