// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/api_provider.dart';
import '../../core/services/auth_state.dart';
import '../widgets/section_header.dart';
import '../widgets/metric_tile.dart';
import '../../core/constants/app_constants.dart';

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
  final _api = ApiProvider.instance.get();
  List<Map<String, dynamic>> _alerts = const [];
  int _currentIndex = 0;

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
          content: const Text('Impossible de charger les alertes'),
        ),
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
        title: const Text('Aperçu'),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'about', child: Text('À propos')),
              PopupMenuItem(value: 'logout', child: Text('Se déconnecter')),
            ],
            onSelected: (value) async {
              if (value == 'about') {
                if (!context.mounted) return;
                context.push('/about');
              } else if (value == 'logout') {
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
                context.push('/login');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              debugPrint(
                'Dashboard: notifications pressed -> settings_notifications',
              );
              context.pushNamed('settings_notifications').then((_) {
                if (!mounted) return;
                setState(() => _currentIndex = 0);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              debugPrint('Dashboard: profile pressed -> profile');
              context.pushNamed('profile').then((_) {
                if (!mounted) return;
                setState(() => _currentIndex = 0);
              });
            },
            tooltip: 'Profil',
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
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                final data = snapshot.data ?? <String, dynamic>{};

                final double temperature =
                    (data['temperature'] as num?)?.toDouble() ?? 0;
                final int humidity = (data['humidity'] as num?)?.toInt() ?? 0;
                // activityScore is available in data but not used in UI yet
                final int litterHumidity =
                    (data['litterHumidity'] as num?)?.toInt() ?? 0;
                final String lastSeen = data['lastSeen'] as String? ?? '';

                final theme = Theme.of(context);
                final cs = theme.colorScheme;
                return ListView(
                  children: [S
                    const SectionHeader('État général'),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/cat_default.png',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) {
                            debugPrint(
                              'Error loading asset default cat.png: $e',
                            );
                            return Center(
                              child: Icon(
                                Icons.pets,
                                size: 100,
                                color: cs.onPrimaryContainer,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'OK',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tout semble bien',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SectionHeader('Dernière activité'),
                    MetricTile(
                      title: 'Dort',
                      subtitle: lastSeen.isEmpty ? '—' : 'Il y a 1 heure',
                      leadingIcon: Icons.bedtime,
                      trailingThumb: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/inactive_cat.png',
                          width: 112,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) {
                            debugPrint(
                              'Error loading asset inactive_cat.png (thumb): $e',
                            );
                            return Container(
                              width: 112,
                              height: 64,
                              color: cs.primaryContainer,
                              child: Icon(
                                Icons.bedtime,
                                color: cs.onPrimaryContainer,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SectionHeader('Environnement'),
                    MetricTile(
                      title: '${temperature.toStringAsFixed(0)}°C',
                      subtitle: 'Température',
                      leadingIcon: Icons.thermostat,
                      trailingThumb: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/home_temp.png',
                          width: 112,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) {
                            debugPrint('Error loading asset home_temp.png: $e');
                            return Container(
                              width: 112,
                              height: 64,
                              color: cs.primaryContainer,
                              child: Icon(
                                Icons.thermostat,
                                color: cs.onPrimaryContainer,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    MetricTile(
                      title: '$humidity%',
                      subtitle: 'Humidité',
                      leadingIcon: Icons.water_drop,
                      trailingThumb: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/home_hum.png',
                          width: 112,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) {
                            debugPrint('Error loading asset home_hum.png: $e');
                            return Container(
                              width: 112,
                              height: 64,
                              color: cs.primaryContainer,
                              child: Icon(
                                Icons.water_drop,
                                color: cs.onPrimaryContainer,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SectionHeader('Bac à litière'),
                    MetricTile(
                      title: litterHumidity > kLitterHumidityHigh
                          ? 'Humide'
                          : 'Propre',
                      subtitle: 'Humidité ${litterHumidity}%',
                      leadingIcon: Icons.inventory_2,
                      trailingThumb: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/litiere.png',
                          width: 112,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) {
                            debugPrint('Error loading asset litiere.png: $e');
                            return Container(
                              width: 112,
                              height: 64,
                              color: cs.primaryContainer,
                              child: Icon(
                                Icons.inventory_2,
                                color: cs.onPrimaryContainer,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SectionHeader('Alertes'),
                    if (_alerts.isEmpty)
                      MetricTile(
                        title: 'Aucune alerte',
                        subtitle: 'Tout est normal',
                        leadingIcon: Icons.info_outline,
                      )
                    else
                      ..._alerts.map(
                        (a) => MetricTile(
                          title: '${a['type']}',
                          subtitle: '${a['message']}',
                          leadingIcon: a['level'] == 'warning'
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline,
                        ),
                      ),
                    const SizedBox(height: 8),
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

      // Barre de navigation visible **uniquement** sur le Dashboard
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              // déjà sur le dashboard
              break;
            case 1:
              context.pushNamed('litter').then((_) {
                if (!mounted) return;
                setState(() => _currentIndex = 0);
              });
              break;
            case 2:
              // open environment overview via named route
              context.pushNamed('environment').then((_) {
                if (!mounted) return;
                setState(() => _currentIndex = 0);
              });
              break;
            case 3:
              context.pushNamed('activity').then((_) {
                if (!mounted) return;
                setState(() => _currentIndex = 0);
              });
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        // show labels for clarity
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            // Litière: utiliser une icône de bac/boîte
            icon: Icon(Icons.inventory_2),
            label: 'Bac à litière',
          ),
          BottomNavigationBarItem(
            // Environnement: température/thermostat
            icon: Icon(Icons.thermostat_outlined),
            label: 'Environnement',
          ),
          BottomNavigationBarItem(
            // Activité: déplacement / course
            icon: Icon(Icons.directions_run_outlined),
            label: 'Activité',
          ),
        ],
      ),
    );
  }
}
