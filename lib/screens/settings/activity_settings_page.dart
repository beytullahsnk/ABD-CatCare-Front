import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Activity settings page: two sections (Activité, Inactivité). No cooldown.
class ActivitySettingsPage extends StatefulWidget {
  const ActivitySettingsPage({super.key});

  @override
  State<ActivitySettingsPage> createState() => _ActivitySettingsPageState();
}

class _ActivitySettingsPageState extends State<ActivitySettingsPage> {
  static const String _kTriggerCount = 'act_trigger_count';
  static const String _kWindowMin = 'act_window_min';
  static const String _kWindowInactivityMin = 'act_window_inactivity_min';
  static const String _kInactivityMin = 'act_inactivity_min';
  static const String _kAlertNoActivityMin = 'act_alert_no_activity_min';
  static const String _kNotif = 'act_notifications';

  int triggerCount = 3;
  int windowMinutes = 15;
  int windowInactivityMinutes = 60;
  int inactivityMin = 60;
  int alertNoActivityMin = 240;
  bool notifications = true;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      triggerCount = sp.getInt(_kTriggerCount) ?? triggerCount;
      windowMinutes = sp.getInt(_kWindowMin) ?? windowMinutes;
      windowInactivityMinutes =
          sp.getInt(_kWindowInactivityMin) ?? windowInactivityMinutes;
      inactivityMin = sp.getInt(_kInactivityMin) ?? inactivityMin;
      alertNoActivityMin =
          sp.getInt(_kAlertNoActivityMin) ?? alertNoActivityMin;
      notifications = sp.getBool(_kNotif) ?? notifications;
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kTriggerCount, triggerCount);
    await sp.setInt(_kWindowMin, windowMinutes);
    await sp.setInt(_kWindowInactivityMin, windowInactivityMinutes);
    await sp.setInt(_kInactivityMin, inactivityMin);
    await sp.setInt(_kAlertNoActivityMin, alertNoActivityMin);
    await sp.setBool(_kNotif, notifications);
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Paramètres Activité enregistrés'),
        backgroundColor: cs.secondary,
      ),
    );
  }

  void incTrigger() => setState(() => triggerCount = triggerCount + 1);
  void decTrigger() =>
      setState(() => triggerCount = (triggerCount - 1).clamp(0, 999));

  void incWindow() =>
      setState(() => windowMinutes = (windowMinutes + 5).clamp(1, 1440));
  void decWindow() =>
      setState(() => windowMinutes = (windowMinutes - 5).clamp(1, 1440));

  void incWindowInactivity() => setState(() =>
      windowInactivityMinutes = (windowInactivityMinutes + 5).clamp(1, 1440));
  void decWindowInactivity() => setState(() =>
      windowInactivityMinutes = (windowInactivityMinutes - 5).clamp(1, 1440));

  void incInactivity() =>
      setState(() => inactivityMin = (inactivityMin + 15).clamp(1, 10080));
  void decInactivity() =>
      setState(() => inactivityMin = (inactivityMin - 15).clamp(1, 10080));

  void incAlertNoActivity() => setState(
      () => alertNoActivityMin = (alertNoActivityMin + 60).clamp(0, 10080));
  void decAlertNoActivity() => setState(
      () => alertNoActivityMin = (alertNoActivityMin - 60).clamp(0, 10080));

  String _formatMin(int m) {
    if (m >= 60 && m % 60 == 0) return '${m ~/ 60}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar:
          AppBar(leading: const BackButton(), title: const Text('Activité')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activité section
            Text('Activité', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.pets,
              title: 'Déclenchement',
              child: Row(children: [
                _SmallButton(icon: Icons.remove, onTap: decTrigger),
                const SizedBox(width: 8),
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$triggerCount'),
                ),
                const SizedBox(width: 8),
                _SmallButton(icon: Icons.add, onTap: incTrigger),
              ]),
            ),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.schedule,
              title: 'Fenêtre (activité)',
              child: Row(children: [
                _SmallButton(icon: Icons.remove, onTap: decWindow),
                const SizedBox(width: 8),
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$windowMinutes min'),
                ),
                const SizedBox(width: 8),
                _SmallButton(icon: Icons.add, onTap: incWindow),
              ]),
            ),
            const SizedBox(height: 16),

            // Inactivité section
            Text('Inactivité', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.schedule_outlined,
              title: 'Fenêtre (inactivité)',
              child: Row(children: [
                _SmallButton(icon: Icons.remove, onTap: decWindowInactivity),
                const SizedBox(width: 8),
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$windowInactivityMinutes min'),
                ),
                const SizedBox(width: 8),
                _SmallButton(icon: Icons.add, onTap: incWindowInactivity),
              ]),
            ),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.timer,
              title: 'Durée minimale d\'inactivité',
              child: Row(children: [
                _SmallButton(icon: Icons.remove, onTap: decInactivity),
                const SizedBox(width: 8),
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_formatMin(inactivityMin)),
                ),
                const SizedBox(width: 8),
                _SmallButton(icon: Icons.add, onTap: incInactivity),
              ]),
            ),
            const SizedBox(height: 20),
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
            ElevatedButton(
              onPressed: _savePrefs,
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

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.child,
  });

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
