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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                    title: "Utilisation quotidienne",
                    value: "3 fois",
                  ),
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
            // afficher la ligne (dash) après chaque icône sauf la dernière
            const _ActivityLog(time: "10h15", showLine: true),
            const _ActivityLog(time: "7h30", showLine: true),
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.black87),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Visites fréquentes",
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        SizedBox(height: 2),
                        Text("Fréquence accrue des visites",
                            style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
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
        // colonne avec icône + ligne centrée (ligne a une largeur non nulle)
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
            // Ligne en pointillés si nécessaire : donner une width > 0 pour que CustomPaint ait une taille
            if (showLine)
              SizedBox(
                width:
                    2, // largeur du trait (CustomPaint recevra size.width = 2)
                height: 30, // hauteur entre deux icônes
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

// Painter pour dessiner une ligne en pointillés
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 6.0;
    double startY = 0;
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = size.width // utiliser la largeur fournie pour l'épaisseur
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
