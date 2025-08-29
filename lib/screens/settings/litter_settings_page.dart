import 'package:flutter/material.dart';

class LitterPageSettings extends StatefulWidget {
  const LitterPageSettings({super.key});

  @override
  State<LitterPageSettings> createState() => _LitterPageState();
}

class _LitterPageState extends State<LitterPageSettings> {
  int humidity = 40;
  int passages = 3;
  bool notifications = true;

  void incHumidity() => setState(() => humidity = (humidity + 1).clamp(0, 100));
  void decHumidity() => setState(() => humidity = (humidity - 1).clamp(0, 100));
  void incPassages() => setState(() => passages = passages + 1);
  void decPassages() => setState(() => passages = (passages - 1).clamp(0, 999));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Litière'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingCard(
              icon: Icons.water_drop,
              title: "Seuil d'alerte du taux d'humidité",
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _SmallButton(icon: Icons.remove, onTap: decHumidity),
                  const SizedBox(width: 8),
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('$humidity%'),
                  ),
                  const SizedBox(width: 8),
                  _SmallButton(icon: Icons.add, onTap: incHumidity),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingCard(
              icon: Icons.directions_walk,
              title: 'Seuil de passages',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _SmallButton(icon: Icons.remove, onTap: decPassages),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('$passages'),
                  ),
                  const SizedBox(width: 8),
                  _SmallButton(icon: Icons.add, onTap: incPassages),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.notifications_none),
                const SizedBox(width: 12),
                const Expanded(child: Text('Notifications push')),
                Switch(
                    value: notifications,
                    onChanged: (v) => setState(() => notifications = v)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                final cs = Theme.of(context).colorScheme;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: const Text('Paramètres Litière enregistrés'),
                      backgroundColor: cs.secondary),
                );
              },
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text('Enregistrer')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SettingCard(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(width: 12),
          child,
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: cs.onPrimaryContainer),
      ),
    );
  }
}
