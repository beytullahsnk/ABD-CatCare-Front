import 'package:flutter/material.dart';

/// Widget KPI réutilisable
/// status: 'ok' | 'warn' | 'alert'
class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String status;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Choix des couleurs par status (Material 3)
    final Color container;
    final Color onContainer;
    final Color iconColor;
    switch (status) {
      case 'alert':
        container = cs.errorContainer;
        onContainer = cs.onErrorContainer;
        iconColor = cs.error;
        break;
      case 'warn':
        container = cs.tertiaryContainer;
        onContainer = cs.onTertiaryContainer;
        iconColor = cs.tertiary;
        break;
      case 'ok':
      default:
        container = cs.secondaryContainer;
        onContainer = cs.onSecondaryContainer;
        iconColor = cs.secondary;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Card(
        color: container,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: onContainer)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
