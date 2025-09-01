import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_prefs.dart';
import '../../models/user.dart';

class MockApiService {
  static const String notificationPrefsKey = 'notification_prefs';

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: autoriser des mdp plus courts pour faciliter les tests
    return email.contains('@') && password.isNotEmpty;
  }

  Future<bool> register(User user) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return user.email.contains('@');
  }

  Future<Map<String, dynamic>> fetchDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return <String, dynamic>{
      'temperature': 37.8,
      'humidity': 41,
      'activityScore': 72,
      'litterHumidity': 28,
      'lastSeen': DateTime.now().toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> fetchAlerts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return <Map<String, dynamic>>[
      {'type': 'health', 'level': 'info', 'message': 'Tout va bien.'},
      {
        'type': 'litter',
        'level': 'warning',
        'message': 'Humidité de la litière un peu élevée.'
      },
    ];
  }

  // ----- Litter (mock) -----
  Future<Map<String, dynamic>> fetchLitterData() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Réutilise la donnée mock du tableau de bord si disponible
    final dashboard = await fetchDashboardData();
    final double litterHumidity = (dashboard['litterHumidity'] is num)
        ? (dashboard['litterHumidity'] as num).toDouble()
        : 35.0;
    final int cleanliness = (100 - litterHumidity).round().clamp(0, 100);

    return <String, dynamic>{
      'dailyUsage': 3,
      'cleanliness': cleanliness,
      'events': <String>['10:15', '07:30', '05:00'],
      'anomalies': litterHumidity > 60
          ? <String>['Litière humide: ${litterHumidity.toStringAsFixed(0)}%']
          : <String>[],
    };
  }

  // ----- Notifications feed (mock) -----
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return <Map<String, dynamic>>[
      {
        'id': 'n1',
        'title': 'Activité accrue détectée',
        'message': 'Votre chat bouge beaucoup.',
        'category': 'activity',
        'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'readAt': null,
      },
      {
        'id': 'n2',
        'title': 'Litière: action recommandée',
        'message': 'Humidité de la litière élevée.',
        'category': 'litter',
        'createdAt':
            now.subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
        'readAt': null,
      },
      {
        'id': 'n3',
        'title': 'Changement de température',
        'message': 'Température ambiante en hausse.',
        'category': 'environment',
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'readAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
  }

  Future<bool> markNotificationRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  // Sauvegarde des préférences notifications
  Future<void> saveNotificationPrefs(NotificationPrefs prefs) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString(notificationPrefsKey, jsonEncode(prefs.toJson()));
  }

  // Chargement des préférences notifications
  Future<NotificationPrefs?> loadNotificationPrefs() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final String? raw = sp.getString(notificationPrefsKey);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPrefs.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
