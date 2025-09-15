// lib/screens/environnement/environment_settings_page.dart
import 'package:abd_petcare/core/services/api_client.dart';
import 'package:flutter/material.dart';



import '../../core/services/auth_service.dart';

class EnvironmentSettingsPage extends StatefulWidget {
  const EnvironmentSettingsPage({super.key});

  @override
  State<EnvironmentSettingsPage> createState() =>
      _EnvironmentSettingsPageState();
}

class _EnvironmentSettingsPageState extends State<EnvironmentSettingsPage> {

  int tempMin = 0;
  int tempMax = 0;
  int humMin = 0;
  int humMax = 0;
  bool notifications = true;
  bool _loading = true;
  String? _catId;
  Map<String, dynamic>? _catThresholds;

  @override
  void initState() {
    super.initState();
    _fetchEnvThresholds();
  }

  Future<void> _fetchEnvThresholds() async {
    setState(() => _loading = true);
    try {
      final userResp = await AuthService.instance.fetchUserWithCats();
      final cats = userResp?['extras']?['cats'] as List?;
      if (cats == null || cats.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final firstCat = cats.first;
      final thresholds = firstCat['activityThresholds'] as Map<String, dynamic>?;
      final env = thresholds?['environment'] as Map<String, dynamic>?;
      setState(() {
        tempMin = env?['temperatureMin'] ?? 0;
        tempMax = env?['temperatureMax'] ?? 0;
  // tempThreshold supprimé
        humMin = env?['humidityMin'] ?? 0;
        humMax = env?['humidityMax'] ?? 0;
        _catId = firstCat['id'] as String?;
        _catThresholds = thresholds;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateEnvThresholds({int? newTempMin, int? newTempMax, int? newHumMin, int? newHumMax}) async {
    if (_catId == null || _catThresholds == null) return;
    final collar = Map<String, dynamic>.from(_catThresholds!['collar'] ?? {});
    final environment = Map<String, dynamic>.from(_catThresholds!['environment'] ?? {});
    final litter = Map<String, dynamic>.from(_catThresholds!['litter'] ?? {});
    if (newTempMin != null) environment['temperatureMin'] = newTempMin;
    if (newTempMax != null) environment['temperatureMax'] = newTempMax;
    if (newHumMin != null) environment['humidityMin'] = newHumMin;
    if (newHumMax != null) environment['humidityMax'] = newHumMax;
    if (litter['dailyUsageMin'] == null) litter['dailyUsageMin'] = 1;
    final body = {
      'collar': collar,
      'environment': environment,
      'litter': litter,
    };
    print('Updating thresholds with body: $body');
    await ApiClient.instance.updateCatThresholds(_catId!, body, headers: AuthService.instance.authHeader);
    setState(() {
      _catThresholds = {
        'collar': collar,
        'environment': environment,
        'litter': litter,
      };
    });
  }

  // Suppression de la sauvegarde locale, tout est initialisé via l'API

  void incMin() {
    final newValue = (tempMin + 1).clamp(-50, tempMax);
    setState(() => tempMin = newValue);
    _updateEnvThresholds(newTempMin: newValue);
  }
  void decMin() {
    final newValue = (tempMin - 1).clamp(-50, tempMax);
    setState(() => tempMin = newValue);
    _updateEnvThresholds(newTempMin: newValue);
  }
  void incMax() {
    final newValue = (tempMax + 1).clamp(tempMin, 100);
    setState(() => tempMax = newValue);
    _updateEnvThresholds(newTempMax: newValue);
  }
  void decMax() {
    final newValue = (tempMax - 1).clamp(tempMin, 100);
    setState(() => tempMax = newValue);
    _updateEnvThresholds(newTempMax: newValue);
  }
  // incThresh/decThresh supprimés
  void incHumMin() {
    final newValue = (humMin + 1).clamp(0, humMax);
    setState(() => humMin = newValue);
    _updateEnvThresholds(newHumMin: newValue);
  }
  void decHumMin() {
    final newValue = (humMin - 1).clamp(0, humMax);
    setState(() => humMin = newValue);
    _updateEnvThresholds(newHumMin: newValue);
  }
  void incHumMax() {
    final newValue = (humMax + 1).clamp(humMin, 100);
    setState(() => humMax = newValue);
    _updateEnvThresholds(newHumMax: newValue);
  }
  void decHumMax() {
    final newValue = (humMax - 1).clamp(humMin, 100);
    setState(() => humMax = newValue);
    _updateEnvThresholds(newHumMax: newValue);
  }

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
                    title: 'Température maximum',
                    child: _MinMaxColumn(
                      label: 'Max',
                      valueText: '$tempMax°C',
                      onDec: decMax,
                      onInc: incMax,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SectionTitle('Humidité'),
                  const SizedBox(height: 8),

                  _SettingCard(
                    icon: Icons.water_drop,
                    title: 'Humidité minimum',
                    child: _MinMaxColumn(
                      label: 'Min',
                      valueText: '$humMin%',
                      onDec: decHumMin,
                      onInc: incHumMin,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingCard(
                    icon: Icons.water_drop_outlined,
                    title: 'Humidité maximum',
                    child: _MinMaxColumn(
                      label: 'Max',
                      valueText: '$humMax%',
                      onDec: decHumMax,
                      onInc: incHumMax,
                      theme: theme,
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
                  // Save button supprimé, tout est géré par l'API
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
