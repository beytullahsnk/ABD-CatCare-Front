// lib/screens/environnement/environment_settings_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/services/auth_state.dart';
import '../../models/ruuvi_tag.dart';

class EnvironmentSettingsPage extends StatefulWidget {
  const EnvironmentSettingsPage({super.key});

  @override
  State<EnvironmentSettingsPage> createState() => _EnvironmentSettingsPageState();
}

class _EnvironmentSettingsPageState extends State<EnvironmentSettingsPage> {
  int tempMin = 0;
  int tempMax = 0;
  int humMin = 0;
  int humMax = 0;
  bool notifications = true;
  bool _loading = true;
  String? _catId;
  String? _ruuviTagId;

  @override
  void initState() {
    super.initState();
    _fetchEnvThresholds();
  }

  Future<void> _fetchEnvThresholds() async {
    setState(() => _loading = true);
    try {
      // Récupérer l'ID du chat de l'utilisateur
      final userResponse = await http.get(
        Uri.parse('http://localhost:3000/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Erreur lors de la récupération des données utilisateur');
      }

      final userData = jsonDecode(userResponse.body);
      if (userData['state'] != true || userData['extras'] == null || 
          userData['extras']['cats'] == null || 
          (userData['extras']['cats'] as List).isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final firstCat = (userData['extras']['cats'] as List).first;
      _catId = firstCat['id'] as String?;

      // Récupérer les RuuviTags
      final ruuviTagsResponse = await http.get(
        Uri.parse('http://localhost:3000/api/ruuvitags'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
      );

      if (ruuviTagsResponse.statusCode != 200) {
        throw Exception('Erreur lors de la récupération des RuuviTags');
      }

      final ruuviTagsData = jsonDecode(ruuviTagsResponse.body);
      if (ruuviTagsData['state'] == true && ruuviTagsData['data'] != null) {
        final allTags = (ruuviTagsData['data'] as List)
            .map((tag) => RuuviTag.fromJson(tag))
            .toList();
        
        // Trouver le RuuviTag de type ENVIRONMENT pour ce chat
        final environmentTag = allTags.firstWhere(
          (tag) => tag.type == RuuviTagType.environment && 
                   tag.catIds != null && 
                   tag.catIds!.contains(_catId),
          orElse: () => throw Exception('Aucun capteur d\'environnement trouvé'),
        );

        _ruuviTagId = environmentTag.id;
        
        // Récupérer les seuils d'environnement
        final envThresholds = environmentTag.alertThresholds?['environment'] as Map<String, dynamic>?;
        
        setState(() {
          tempMin = envThresholds?['temperatureMin'] ?? 15;
          tempMax = envThresholds?['temperatureMax'] ?? 30;
          humMin = envThresholds?['humidityMin'] ?? 30;
          humMax = envThresholds?['humidityMax'] ?? 70;
          _loading = false;
        });
      } else {
        throw Exception('Aucun RuuviTag trouvé');
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateThresholds({
    int? newTempMin,
    int? newTempMax,
    int? newHumMin,
    int? newHumMax,
  }) async {
    if (_ruuviTagId == null) return;

    try {
      setState(() => _loading = true);

      // Récupérer les seuils actuels du RuuviTag
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/ruuvitags'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la récupération des seuils actuels');
      }

      final data = jsonDecode(response.body);
      final allTags = (data['data'] as List)
          .map((tag) => RuuviTag.fromJson(tag))
          .toList();
      
      final currentTag = allTags.firstWhere(
        (tag) => tag.id == _ruuviTagId,
      );

      // Mettre à jour les seuils d'environnement
      final updatedThresholds = Map<String, dynamic>.from(currentTag.alertThresholds ?? {});
      if (updatedThresholds['environment'] == null) {
        updatedThresholds['environment'] = {};
      }
      
      if (newTempMin != null) updatedThresholds['environment']['temperatureMin'] = newTempMin;
      if (newTempMax != null) updatedThresholds['environment']['temperatureMax'] = newTempMax;
      if (newHumMin != null) updatedThresholds['environment']['humidityMin'] = newHumMin;
      if (newHumMax != null) updatedThresholds['environment']['humidityMax'] = newHumMax;

      // Envoyer la mise à jour
      final updateResponse = await http.patch(
        Uri.parse('http://localhost:3000/api/ruuvitags/$_ruuviTagId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
        body: jsonEncode({
          'alertThresholds': updatedThresholds,
        }),
      );

      if (updateResponse.statusCode == 200) {
        setState(() {
          if (newTempMin != null) tempMin = newTempMin;
          if (newTempMax != null) tempMax = newTempMax;
          if (newHumMin != null) humMin = newHumMin;
          if (newHumMax != null) humMax = newHumMax;
          _loading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seuils mis à jour avec succès')),
          );
        }
      } else {
        throw Exception('Erreur lors de la mise à jour: ${updateResponse.statusCode}');
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // Suppression de la sauvegarde locale, tout est initialisé via l'API

  void incMin() {
    final newValue = (tempMin + 1).clamp(-50, tempMax);
    setState(() => tempMin = newValue);
    _updateThresholds(newTempMin: newValue);
  }
  void decMin() {
    final newValue = (tempMin - 1).clamp(-50, tempMax);
    setState(() => tempMin = newValue);
    _updateThresholds(newTempMin: newValue);
  }
  void incMax() {
    final newValue = (tempMax + 1).clamp(tempMin, 100);
    setState(() => tempMax = newValue);
    _updateThresholds(newTempMax: newValue);
  }
  void decMax() {
    final newValue = (tempMax - 1).clamp(tempMin, 100);
    setState(() => tempMax = newValue);
    _updateThresholds(newTempMax: newValue);
  }
  // incThresh/decThresh supprimés
  void incHumMin() {
    final newValue = (humMin + 1).clamp(0, humMax);
    setState(() => humMin = newValue);
    _updateThresholds(newHumMin: newValue);
  }
  void decHumMin() {
    final newValue = (humMin - 1).clamp(0, humMax);
    setState(() => humMin = newValue);
    _updateThresholds(newHumMin: newValue);
  }
  void incHumMax() {
    final newValue = (humMax + 1).clamp(humMin, 100);
    setState(() => humMax = newValue);
    _updateThresholds(newHumMax: newValue);
  }
  void decHumMax() {
    final newValue = (humMax - 1).clamp(humMin, 100);
    setState(() => humMax = newValue);
    _updateThresholds(newHumMax: newValue);
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
