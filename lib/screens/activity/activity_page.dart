import 'package:flutter/material.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Activité"),
        centerTitle: true,
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fake map preview
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.map, size: 60, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 24),

              // Statistiques de mouvement
              const Text(
                "Statistiques de mouvement",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(title: "Temps actif", value: "2h 30m"),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(title: "Temps inactif", value: "1h 15m"),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Activité quotidienne
              const Text(
                "Activité quotidienne",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Activité quotidienne",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const Text(
                "3h 45m",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              const Text(
                "7 derniers jours   +15%",
                style: TextStyle(color: Colors.green, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Graphique simple (barres grises identiques)
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    _Bar(label: "Lun", height: 80),
                    _Bar(label: "Mar", height: 80),
                    _Bar(label: "Mer", height: 80),
                    _Bar(label: "Jeu", height: 80),
                    _Bar(label: "Ven", height: 80),
                    _Bar(label: "Sam", height: 80),
                    _Bar(label: "Dim", height: 80),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double height;
  const _Bar({required this.label, required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            )),
      ],
    );
  }
}
