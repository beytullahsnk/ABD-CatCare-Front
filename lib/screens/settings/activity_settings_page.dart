import 'package:abd_petcare/core/services/api_client.dart';

import 'package:flutter/material.dart';
import 'package:abd_petcare/core/services/auth_service.dart';

// Activity settings page: two sections (Activité, Inactivité). No cooldown.
class ActivitySettingsPage extends StatefulWidget {
  const ActivitySettingsPage({super.key});

  @override
  State<ActivitySettingsPage> createState() => _ActivitySettingsPageState();
}


// Activity settings page: two sections (Activité, Inactivité). No cooldown.

class _ActivitySettingsPageState extends State<ActivitySettingsPage> {

  String? _catId;
  Map<String, dynamic>? _catThresholds;
  double movementThreshold = 0;
  double lowActivityThreshold = 0;
  double highActivityThreshold = 0;
  int inactivityHours = 0;
  bool _loading = true;

  Future<void> _updateCollarThresholds({
    int? newInactivityHours,
    double? newMovementThreshold,
    double? newLowActivityThreshold,
    double? newHighActivityThreshold,
  }) async {
    if (_catId == null || _catThresholds == null) return;
    final collar = Map<String, dynamic>.from(_catThresholds!['collar'] ?? {});
    final environment = Map<String, dynamic>.from(_catThresholds!['environment'] ?? {});
    final litter = Map<String, dynamic>.from(_catThresholds!['litter'] ?? {});
    if (newInactivityHours != null) collar['inactivityHours'] = newInactivityHours;
    if (newMovementThreshold != null) collar['movementThreshold'] = newMovementThreshold;
    if (newLowActivityThreshold != null) collar['lowActivityThreshold'] = newLowActivityThreshold;
    if (newHighActivityThreshold != null) collar['highActivityThreshold'] = newHighActivityThreshold;
    if (litter['dailyUsageMin'] == null) litter['dailyUsageMin'] = 1;
    final body = {
      'collar': collar,
      'environment': environment,
      'litter': litter,
    };
    await ApiClient.instance.updateCatThresholds(_catId!, body, headers: AuthService.instance.authHeader);
    setState(() {
      _catThresholds = {
        'collar': collar,
        'environment': environment,
        'litter': litter,
      };
      if (newInactivityHours != null) inactivityHours = newInactivityHours;
      if (newMovementThreshold != null) movementThreshold = newMovementThreshold;
      if (newLowActivityThreshold != null) lowActivityThreshold = newLowActivityThreshold;
      if (newHighActivityThreshold != null) highActivityThreshold = newHighActivityThreshold;
    });
  }

  void incInactivity() => _updateCollarThresholds(newInactivityHours: inactivityHours + 1);
  void decInactivity() => _updateCollarThresholds(newInactivityHours: (inactivityHours - 1).clamp(0, 999));
  void incMovement() => _updateCollarThresholds(newMovementThreshold: double.parse((movementThreshold + 0.01).toStringAsFixed(2)));
  void decMovement() => _updateCollarThresholds(newMovementThreshold: double.parse((movementThreshold - 0.01).clamp(0, 999).toStringAsFixed(2)));
  void incLowActivity() => _updateCollarThresholds(newLowActivityThreshold: double.parse((lowActivityThreshold + 0.01).toStringAsFixed(2)));
  void decLowActivity() => _updateCollarThresholds(newLowActivityThreshold: double.parse((lowActivityThreshold - 0.01).clamp(0, 999).toStringAsFixed(2)));
  void incHighActivity() => _updateCollarThresholds(newHighActivityThreshold: double.parse((highActivityThreshold + 0.01).toStringAsFixed(2)));
  void decHighActivity() => _updateCollarThresholds(newHighActivityThreshold: double.parse((highActivityThreshold - 0.01).clamp(0, 999).toStringAsFixed(2)));

  @override
  void initState() {
    super.initState();
    _fetchCollarThresholds();
  }

  Future<void> _fetchCollarThresholds() async {
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
      final collar = thresholds?['collar'] ?? {};
      setState(() {
        _catId = firstCat['id'] as String?;
        _catThresholds = thresholds;
        inactivityHours = collar['inactivityHours'] ?? 0;
        movementThreshold = (collar['movementThreshold'] ?? 0).toDouble();
        lowActivityThreshold = (collar['lowActivityThreshold'] ?? 0).toDouble();
        highActivityThreshold = (collar['highActivityThreshold'] ?? 0).toDouble();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
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
                  _SmallButton(icon: Icons.remove, onTap: decInactivity),
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
                  _SmallButton(icon: Icons.add, onTap: incInactivity),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.directions_run,
              title: 'Seuil de mouvement',
              child: Row(
                children: [
                  _SmallButton(icon: Icons.remove, onTap: decMovement),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(movementThreshold.toString()),
                  ),
                  const SizedBox(width: 8),
                  _SmallButton(icon: Icons.add, onTap: incMovement),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.trending_down,
              title: 'Seuil activité basse',
              child: Row(
                children: [
                  _SmallButton(icon: Icons.remove, onTap: decLowActivity),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(lowActivityThreshold.toString()),
                  ),
                  const SizedBox(width: 8),
                  _SmallButton(icon: Icons.add, onTap: incLowActivity),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.trending_up,
              title: 'Seuil activité haute',
              child: Row(
                children: [
                  _SmallButton(icon: Icons.remove, onTap: decHighActivity),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(highActivityThreshold.toString()),
                  ),
                  const SizedBox(width: 8),
                  _SmallButton(icon: Icons.add, onTap: incHighActivity),
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
