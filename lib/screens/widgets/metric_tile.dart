import 'package:flutter/material.dart';

class MetricTile extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Optional leading icon (legacy)
  final IconData? leadingIcon;

  /// Optional leading widget (preferred) - can be Image.asset or any widget
  final Widget? leadingWidget;
  final Widget? trailingThumb;
  const MetricTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingIcon,
    this.leadingWidget,
    this.trailingThumb,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: leadingWidget ??
                (leadingIcon != null
                    ? Icon(leadingIcon, color: cs.onSecondaryContainer)
                    : const SizedBox.shrink()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailingThumb ?? _ThumbPlaceholder(color: cs.primaryContainer),
        ],
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  final Color color;
  const _ThumbPlaceholder({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
