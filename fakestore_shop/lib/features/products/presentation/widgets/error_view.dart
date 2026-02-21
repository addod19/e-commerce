import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final IconData? icon;

  const ErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 42, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 10),
            ],
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
