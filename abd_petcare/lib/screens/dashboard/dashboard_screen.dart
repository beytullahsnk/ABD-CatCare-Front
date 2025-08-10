import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/mock_api_service.dart';
import '../widgets/kpi_card.dart';

/// Ecran tableau de bord
/// - Récupère les métriques via MockApiService
/// - Affiche 4 cartes (Température, Humidité, Activité, Litière) avec icône et couleur
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _futureMetrics;
  final MockApiService _api = MockApiService();

  @override
  void initState() {
    super.initState();
    _futureMetrics = _api.fetchDashboardData();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureMetrics = _api.fetchDashboardData();
    });
    await _futureMetrics;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Se déconnecter')),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                // Déconnexion simple
                final messenger = ScaffoldMessenger.of(context);
                final cs = Theme.of(context).colorScheme;
                await AuthState.instance.setLoggedIn(false);
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: cs.secondary,
                    content: const Text('Déconnecté'),
                  ),
                );
                context.go('/login');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/settings/notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
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

                return ListView(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        KpiCard(
                          icon: Icons.thermostat,
                          label: 'Température',
                          value: '${temperature.toStringAsFixed(1)} °C',
                          status: (temperature < 36.0 || temperature > 39.0)
                              ? 'alert'
                              : 'ok',
                        ),
                        KpiCard(
                          icon: Icons.water_drop,
                          label: 'Humidité',
                          value: '$humidity %',
                          status:
                              (humidity < 30 || humidity > 60) ? 'warn' : 'ok',
                        ),
                        KpiCard(
                          icon: Icons.directions_run,
                          label: 'Activité',
                          value: '$activity %',
                          status: (activity < 30) ? 'warn' : 'ok',
                        ),
                        KpiCard(
                          icon: Icons.inventory_2_outlined,
                          label: 'Litière',
                          value: '$litterHumidity % humidité',
                          status: (litterHumidity > 50) ? 'alert' : 'ok',
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

// Cartes personnalisées remplacées par KpiCard (screens/widgets/kpi_card.dart)
