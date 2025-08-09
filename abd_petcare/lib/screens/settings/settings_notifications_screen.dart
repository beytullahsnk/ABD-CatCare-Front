import 'package:flutter/material.dart';
import '../../core/services/mock_api_service.dart';
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
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Activité'),
                  value: _activity,
                  onChanged: (v) => setState(() => _activity = v),
                ),
                SwitchListTile(
                  title: const Text('Environnement'),
                  value: _environment,
                  onChanged: (v) => setState(() => _environment = v),
                ),
                SwitchListTile(
                  title: const Text('Litière'),
                  value: _litter,
                  onChanged: (v) => setState(() => _litter = v),
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
                ElevatedButton(
                  onPressed: () async {
                    final prefs = NotificationPrefs(
                      activity: _activity,
                      environment: _environment,
                      litter: _litter,
                      channel: _channel,
                    );
                    await _api.saveNotificationPrefs(prefs);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Préférences enregistrées')),
                    );
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
    );
  }
}
