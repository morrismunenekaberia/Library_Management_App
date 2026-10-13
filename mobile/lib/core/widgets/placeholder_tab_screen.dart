import 'package:flutter/material.dart';

/// Generic placeholder screen for tabs whose dedicated implementation is not yet built.
class PlaceholderTabScreen extends StatefulWidget {
  final String title;
  final IconData icon;

  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  State<PlaceholderTabScreen> createState() => _PlaceholderTabScreenState();
}

class _PlaceholderTabScreenState extends State<PlaceholderTabScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This section is coming soon.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

