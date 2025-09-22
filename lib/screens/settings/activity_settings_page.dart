import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/services/auth_state.dart';
import '../../models/ruuvi_tag.dart';

class ActivitySettingsPage extends StatefulWidget {
  const ActivitySettingsPage({super.key});

  @override
  State<ActivitySettingsPage> createState() => _ActivitySettingsPageState();
}

class _ActivitySettingsPageState extends State<ActivitySettingsPage> {
  String? _catId;
  String? _ruuviTagId;
  int inactivityHours = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivityThresholds();
  }

  Future<void> _fetchActivityThresholds() async {
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
        
        // Trouver le RuuviTag de type COLLAR pour ce chat
        final collarTag = allTags.firstWhere(
          (tag) => tag.type == RuuviTagType.collar && 
                   tag.catIds != null && 
                   tag.catIds!.contains(_catId),
          orElse: () => throw Exception('Aucun capteur de collier trouvé'),
        );

        _ruuviTagId = collarTag.id;
        
        // Récupérer les seuils de collier
        final collarThresholds = collarTag.alertThresholds?['collar'] as Map<String, dynamic>?;
        
        setState(() {
          inactivityHours = collarThresholds?['inactivityHours'] ?? 8;
          _loading = false;
        });
      } else {
        throw Exception('Aucun RuuviTag trouvé');
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateCollarThresholds({int? newInactivityHours}) async {
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

      // Mettre à jour les seuils de collier
      final updatedThresholds = Map<String, dynamic>.from(currentTag.alertThresholds ?? {});
      if (updatedThresholds['collar'] == null) {
        updatedThresholds['collar'] = {};
      }
      
      if (newInactivityHours != null) {
        updatedThresholds['collar']['inactivityHours'] = newInactivityHours;
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
          if (newInactivityHours != null) inactivityHours = newInactivityHours;
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

  void incInactivityHours() {
    final newValue = (inactivityHours + 1).clamp(1, 24);
    setState(() => inactivityHours = newValue);
    _updateCollarThresholds(newInactivityHours: newValue);
  }

  void decInactivityHours() {
    final newValue = (inactivityHours - 1).clamp(1, 24);
    setState(() => inactivityHours = newValue);
    _updateCollarThresholds(newInactivityHours: newValue);
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
            Text('Collier', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.timer,
              title: 'Heures d\'inactivité',
              child: Row(
                children: [
                  _SmallButton(icon: Icons.remove, onTap: decInactivityHours),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$inactivityHours h'),
                  ),
                  const SizedBox(width: 8),
                  _SmallButton(icon: Icons.add, onTap: incInactivityHours),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 20),
            // Plus de bouton enregistrer, tout est affiché depuis l'API
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
