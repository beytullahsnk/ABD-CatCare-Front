// lib/screens/environnement/environment_settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnvironmentSettingsPage extends StatefulWidget {
  const EnvironmentSettingsPage({super.key});

  @override
  State<EnvironmentSettingsPage> createState() =>
      _EnvironmentSettingsPageState();
}

class _EnvironmentSettingsPageState extends State<EnvironmentSettingsPage> {
  static const String _kMinKey = 'env_min';
  static const String _kMaxKey = 'env_max';
  static const String _kThresholdKey = 'env_threshold';
  static const String _kNotifKey = 'env_notifications';

  int tempMin = 0;
  int tempMax = 30;
  int tempThreshold = 30;
  bool notifications = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      tempMin = sp.getInt(_kMinKey) ?? tempMin;
      tempMax = sp.getInt(_kMaxKey) ?? tempMax;
      tempThreshold = sp.getInt(_kThresholdKey) ?? tempThreshold;
      notifications = sp.getBool(_kNotifKey) ?? notifications;
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    setState(() => _saving = true);
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kMinKey, tempMin);
    await sp.setInt(_kMaxKey, tempMax);
    await sp.setInt(_kThresholdKey, tempThreshold);
    await sp.setBool(_kNotifKey, notifications);
    if (!mounted) return;
    setState(() => _saving = false);
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Paramètres Environnement enregistrés'),
        backgroundColor: cs.secondary,
      ),
    );
  }

  void incMin() => setState(() => tempMin = (tempMin + 1).clamp(-50, tempMax));
  void decMin() => setState(() => tempMin = (tempMin - 1).clamp(-50, tempMax));
  void incMax() => setState(() => tempMax = (tempMax + 1).clamp(tempMin, 100));
  void decMax() => setState(() => tempMax = (tempMax - 1).clamp(tempMin, 100));
  void incThresh() =>
      setState(() => tempThreshold = (tempThreshold + 1).clamp(-50, 100));
  void decThresh() =>
      setState(() => tempThreshold = (tempThreshold - 1).clamp(-50, 100));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Environnement'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingCard(
                    icon: Icons.thermostat,
                    title: 'Température minimum',
                    child: _MinMaxColumn(
                      label: 'Min',
                      valueText: '$tempMin°C',
                      onDec: decMin,
                      onInc: incMin,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingCard(
                    icon: Icons.thermostat_auto,
                    title: 'Seuil de température maximum',
                    child: Row(
                      children: [
                        _SmallButton(icon: Icons.remove, onTap: decThresh),
                        const SizedBox(width: 8),
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$tempThreshold°C'),
                        ),
                        const SizedBox(width: 8),
                        _SmallButton(icon: Icons.add, onTap: incThresh),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Notifications',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        ElevatedButton(
                          onPressed: _saving ? null : _savePrefs,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                                48), // force la pleine largeur
                          ),
                          child: const Text('Enregistrer'),
                        ),
                        if (_saving)
                          const Positioned(
                            right: 16,
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
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
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
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

class _MinMaxColumn extends StatelessWidget {
  final String label;
  final String valueText;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final ThemeData theme;
  const _MinMaxColumn({
    required this.label,
    required this.valueText,
    required this.onDec,
    required this.onInc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        Row(
          children: [
            _SmallButton(icon: Icons.remove, onTap: onDec),
            const SizedBox(width: 6),
            Container(
              width: 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(valueText),
            ),
            const SizedBox(width: 6),
            _SmallButton(icon: Icons.add, onTap: onInc),
          ],
        ),
      ],
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
