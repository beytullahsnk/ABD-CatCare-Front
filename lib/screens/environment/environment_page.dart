import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/api_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/services/auth_state.dart';
import 'package:go_router/go_router.dart'; 
import '../../models/ruuvi_tag.dart'; 

class EnvironmentPage extends StatefulWidget {
  const EnvironmentPage({super.key});

  @override
  State<EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> {
  double? _temperature;
  int? _humidity;
  bool _loading = true;
  List<Map<String, dynamic>> _historicalData = [];

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
  }

  Future<void> _fetchSensorData() async {
    final api = ApiProvider.instance.get();
    // Récupérer le vrai catId depuis les données utilisateur
    final catId = await _getUserCatId();
    if (catId != null) {
      // Récupérer les données actuelles
      final data = await api.fetchLatestSensorData(catId);
      
      // Récupérer les données d'historique
      final historicalData = await _fetchHistoricalData(catId);
      
      setState(() {
        final envData = data?['environment'];
        _temperature = envData != null && envData['temperature'] != null 
            ? double.tryParse(envData['temperature'].toString()) 
            : null;
        _humidity = envData != null && envData['humidity'] != null 
            ? double.tryParse(envData['humidity'].toString())?.round() 
            : null;
        _historicalData = historicalData;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHistoricalData(String catId) async {
    try {
      final token = AuthState.instance.accessToken;
      if (token == null || token.isEmpty) return [];

      // D'abord, récupérer les RuuviTags pour faire le mapping
      final ruuviTagsResp = await http.get(
        Uri.parse('http://localhost:3000/api/ruuvitags'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, String> ruuviTagToType = {};
      if (ruuviTagsResp.statusCode == 200) {
        final ruuviTagsData = jsonDecode(ruuviTagsResp.body);
        if (ruuviTagsData['state'] == true && ruuviTagsData['data'] != null) {
          final ruuviTags = (ruuviTagsData['data'] as List)
              .map((tag) => RuuviTag.fromJson(tag))
              .where((tag) => tag.catIds != null && tag.catIds!.contains(catId))
              .toList();
          
          for (final tag in ruuviTags) {
            ruuviTagToType[tag.id] = tag.type.value;
          }
        }
      }

      // Récupérer les données d'historique depuis l'API
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/ruuvitags/data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['state'] == true && data['data'] != null) {
          final sensorData = data['data']['items'] as List;
          
          // Filtrer les données d'environnement et les trier par timestamp
          final envData = sensorData
              .where((item) {
                final ruuviTagId = item['ruuvitagId'] as String?;
                return ruuviTagId != null && 
                       ruuviTagToType.containsKey(ruuviTagId) && 
                       ruuviTagToType[ruuviTagId] == 'ENVIRONMENT';
              })
              .cast<Map<String, dynamic>>()
              .toList();
          
          // Trier par timestamp (plus récent en premier)
          envData.sort((a, b) {
            final aTime = DateTime.tryParse(a['timestamp'] ?? '');
            final bTime = DateTime.tryParse(b['timestamp'] ?? '');
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          
          return envData;
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des données d\'historique: $e');
    }
    return [];
  }

  List<FlSpot> _buildTemperatureSpots() {
    if (_historicalData.isEmpty) return [];
    
    final spots = <FlSpot>[];
    for (int i = 0; i < _historicalData.length && i < 7; i++) {
      final data = _historicalData[i];
      final temp = double.tryParse(data['temperature']?.toString() ?? '');
      if (temp != null) {
        spots.add(FlSpot(i.toDouble(), temp));
      }
    }
    return spots;
  }

  List<FlSpot> _buildHumiditySpots() {
    if (_historicalData.isEmpty) return [];
    
    final spots = <FlSpot>[];
    for (int i = 0; i < _historicalData.length && i < 7; i++) {
      final data = _historicalData[i];
      final humidity = double.tryParse(data['humidity']?.toString() ?? '');
      if (humidity != null) {
        spots.add(FlSpot(i.toDouble(), humidity));
      }
    }
    return spots;
  }

  Future<String?> _getUserCatId() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['state'] == true && data['extras'] != null) {
          final cats = data['extras']['cats'] as List<dynamic>?;
          if (cats != null && cats.isNotEmpty) {
            return cats[0]['id'] as String;
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération du chat utilisateur: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Environnement'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings/environment'),
            tooltip: 'Paramètres des seuils',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Données actuelles
            Row(
              children: [
                _InfoCard(
                  title: "Température",
                  value: _loading
                      ? "..."
                      : _temperature != null
                          ? "${_temperature!.toStringAsFixed(1)}°C"
                          : "-",
                ),
                const SizedBox(width: 16),
                _InfoCard(
                  title: "Humidité",
                  value: _loading
                      ? "..."
                      : _humidity != null
                          ? "${_humidity!.toString()}%"
                          : "-",
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Historique avec vraies données
            const Text("Historique", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            if (_historicalData.isNotEmpty) ...[
              _ChartSection(
                title: "Température",
                value: _temperature != null ? "${_temperature!.toStringAsFixed(1)}°C" : "-",
                variation: _historicalData.length > 1 ? "+0%" : "N/A",
                isPositive: true,
                spots: _buildTemperatureSpots(),
              ),
              const SizedBox(height: 24),
              _ChartSection(
                title: "Humidité",
                value: _humidity != null ? "${_humidity!.toString()}%" : "-",
                variation: _historicalData.length > 1 ? "+0%" : "N/A",
                isPositive: false,
                spots: _buildHumiditySpots(),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune donnée d\'historique disponible',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'L\'historique apparaîtra ici une fois que les capteurs enverront des données.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Petit widget pour les cartes Température / Humidité
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Section avec graphique
class _ChartSection extends StatelessWidget {
  final String title;
  final String value;
  final String variation;
  final bool isPositive;
  final List<FlSpot> spots;

  const _ChartSection({
    required this.title,
    required this.value,
    required this.variation,
    required this.isPositive,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          "7 derniers jours $variation",
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
                      if (value.toInt() < days.length) {
                        return Text(days[value.toInt()]);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: spots,
                  color: Colors.blue,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
