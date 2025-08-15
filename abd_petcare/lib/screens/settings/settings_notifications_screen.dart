import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/mock_api_service.dart';
import '../../core/services/auth_state.dart';
import '../../models/notification_prefs.dart';

class SettingsNotificationsScreen extends StatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  State<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends State<SettingsNotificationsScreen> {
  final MockApiService _api = MockApiService();
  bool _loading = true;
  bool _saving = false;

  bool _activity = true;
  bool _environment = true;
  bool _litter = true;
  String _channel = 'both';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await _api.loadNotificationPrefs();
    if (!mounted) return;
    if (prefs == null) {
      setState(() {
        _activity = true;
        _environment = true;
        _litter = true;
        _channel = 'both';
        _loading = false;
      });
      return;
    }
    setState(() {
      _activity = prefs.activity;
      _environment = prefs.environment;
      _litter = prefs.litter;
      _channel = prefs.channel;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Text('Seuils',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _SettingRow(
                    icon: Icons.favorite_border,
                    title: 'Activité',
                    subtitle: "Seuil d’activité"),
                _SettingRow(
                    icon: Icons.device_thermostat,
                    title: 'Litière',
                    subtitle: 'Humidité et récurrence'),
                _SettingRow(
                    icon: Icons.tune,
                    title: 'Environnement',
                    subtitle: 'Température et humidité'),
                const SizedBox(height: 16),
                Text('Notifications',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _SwitchRow(
                  icon: Icons.notifications_none,
                  title: 'Notifications pu…',
                  value: _activity,
                  onChanged: (v) => setState(() => _activity = v),
                ),
                _SwitchRow(
                  icon: Icons.mail_outline,
                  title: 'Notifications par e‑mail',
                  value: _environment,
                  onChanged: (v) => setState(() => _environment = v),
                ),
                const SizedBox(height: 16),
                const Text('Canal de notification'),
                RadioListTile<String>(
                  title: const Text('Push'),
                  value: 'push',
                  groupValue: _channel,
                  onChanged: (v) => setState(() => _channel = v ?? 'push'),
                ),
                RadioListTile<String>(
                  title: const Text('Email'),
                  value: 'email',
                  groupValue: _channel,
                  onChanged: (v) => setState(() => _channel = v ?? 'email'),
                ),
                RadioListTile<String>(
                  title: const Text('Les deux'),
                  value: 'both',
                  groupValue: _channel,
                  onChanged: (v) => setState(() => _channel = v ?? 'both'),
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              final prefs = NotificationPrefs(
                                activity: _activity,
                                environment: _environment,
                                litter: _litter,
                                channel: _channel,
                              );
                              await _api.saveNotificationPrefs(prefs);
                              if (!mounted) return;
                              final cs = Theme.of(context).colorScheme;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: cs.secondary,
                                  content:
                                      const Text('Préférences enregistrées'),
                                ),
                              );
                              setState(() => _saving = false);
                            },
                      child: const Text('Enregistrer'),
                    ),
                    if (_saving)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Déconnexion rapide accessible depuis les paramètres
                TextButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final cs = Theme.of(context).colorScheme;
                    await AuthState.instance.setLoggedIn(false);
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: cs.secondary,
                        content: const Text('Déconnecté'),
                      ),
                    );
                    if (!mounted) return;
                    // Utilise go_router (MaterialApp.router)
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                ),
              ],
            ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SettingRow(
      {required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: cs.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 112,
            height: 64,
            decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow(
      {required this.icon,
      required this.title,
      required this.value,
      required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, color: cs.onSecondaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(title, style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
