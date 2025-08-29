import 'dart:convert';
import 'package:abd_petcare/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

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
}
