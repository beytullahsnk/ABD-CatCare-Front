import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/mock_api_service.dart';

/// Ecran tableau de bord
/// - Récupère les métriques via MockApiService
/// - Affiche 4 cartes (Température, Humidité, Activité, Litière) avec icône et couleur
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<Map<String, dynamic>> _futureMetrics;
  final MockApiService _api = MockApiService();

  @override
  void initState() {
    super.initState();
    _futureMetrics = _api.fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/settings/notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _futureMetrics,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erreur: ${snapshot.error}'),
                );
              }
              final data = snapshot.data ?? <String, dynamic>{};

              final double temperature =
                  (data['temperature'] as num?)?.toDouble() ?? 0;
              final int humidity = (data['humidity'] as num?)?.toInt() ?? 0;
              final int activity =
                  (data['activityScore'] as num?)?.toInt() ?? 0;
              final int litterHumidity =
                  (data['litterHumidity'] as num?)?.toInt() ?? 0;
              final String lastSeen = data['lastSeen'] as String? ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricCard(
                        title: 'Température',
                        icon: Icons.thermostat,
                        valueText: '${temperature.toStringAsFixed(1)}°C',
                        status: _metricStatus(
                            isAlert: temperature < 36.0 || temperature > 39.0),
                      ),
                      _MetricCard(
                        title: 'Humidité',
                        icon: Icons.water_drop,
                        valueText: '$humidity%',
                        status: _metricStatus(
                            isAlert: humidity < 30 || humidity > 60),
                      ),
                      _MetricCard(
                        title: 'Activité',
                        icon: Icons.directions_run,
                        valueText: '$activity',
                        status: _metricStatus(isAlert: activity < 30),
                      ),
                      _MetricCard(
                        title: 'Litière',
                        icon: Icons.inventory_2_outlined,
                        valueText: '$litterHumidity%',
                        status: _metricStatus(isAlert: litterHumidity > 50),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dernière activité'),
                    subtitle: Text(lastSeen.isEmpty ? '—' : lastSeen),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Retourne les couleurs d'état (ok/alerte) basées sur le thème courant
  _StatusColors _metricStatus({required bool isAlert}) {
    final cs = Theme.of(context).colorScheme;
    if (isAlert) {
      return _StatusColors(
        container: cs.errorContainer,
        onContainer: cs.onErrorContainer,
        icon: cs.error,
      );
    }
    return _StatusColors(
      container: cs.secondaryContainer,
      onContainer: cs.onSecondaryContainer,
      icon: cs.secondary,
    );
  }
}

class _StatusColors {
  final Color container;
  final Color onContainer;
  final Color icon;

  const _StatusColors({
    required this.container,
    required this.onContainer,
    required this.icon,
  });
}

/// Carte de métrique (Material 3)
class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String valueText;
  final _StatusColors status;

  const _MetricCard({
    required this.title,
    required this.icon,
    required this.valueText,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Card(
        color: status.container,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: status.icon),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: status.onContainer)),
                  const SizedBox(height: 6),
                  Text(
                    valueText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: status.onContainer,
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
