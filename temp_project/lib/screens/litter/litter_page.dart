import 'package:flutter/material.dart';

class LitterPage extends StatelessWidget {
  const LitterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Bac à litière"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Utilisation quotidienne + propreté
            Row(
              children: const [
                Expanded(
                  child: _InfoCard(
                      title: "Utilisation quotidienne", value: "3 fois"),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(title: "Propreté", value: "75%"),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Journal d'activité
            const Text(
              "Journal d'activité",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const _ActivityLog(time: "10h15"),
            const _ActivityLog(time: "7h30"),
            const _ActivityLog(time: "5h00"),
            const SizedBox(height: 24),

            // Comportement inhabituel
            const Text(
              "Comportement inhabituel",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        "Visites fréquentes\nFréquence accrue des visites"),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(
              icon: Icon(Icons.pets), label: "Bac à litière"),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk), label: "Activité"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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

class _ActivityLog extends StatelessWidget {
  final String time;
  const _ActivityLog({required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.pets, size: 20),
        const SizedBox(width: 10),
        Text(time, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
