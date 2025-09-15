
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_client.dart';

class LitterPageSettings extends StatefulWidget {
  const LitterPageSettings({Key? key}) : super(key: key);

  @override
  State<LitterPageSettings> createState() => _LitterPageState();
}

class _LitterPageState extends State<LitterPageSettings> {
  int? humidity;
  int? passages;
  bool notifications = true;
  bool loading = true;
  String? error;
  Map<String, dynamic>? _catThresholds;
  String? _catId;

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
      final userResp = await AuthService.instance.fetchUserWithCats();
      if (userResp == null || userResp['extras'] == null || userResp['extras']['cats'] == null || (userResp['extras']['cats'] as List).isEmpty) {
        setState(() {
          error = "Aucun chat trouvé.";
          loading = false;
        });
        return;
      }
      final firstCat = (userResp['extras']['cats'] as List).first;
      final thresholds = firstCat['activityThresholds'] as Map<String, dynamic>?;
      final litter = thresholds?['litter'] as Map<String, dynamic>?;
      setState(() {
        humidity = litter?['humidityMax'] ?? 40;
        passages = litter?['dailyUsageMax'] ?? 3;
        _catThresholds = thresholds;
        _catId = firstCat['id'] as String?;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Erreur lors du chargement.";
        loading = false;
      });
    }
  }

  Future<void> _updateThresholds({int? newHumidity, int? newPassages}) async {
    if (_catId == null || _catThresholds == null) return;
    final collar = Map<String, dynamic>.from(_catThresholds!['collar'] ?? {});
    final environment = Map<String, dynamic>.from(_catThresholds!['environment'] ?? {});
    final litter = Map<String, dynamic>.from(_catThresholds!['litter'] ?? {});
    if (newHumidity != null) litter['humidityMax'] = newHumidity;
    if (newPassages != null) litter['dailyUsageMax'] = newPassages;
    // Correction: dailyUsageMin ne doit jamais être null
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
    });
  }

  void incHumidity() {
    final newValue = ((humidity ?? 0) + 1).clamp(0, 100);
    setState(() => humidity = newValue);
    _updateThresholds(newHumidity: newValue);
  }
  void decHumidity() {
    final newValue = ((humidity ?? 0) - 1).clamp(0, 100);
    setState(() => humidity = newValue);
    _updateThresholds(newHumidity: newValue);
  }
  void incPassages() {
    final newValue = ((passages ?? 0) + 1);
    setState(() => passages = newValue);
    _updateThresholds(newPassages: newValue);
  }
  void decPassages() {
    final newValue = ((passages ?? 0) - 1).clamp(0, 999);
    setState(() => passages = newValue);
    _updateThresholds(newPassages: newValue);
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
                              child: Text(humidity != null ? '$humidity%' : '-'),
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
                              child: Text(passages != null ? '$passages' : '-'),
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
