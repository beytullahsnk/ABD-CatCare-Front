
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/services/auth_state.dart';
import '../../models/ruuvi_tag.dart';

class LitterPageSettings extends StatefulWidget {
  const LitterPageSettings({Key? key}) : super(key: key);

  @override
  State<LitterPageSettings> createState() => _LitterPageState();
}

class _LitterPageState extends State<LitterPageSettings> {
  int? dailyUsageMax;
  bool notifications = true;
  bool loading = true;
  String? error;
  String? _catId;
  String? _ruuviTagId;

  @override
  void initState() {
    super.initState();
    _fetchLitterThresholds();
  }

  Future<void> _fetchLitterThresholds() async {
    setState(() {
      loading = true;
      error = null;
    });
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
        setState(() {
          error = "Aucun chat trouvé.";
          loading = false;
        });
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
        
        // Trouver le RuuviTag de type LITTER pour ce chat
        final litterTag = allTags.firstWhere(
          (tag) => tag.type == RuuviTagType.litter && 
                   tag.catIds != null && 
                   tag.catIds!.contains(_catId),
          orElse: () => throw Exception('Aucun capteur de litière trouvé'),
        );

        _ruuviTagId = litterTag.id;
        
        // Récupérer les seuils de litière
        final litterThresholds = litterTag.alertThresholds?['litter'] as Map<String, dynamic>?;
        
        setState(() {
          dailyUsageMax = litterThresholds?['dailyUsageMax'] ?? 10;
          loading = false;
        });
      } else {
        throw Exception('Aucun RuuviTag trouvé');
      }
    } catch (e) {
      setState(() {
        error = "Erreur lors du chargement: $e";
        loading = false;
      });
    }
  }

  Future<void> _updateThresholds({int? newDailyUsageMax}) async {
    if (_ruuviTagId == null) return;

    try {
      setState(() {
        loading = true;
        error = null;
      });

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

      // Mettre à jour les seuils de litière
      final updatedThresholds = Map<String, dynamic>.from(currentTag.alertThresholds ?? {});
      if (updatedThresholds['litter'] == null) {
        updatedThresholds['litter'] = {};
      }
      
      if (newDailyUsageMax != null) {
        updatedThresholds['litter']['dailyUsageMax'] = newDailyUsageMax;
      }

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
          if (newDailyUsageMax != null) dailyUsageMax = newDailyUsageMax;
          loading = false;
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
      setState(() {
        error = "Erreur lors de la mise à jour: $e";
        loading = false;
      });
    }
  }

  void incDailyUsageMax() {
    final newValue = ((dailyUsageMax ?? 0) + 1).clamp(0, 100);
    setState(() => dailyUsageMax = newValue);
    _updateThresholds(newDailyUsageMax: newValue);
  }
  void decDailyUsageMax() {
    final newValue = ((dailyUsageMax ?? 0) - 1).clamp(0, 100);
    setState(() => dailyUsageMax = newValue);
    _updateThresholds(newDailyUsageMax: newValue);
  }

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
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingCard(
                        icon: Icons.directions_walk,
                        title: "Seuil de passages",
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _SmallButton(icon: Icons.remove, onTap: decDailyUsageMax),
                            const SizedBox(width: 8),
                            Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(dailyUsageMax != null ? '$dailyUsageMax' : '-'),
                            ),
                            const SizedBox(width: 8),
                            _SmallButton(icon: Icons.add, onTap: incDailyUsageMax),
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
