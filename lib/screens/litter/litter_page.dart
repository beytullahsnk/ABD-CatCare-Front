import 'package:flutter/material.dart';
import 'package:abd_petcare/core/services/api_provider.dart';
import 'package:abd_petcare/core/services/api_service.dart';
import 'package:go_router/go_router.dart'; 

class LitterPage extends StatelessWidget {
  const LitterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Bac à litière"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings/litter'),
            tooltip: 'Paramètres des seuils',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ??
              const {
                'dailyUsage': 0,
                'cleanliness': 0,
                'events': <String>[],
                'anomalies': <String>[],
              };
          final daily = data['dailyUsage'] as int? ?? 0;
          final cleanliness = data['cleanliness'] as int? ?? 0;
          final events = (data['events'] as List?)?.cast<String>() ?? const [];
          final anomalies =
              (data['anomalies'] as List?)?.cast<String>() ?? const [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Utilisation quotidienne + propreté
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        title: "Utilisation quotidienne",
                        value: "$daily fois",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        title: "Humidité", 
                        value: "$cleanliness%",
                      ),
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
                if (events.isEmpty)
                  const Text("Aucun passage récent",
                      style: TextStyle(color: Colors.black54))
                else ...[
                  for (int i = 0; i < events.length; i++)
                    _ActivityLog(
                      time: events[i],
                      showLine: i != events.length - 1,
                    ),
                ],
                const SizedBox(height: 24),

                // Comportement inhabituel
                const Text(
                  "Comportement inhabituel",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (anomalies.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      "Rien à signaler",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final a in anomalies)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.black87),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(a,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<Map<String, dynamic>> _fetch() async {
  final api = ApiProvider.instance.get();
  if (api is RealApiService) {
    return api.fetchLitterData();
  }
  // Retourner des données vides si le service n'est pas disponible
  return const {
    'dailyUsage': 0,
    'cleanliness': 0,
    'events': <String>[],
    'anomalies': <String>[],
  };
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActivityLog extends StatelessWidget {
  final String time;
  final bool showLine; // pour savoir si on affiche le trait après l’icône
  const _ActivityLog({required this.time, this.showLine = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icône chat dans un cercle
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black12,
              ),
              child: const Icon(Icons.pets, size: 18, color: Colors.black87),
            ),
            if (showLine)
              SizedBox(
                width: 2,
                height: 30,
                child: CustomPaint(painter: _DashedLinePainter()),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Text(time, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 6.0;
    double startY = 0;
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    while (startY < size.height) {
      final endY = (startY + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(centerX, startY), Offset(centerX, endY), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
