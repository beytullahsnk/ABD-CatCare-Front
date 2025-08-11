import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/mock_api_service.dart';
import '../../core/services/auth_state.dart';
import '../widgets/kpi_card.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/status_utils.dart';

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
  List<Map<String, dynamic>> _alerts = const [];

  @override
  void initState() {
    super.initState();
    _futureMetrics = _api.fetchDashboardData();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final items = await _api.fetchAlerts();
      if (!mounted) return;
      setState(() => _alerts = items);
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: cs.error,
            content: const Text('Impossible de charger les alertes')),
      );
      setState(() => _alerts = const []);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _futureMetrics = _api.fetchDashboardData();
    });
    await _futureMetrics;
    await _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'about', child: Text('À propos')),
              PopupMenuItem(value: 'logout', child: Text('Se déconnecter')),
            ],
            onSelected: (value) async {
              if (value == 'about') {
                if (!context.mounted) return;
                context.go('/about');
              } else if (value == 'logout') {
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
                          value: temperature.toStringAsFixed(1),
                          subtitle: '°C',
                          status: kpiStatusForTemp(temperature),
                        ),
                        KpiCard(
                          icon: Icons.water_drop,
                          label: 'Humidité',
                          value: '$humidity',
                          subtitle: '%',
                          status: kpiStatusForHumidity(humidity),
                        ),
                        KpiCard(
                          icon: Icons.pets,
                          label: 'Activité',
                          value: '$activity',
                          subtitle: '%',
                          status: kpiStatusForActivity(activity),
                        ),
                        KpiCard(
                          icon: Icons.inventory_2,
                          label: 'Litière',
                          value: '$litterHumidity',
                          subtitle: '% humidité',
                          status: kpiStatusForLitterHumidity(litterHumidity),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Alertes récentes'),
                    const SizedBox(height: 8),
                    if (_alerts.isEmpty)
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 8),
                          const Text('Aucune alerte'),
                        ],
                      )
                    else
                      Column(
                        children: _alerts
                            .map((a) => ListTile(
                                  leading: Icon(
                                    a['level'] == 'warning'
                                        ? Icons.warning_amber_rounded
                                        : Icons.info_outline,
                                    color: a['level'] == 'warning'
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                  ),
                                  title: Text('${a['type']}'),
                                  subtitle: Text('${a['message']}'),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dernière activité'),
                      subtitle: Text(
                        lastSeen.isEmpty ? '—' : lastSeen.substring(11, 16),
                      ),
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
}

// Cartes personnalisées remplacées par KpiCard (screens/widgets/kpi_card.dart)
