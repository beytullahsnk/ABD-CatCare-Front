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
  // humidity and pressure keys
  static const String _kHumMinKey = 'env_hum_min';
  static const String _kHumMaxKey = 'env_hum_max';
  static const String _kHumSustainedKey = 'env_hum_sustained_min';
  static const String _kPressureChangeKey = 'env_pressure_change_hpa';
  static const String _kPressureSustainedKey = 'env_pressure_sustained_min';

  int tempMin = 0;
  int tempMax = 30;
  int tempThreshold = 30;
  int humMin = 30;
  int humMax = 60;
  int humSustainedMin = 20; // minutes
  int pressureChangeHpa = 5;
  int pressureSustainedMin = 60; // minutes
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
      // load humidity & pressure
      humMin = sp.getInt(_kHumMinKey) ?? humMin;
      humMax = sp.getInt(_kHumMaxKey) ?? humMax;
      humSustainedMin = sp.getInt(_kHumSustainedKey) ?? humSustainedMin;
      pressureChangeHpa = sp.getInt(_kPressureChangeKey) ?? pressureChangeHpa;
      pressureSustainedMin =
          sp.getInt(_kPressureSustainedKey) ?? pressureSustainedMin;
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    setState(() => _saving = true);
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kMinKey, tempMin);
    await sp.setInt(_kMaxKey, tempMax);
    await sp.setInt(_kThresholdKey, tempThreshold);
    await sp.setInt(_kHumMinKey, humMin);
    await sp.setInt(_kHumMaxKey, humMax);
    await sp.setInt(_kHumSustainedKey, humSustainedMin);
    await sp.setInt(_kPressureChangeKey, pressureChangeHpa);
    await sp.setInt(_kPressureSustainedKey, pressureSustainedMin);
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

  // humidity helpers
  void incHumMin() => setState(() => humMin = (humMin + 1).clamp(0, humMax));
  void decHumMin() => setState(() => humMin = (humMin - 1).clamp(0, humMax));
  void incHumMax() => setState(() => humMax = (humMax + 1).clamp(humMin, 100));
  void decHumMax() => setState(() => humMax = (humMax - 1).clamp(humMin, 100));
  void incHumSust() =>
      setState(() => humSustainedMin = (humSustainedMin + 5).clamp(0, 1440));
  void decHumSust() =>
      setState(() => humSustainedMin = (humSustainedMin - 5).clamp(0, 1440));

  // pressure helpers
  void incPressureChange() =>
      setState(() => pressureChangeHpa = (pressureChangeHpa + 1).clamp(0, 100));
  void decPressureChange() =>
      setState(() => pressureChangeHpa = (pressureChangeHpa - 1).clamp(0, 100));
  void incPressureSust() => setState(
      () => pressureSustainedMin = (pressureSustainedMin + 10).clamp(0, 1440));
  void decPressureSust() => setState(
      () => pressureSustainedMin = (pressureSustainedMin - 10).clamp(0, 1440));

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
                  const SizedBox(height: 12),
                  const SectionTitle('Humidité'),
                  const SizedBox(height: 8),

                  _SettingCard(
                    icon: Icons.water_drop,
                    title: 'Plage d\'humidit\u00e9 (min / max)',
                    child: _MinMaxColumn(
                      label: 'Hum',
                      valueText: '$humMin% - $humMax%',
                      onDec: decHumMin,
                      onInc: incHumMax,
                      theme: theme,
                      boxWidth: 130,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingCard(
                    icon: Icons.timer,
                    title: 'Durée soutenue avant alerte (humidité)',
                    child: Row(
                      children: [
                        _SmallButton(icon: Icons.remove, onTap: decHumSust),
                        const SizedBox(width: 8),
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$humSustainedMin min'),
                        ),
                        const SizedBox(width: 8),
                        _SmallButton(icon: Icons.add, onTap: incHumSust),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // const SectionTitle('Pression'),
                  // const SizedBox(height: 8),

                  //         alignment: Alignment.center,
                  //         decoration: BoxDecoration(
                  //           color: theme.colorScheme.surfaceVariant,
                  //           borderRadius: BorderRadius.circular(8),
                  //         ),
                  //         child: Text('$pressureChangeHpa hPa'),
                  //       ),
                  //       const SizedBox(width: 8),
                  //       _SmallButton(icon: Icons.add, onTap: incPressureChange),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 12),
                  // _SettingCard(
                  //   icon: Icons.timer,
                  //   title: 'Durée soutenue (pression)',
                  //   child: Row(
                  //     children: [
                  //       _SmallButton(
                  //           icon: Icons.remove, onTap: decPressureSust),
                  //       const SizedBox(width: 8),
                  //       Container(
                  //         width: 80,
                  //         padding: const EdgeInsets.symmetric(vertical: 8),
                  //         alignment: Alignment.center,
                  //         decoration: BoxDecoration(
                  //           color: theme.colorScheme.surfaceVariant,
                  //           borderRadius: BorderRadius.circular(8),
                  //         ),
                  //         child: Text('$pressureSustainedMin min'),
                  //       ),
                  //       const SizedBox(width: 8),
                  //       _SmallButton(icon: Icons.add, onTap: incPressureSust),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 12),

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
  final double? boxWidth;
  const _MinMaxColumn({
    required this.label,
    required this.valueText,
    required this.onDec,
    required this.onInc,
    required this.theme,
    this.boxWidth,
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
              width: boxWidth ?? 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                valueText,
                textAlign: TextAlign.center,
              ),
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

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      );
}
