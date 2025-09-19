
import 'dart:convert';
import 'package:abd_petcare/core/services/auth_service.dart';
import 'package:abd_petcare/models/notification_prefs.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

  /// Fetches the latest sensor data for a given catId from the backend.
  /// Returns the decoded data map or null on error.
  Future<Map<String, dynamic>?> fetchLatestSensorData(String catId) async {
    try {
      final resp = await ApiClient.instance.get(
        '/sensors/latest/$catId',
        headers: AuthService.instance.authHeader,
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        if (data is Map && data['data'] is Map<String, dynamic>) {
          return data['data'] as Map<String, dynamic>;
        }
      } else {
        print('Erreur API /sensors/latest/$catId: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      print('Erreur réseau /sensors/latest/$catId: $e');
    }
    return null;
  }

class RealApiService {
  RealApiService._();
  static final RealApiService instance = RealApiService._();

  // TODO: passer le catId depuis l'état utilisateur (provider/riverpod)
  String defaultCatId = '123e4567-e89b-12d3-a456-426614174000';

  Future<bool> login(String identifier, String password) async {
    final body = {'identifier': identifier, 'password': password};
    final resp = await ApiClient.instance.post('/auth/login', body);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final token =
          data['accessToken'] ?? data['token'] ?? data['access_token'];
      final refresh = data['refreshToken'] ?? data['refresh_token'];
      if (token != null) {
        await AuthService.instance.saveTokens(token, refresh);
        return true;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>?> getSensorStats(String catId,
      {int hours = 24}) async {
    final resp = await ApiClient.instance.get(
      '/sensors/stats/$catId?hours=$hours',
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<dynamic>> getCatAlerts(String catId) async {
    // 1) Chemin documenté dans README: /cats/{id}/alerts
    http.Response resp = await ApiClient.instance.get(
      '/cats/$catId/alerts',
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data['data'] != null)
        return data['data'] as List<dynamic>;
      if (data is List) return data;
    }
    // 2) Chemin utilisé par le script de test: /sensors/alerts/{catId}
    resp = await ApiClient.instance.get(
      '/sensors/alerts/$catId',
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data['data'] is List)
        return data['data'] as List<dynamic>;
      if (data is List) return data;
    }
    return <dynamic>[];
  }

  Future<bool> sendNotification(Map<String, dynamic> payload) async {
    final http.Response resp = await ApiClient.instance.post(
      '/communication/notifications',
      payload,
      headers: AuthService.instance.authHeader,
    );
    return resp.statusCode == 200 || resp.statusCode == 201;
  }

  // ----- Notifications (in-app feed) -----

  /// Récupère les notifications de l'utilisateur connecté
  /// Retourne une liste de maps (NotificationEntity-like)
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final http.Response resp = await ApiClient.instance.get(
      '/communication/notifications?limit=$limit&offset=$offset',
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  /// Marque une notification comme lue
  Future<bool> markNotificationRead(String notificationId) async {
    final http.Response resp = await ApiClient.instance.post(
      '/communication/notifications/$notificationId/read',
      const {},
      headers: AuthService.instance.authHeader,
    );
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  /// Marque une alerte comme résolue
  Future<bool> resolveAlert(String alertId) async {
    // 1) Route générique
    http.Response resp = await ApiClient.instance.post(
      '/alerts/$alertId/resolve',
      const {},
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200 || resp.statusCode == 204) return true;
    // 2) Variante côté sensors
    resp = await ApiClient.instance.post(
      '/sensors/alerts/$alertId/resolve',
      const {},
      headers: AuthService.instance.authHeader,
    );
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  // ----- Préférences & Seuils (sync avec le backend) -----

  /// Sauvegarde des préférences de notifications globales (par catégories/canal)
  /// Essaie plusieurs endpoints possibles pour tolérer les variantes de gateway.
  Future<bool> saveNotificationPrefs(NotificationPrefs prefs) async {
    final body = prefs.toJson();
    // 1) Endpoint communication dédié
    http.Response resp = await ApiClient.instance.post(
      '/communication/notification-prefs',
      body,
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204) return true;
    // 2) Endpoint côté user
    resp = await ApiClient.instance.post(
      '/users/me/notification-prefs',
      body,
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204) return true;
    // 3) Endpoint générique
    resp = await ApiClient.instance.post(
      '/notification-prefs',
      body,
      headers: AuthService.instance.authHeader,
    );
    return resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204;
  }

  /// Sauvegarde des réglages Activité (fenêtres, seuils, on/off)
  Future<bool> saveActivitySettings(Map<String, dynamic> settings,
      {String? catId}) async {
    final String cid = catId ?? defaultCatId;
    http.Response resp = await ApiClient.instance.post(
      '/users/me/settings/activity',
      settings,
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204) return true;
    resp = await ApiClient.instance.post(
      '/cats/$cid/settings/activity',
      settings,
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204) return true;
    resp = await ApiClient.instance.post(
      '/settings/activity',
      settings,
      headers: AuthService.instance.authHeader,
    );
    return resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204;
  }

  /// Sauvegarde des réglages Environnement (temp/hum/…)
  Future<bool> saveEnvironmentSettings(Map<String, dynamic> settings,
      {String? catId}) async {
    final String cid = catId ?? defaultCatId;
    http.Response resp = await ApiClient.instance.post(
      '/users/me/settings/environment',
      settings,
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204) return true;
    resp = await ApiClient.instance.post(
      '/cats/$cid/settings/environment',
      settings,
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204) return true;
    resp = await ApiClient.instance.post(
      '/settings/environment',
      settings,
      headers: AuthService.instance.authHeader,
    );
    return resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204;
  }

  /// Sauvegarde des réglages Litière
  Future<bool> saveLitterSettings(Map<String, dynamic> settings,
      {String? catId}) async {
    final String cid = catId ?? defaultCatId;
    http.Response resp = await ApiClient.instance.post(
      '/users/me/settings/litter',
      settings,
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204) return true;
    resp = await ApiClient.instance.post(
      '/cats/$cid/settings/litter',
      settings,
      headers: AuthService.instance.authHeader,
    );
    if (resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204) return true;
    resp = await ApiClient.instance.post(
      '/settings/litter',
      settings,
      headers: AuthService.instance.authHeader,
    );
    return resp.statusCode == 200 ||
        resp.statusCode == 201 ||
        resp.statusCode == 204;
  }

  // ----- Compat Dashboard (même API que MockApiService) -----

  /// Transforme les stats backend en métriques attendues par le Dashboard
  /// { temperature: double, humidity: int, litterHumidity: int, lastSeen: String }
  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      final http.Response resp = await ApiClient.instance.get(
        '/sensors/stats/$defaultCatId?hours=24',
        headers: AuthService.instance.authHeader,
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final Map<String, dynamic> stats = decoded is Map<String, dynamic>
            ? (decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded)
            : <String, dynamic>{};

        final tempAvg =
            (stats['temperature'] is Map && stats['temperature']['avg'] is num)
                ? (stats['temperature']['avg'] as num).toDouble()
                : 0.0;
        final humAvg =
            (stats['humidity'] is Map && stats['humidity']['avg'] is num)
                ? (stats['humidity']['avg'] as num).toInt()
                : 0;

        return <String, dynamic>{
          'temperature': tempAvg,
          'humidity': humAvg,
          // Non fourni par /sensors/stats – on met 0 par défaut tant que la route dédiée n'est pas branchée
          'litterHumidity': 0,
          // A défaut d'une dernière mesure, utiliser maintenant
          'lastSeen': DateTime.now().toIso8601String(),
        };
      }
    } catch (_) {}

    return <String, dynamic>{
      'temperature': 0.0,
      'humidity': 0,
      'litterHumidity': 0,
      'lastSeen': '',
    };
  }

  /// Mappe les alertes backend vers { type, level, message }
  Future<List<Map<String, dynamic>>> fetchAlerts() async {
    try {
      final raw = await getCatAlerts(defaultCatId);
      return raw.map<Map<String, dynamic>>((e) {
        final m = (e as Map).cast<String, dynamic>();
        return <String, dynamic>{
          'type': m['type'] ?? 'generic',
          'level': m['severity'] ?? m['level'] ?? 'info',
          'message': m['message'] ?? '-',
        };
      }).toList(growable: false);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  /// Récupère les données liées à la litière pour la page dédiée.
  /// Retour standardisé:
  /// {
  ///   dailyUsage: int,            // nombre d'utilisations aujourd'hui
  ///   cleanliness: int,           // propreté en pourcentage 0-100
  ///   events: List<String>,       // heures (HH:mm) des derniers passages
  ///   anomalies: List<String>,    // libellés d'anomalies détectées
  /// }
  Future<Map<String, dynamic>> fetchLitterData({String? catId}) async {
    final String cid = catId ?? defaultCatId;
    final headers = AuthService.instance.authHeader;

    Future<Map<String, dynamic>?> tryGet(String path) async {
      final http.Response resp =
          await ApiClient.instance.get(path, headers: headers);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['data'] is Map<String, dynamic>
              ? (decoded['data'] as Map<String, dynamic>)
              : decoded;
        }
      }
      return null;
    }

    Map<String, dynamic>? raw;

    raw = await tryGet('/litter/stats/$cid');
    raw ??= await tryGet('/cats/$cid/litter/stats');
    raw ??= await tryGet('/sensors/litter/stats/$cid');
    raw ??= await tryGet('/cats/$cid/litter');

    int daily = 0;
    int cleanliness = 0;
    double? litterHumidityPct; // 0..100
    List<String> events = <String>[];
    List<String> anomalies = <String>[];

    Map<String, dynamic> toReturn() => <String, dynamic>{
          'dailyUsage': daily,
          'cleanliness': cleanliness.clamp(0, 100),
          'events': events,
          'anomalies': anomalies,
        };

    if (raw == null) return toReturn();

    try {
      // Compteurs
      final usageCandidates = [
        raw['dailyUsage'],
        raw['usageToday'],
        raw['todayCount'],
        raw['usage_count'],
      ];
      for (final c in usageCandidates) {
        if (c is num) {
          daily = c.toInt();
          break;
        }
      }

      // Humidité de la litière (prioritaire pour calculer la propreté)
      final humCandidates = [
        raw['litterHumidity'],
        raw['litter_humidity'],
        raw['humidity_litter'],
        raw['litter'] is Map ? (raw['litter'] as Map)['humidity'] : null,
      ];
      for (final h in humCandidates) {
        if (h is num) {
          litterHumidityPct = h.toDouble();
          break;
        }
      }
      // Événements (passages)
      final ev = raw['events'] ?? raw['visits'] ?? raw['activity'];
      if (ev is List) {
        events = ev
            .map((e) {
              if (e is String) return e; // supposé ISO ou HH:mm
              if (e is Map) {
                final m = e.cast<String, dynamic>();
                return m['time'] ?? m['timestamp'] ?? m['at'];
              }
              return null;
            })
            .whereType<String>()
            .map((s) {
              try {
                final dt = DateTime.tryParse(s);
                if (dt != null) {
                  final h = dt.hour.toString().padLeft(2, '0');
                  final m = dt.minute.toString().padLeft(2, '0');
                  return '$h:$m';
                }
              } catch (_) {}
              return s; // déjà formaté
            })
            .toList(growable: false);
      }

      // anomalies éventuelles
      final an = raw['anomalies'] ?? raw['alerts'] ?? raw['warnings'];
      if (an is List) {
        anomalies = an
            .map((e) {
              if (e is String) return e;
              if (e is Map) {
                final m = e.cast<String, dynamic>();
                return m['message'] ?? m['label'] ?? m['type'];
              }
              return null;
            })
            .whereType<String>()
            .toList(growable: false);
      }

      if (litterHumidityPct == null) {
        try {
          // tester variante coté back end
          final http.Response typedResp = await ApiClient.instance.get(
            '/sensors/stats/$cid?hours=24&type=litter',
            headers: headers,
          );
          if (typedResp.statusCode == 200) {
            final typed = jsonDecode(typedResp.body);
            if (typed is Map<String, dynamic>) {
              final h = typed['humidity'];
              if (h is Map && h['avg'] is num) {
                litterHumidityPct = (h['avg'] as num).toDouble();
              }
            }
          }

          // 2) Fallback: stats génériques (non filtrées)
          final stats = await getSensorStats(cid, hours: 24);
          if (stats != null) {
            final data = stats['data'] is Map<String, dynamic>
                ? stats['data'] as Map<String, dynamic>
                : stats;
            final candidates = [
              data['litterHumidity'],
              data['litter_humidity'],
              data['humidity_litter'],
              data['litter'] is Map
                  ? (data['litter'] as Map)['humidity']
                  : null,
              data['litterHumidity'] is Map
                  ? (data['litterHumidity']['avg'] ??
                      data['litterHumidity']['value'])
                  : null,
              data['humidity'] is Map ? data['humidity']['avg'] : null,
            ];
            for (final h in candidates) {
              if (h is num) {
                litterHumidityPct = h.toDouble();
                break;
              }
            }
          }
        } catch (_) {}
      }

      // normalisation+ calcul propreté = 100 - humidité
      if (litterHumidityPct != null) {
        double h = litterHumidityPct;
        if (h >= 0 && h <= 1) h *= 100; // ratio -> %
        h = h.clamp(0, 100);
        cleanliness = (100 - h).round();
      }
    } catch (_) {
      // Renvoie ce qui a pu être extrait
    }

    return toReturn();
  }
}
