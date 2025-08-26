import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EnvironmentPage extends StatelessWidget {
  const EnvironmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Environnement"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Température et Humidité
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoCard(title: "Température", value: "22°C"),
                _InfoCard(title: "Humidité", value: "55%"),
              ],
            ),
            const SizedBox(height: 20),

            // Historique
            const Text("Historique",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _ChartSection(
              title: "Température",
              value: "22°C",
              variation: "+2%",
              isPositive: true,
              spots: [
                FlSpot(0, 21),
                FlSpot(1, 22),
                FlSpot(2, 21.5),
                FlSpot(3, 22.2),
                FlSpot(4, 21.8),
                FlSpot(5, 23),
                FlSpot(6, 22.5),
              ],
            ),
            const SizedBox(height: 24),

            _ChartSection(
              title: "Humidité",
              value: "55%",
              variation: "-1%",
              isPositive: false,
              spots: [
                FlSpot(0, 57),
                FlSpot(1, 56),
                FlSpot(2, 55.5),
                FlSpot(3, 54),
                FlSpot(4, 55),
                FlSpot(5, 56),
                FlSpot(6, 55),
              ],
            ),
            const SizedBox(height: 24),

            // Alertes
            const Text("Alertes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _AlertCard(
              icon: Icons.thermostat,
              title: "Température élevée",
              subtitle: "Température supérieure à 25°C",
              time: "Il y a 2h",
            ),
            _AlertCard(
              icon: Icons.water_drop,
              title: "Faible humidité",
              subtitle: "Humidité inférieure à 40%",
              time: "Hier",
            ),
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

/// Carte alerte
class _AlertCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _AlertCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(time, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
