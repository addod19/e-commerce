import 'dart:async';
import 'package:flutter/material.dart';

class SlowAwareLoadingView extends StatefulWidget {
  const SlowAwareLoadingView({
    super.key,
    this.label = 'Loading...',
    this.slowHintDelay = const Duration(seconds: 4),
  });

  final String label;
  final Duration slowHintDelay;

  @override
  State<SlowAwareLoadingView> createState() => _SlowAwareLoadingViewState();
}

class _SlowAwareLoadingViewState extends State<SlowAwareLoadingView> {
  Timer? _timer;
  bool _showSlowHint = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.slowHintDelay, () {
      if (!mounted) return;
      setState(() => _showSlowHint = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 12),
            Text(widget.label),
            if (_showSlowHint) ...[
              const SizedBox(height: 8),
              Text(
                'This is taking longer than usual. Network may be slow.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
