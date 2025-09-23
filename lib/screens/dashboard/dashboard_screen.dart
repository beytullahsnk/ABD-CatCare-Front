// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/services/api_provider.dart';
import '../../core/services/auth_state.dart';
import '../../core/services/auth_service.dart';
import '../widgets/section_header.dart';
import '../widgets/metric_tile.dart';
import '../../core/constants/app_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _fetchSensorAlerts(String catId) async {
    final token = AuthState.instance.accessToken;
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/sensors/alerts/$catId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        
        // fait en sorte que le jsondecode se fasse sur 
        /* 
        [
          {
            "id": "c1803ab7-9e8d-42d8-b0bf-85f6989230cb",
            "createdAt": "2025-09-11T03:55:56.353Z",
            "updatedAt": "2025-09-10T20:19:37.876Z",
            "catId": "6e927a54-b1eb-41ec-9547-8f5f4e2777e9",
            "type": "temperature_high",
            "message": "Température élevée détectée",
            "severity": "high",
            "isResolved": false
          }
        ]

        afin de pouvoir faire un test
        */
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _sensorAlerts = List<Map<String, dynamic>>.from(data);
          });
        } else {
          setState(() {
            _sensorAlerts = [];
          });
        }
      } else {
        print('Erreur API /sensors/alerts/$catId: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erreur réseau /sensors/alerts/$catId: $e');
    }
  }
  List<Map<String, dynamic>> _sensorAlerts = [];
  Map<String, dynamic>? _sensorData;
  Map<String, dynamic>? _firstCat;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAndLogFirstCat();
  }

  Future<void> _fetchAndLogFirstCat() async {
    // Après avoir fetch le chat, fetch les alertes capteur
    try {
      final data = await AuthService.instance.fetchUserWithCats();
      final cats = data?['extras']?['cats'] as List?;
      if (cats != null && cats.isNotEmpty) {
        setState(() {
          _firstCat = Map<String, dynamic>.from(cats.first);
        });
        print('Premier chat: ${cats.first}');
        await _fetchSensorData(_firstCat!['id']);
      } else {
        setState(() {
          _firstCat = null;
          _sensorData = null;
        });
        print('Aucun chat trouvé dans la réponse.');
      }
    } catch (e) {
      print('Erreur fetchUserWithCats: $e');
    }
  }

  Future<void> _fetchSensorData(String catId) async {
    await _fetchSensorAlerts(catId);
    final api = ApiProvider.instance.get();
    final data = await api.fetchLatestSensorData(catId);
    setState(() {
      _sensorData = data;
    });
  }
  late Future<Map<String, dynamic>> _futureMetrics;
  final _api = ApiProvider.instance.get();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _futureMetrics = _api.fetchDashboardData();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
  // plus d'usage de _alerts, fonction conservée pour compatibilité éventuelle
  }

  Future<void> _refresh() async {
    setState(() {
      _futureMetrics = _api.fetchDashboardData();
    });
    await _futureMetrics;
    await _loadAlerts();
    await _fetchAndLogFirstCat();
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
                  children: [
                    SectionHeader(_firstCat != null
                        ? 'État général de ${_firstCat!['name'] ?? ''}'
                        : 'État général'),
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
                      title: lastSeen.isNotEmpty ? 'En activité' : 'Dort',
                      subtitle: lastSeen.isNotEmpty 
                          ? lastSeen 
                          : (_firstCat != null &&
                              _firstCat!['activityThresholds'] != null &&
                              _firstCat!['activityThresholds']['collar'] != null &&
                              _firstCat!['activityThresholds']['collar']['inactivityHours'] != null
                          ? 'Dort depuis ${_firstCat!['activityThresholds']['collar']['inactivityHours']} heures'
                          : 'Aucune donnée d\'activité disponible'),
                      leadingIcon: lastSeen.isNotEmpty ? Icons.pets : Icons.bedtime,
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
                                Icons.pets,
                                color: cs.onPrimaryContainer,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SectionHeader('Environnement'),
                    MetricTile(
                      title: _sensorData != null && _sensorData!['temperature'] != null
                          ? '${_sensorData!['temperature']}°C'
                          : (_firstCat != null &&
                              _firstCat!['activityThresholds'] != null &&
                              _firstCat!['activityThresholds']['environment'] != null &&
                              _firstCat!['activityThresholds']['environment']['temperatureMin'] != null &&
                              _firstCat!['activityThresholds']['environment']['temperatureMax'] != null
                              ? '${_firstCat!['activityThresholds']['environment']['temperatureMin']}°C / ${_firstCat!['activityThresholds']['environment']['temperatureMax']}°C'
                              : '${temperature.toStringAsFixed(0)}°C'),
                      subtitle: 'Température mesurée',
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
                      title: _sensorData != null && _sensorData!['humidity'] != null
                          ? '${_sensorData!['humidity']}%'
                          : (_firstCat != null &&
                              _firstCat!['activityThresholds'] != null &&
                              _firstCat!['activityThresholds']['environment'] != null &&
                              _firstCat!['activityThresholds']['environment']['humidityMin'] != null &&
                              _firstCat!['activityThresholds']['environment']['humidityMax'] != null
                              ? '${_firstCat!['activityThresholds']['environment']['humidityMin']}% / ${_firstCat!['activityThresholds']['environment']['humidityMax']}%'
                              : '$humidity%'),
                      subtitle:'Humidité mesurée',
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
                      title: _firstCat != null &&
                              _firstCat!['activityThresholds'] != null &&
                              _firstCat!['activityThresholds']['litter'] != null &&
                              _firstCat!['activityThresholds']['litter']['humidityMin'] != null &&
                              _firstCat!['activityThresholds']['litter']['humidityMax'] != null
                          ? 'Humidité ${_firstCat!['activityThresholds']['litter']['humidityMin']}% / ${_firstCat!['activityThresholds']['litter']['humidityMax']}%'
                          : 'Humidité ${litterHumidity}%',
                      subtitle: litterHumidity > kLitterHumidityHigh
                          ? 'Humide'
                          : 'Propre',
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
                    if (_sensorAlerts.isEmpty)
                      MetricTile(
                        title: 'Aucune alerte',
                        subtitle: 'Tout est normal',
                        leadingIcon: Icons.info_outline,
                      )
                    else
                      ..._sensorAlerts.map(
                        (a) => MetricTile(
                          title: a['type'] ?? 'Alerte',
                          subtitle: a['message'] ?? '',
                          leadingIcon: (a['severity'] == 'high')
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),

      // Barre de navigation + bouton flottant centré
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Bouton actualiser : recharger les données
            _refresh();
            return;
          }
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              context.pushNamed('litter').then((_) {
                if (!mounted) return;
                setState(() => _currentIndex = 0);
              });
              break;
            case 3:
              context.pushNamed('environment').then((_) {
                if (!mounted) return;
                setState(() => _currentIndex = 0);
              });
              break;
            case 4:
              context.pushNamed('activity').then((_) {
                if (!mounted) return;
                setState(() => _currentIndex = 0);
              });
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Bac à litière',
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 32,
              ),
            ),
            label: 'Actualiser',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.thermostat_outlined),
            label: 'Environnement',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Activité',
          ),
        ],
      ),
    );
  }
}
