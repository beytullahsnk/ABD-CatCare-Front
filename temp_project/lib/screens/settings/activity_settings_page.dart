import 'package:flutter/material.dart';

class ActivitySettingsPage extends StatefulWidget {
  const ActivitySettingsPage({super.key});

  @override
  State<ActivitySettingsPage> createState() => _ActivitySettingsPageState();
}

class _ActivitySettingsPageState extends State<ActivitySettingsPage> {
  int triggerCount = 3;
  Duration inactivity = const Duration(hours: 1);
  bool notifications = true;

  void incTrigger() => setState(() => triggerCount = triggerCount + 1);
  void decTrigger() =>
      setState(() => triggerCount = (triggerCount - 1).clamp(0, 999));
  void incInactivity() =>
      setState(() => inactivity = inactivity + const Duration(minutes: 15));
  void decInactivity() => setState(() {
        final newDur = inactivity - const Duration(minutes: 15);
        inactivity = newDur.compareTo(Duration.zero) > 0
            ? newDur
            : const Duration(minutes: 15);
      });

  String _formatDuration(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Activité'),
          centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SettingCard(
            icon: Icons.directions_run,
            title: 'Déclenchement d\'activité',
            child: Row(
              children: [
                _SmallButton(icon: Icons.remove, onTap: decTrigger),
                const SizedBox(width: 8),
                Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('$triggerCount déclenchements')),
                const SizedBox(width: 8),
                _SmallButton(icon: Icons.add, onTap: incTrigger),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.timer,
            title: 'Déclenchement d\'inactivité',
            child: Row(
              children: [
                _SmallButton(icon: Icons.remove, onTap: decInactivity),
                const SizedBox(width: 8),
                Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(_formatDuration(inactivity))),
                const SizedBox(width: 8),
                _SmallButton(icon: Icons.add, onTap: incInactivity),
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
                    content: const Text('Paramètres Activité enregistrés'),
                    backgroundColor: cs.secondary),
              );
            },
            child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text('Enregistrer'))),
          ),
        ]),
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
      decoration: BoxDecoration(
          color: cs.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: cs.onSecondaryContainer)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(width: 12),
        child,
      ]),
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
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: cs.onPrimaryContainer)),
    );
  }
}
