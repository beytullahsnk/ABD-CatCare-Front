import 'dart:convert';
import 'package:abd_petcare/core/services/auth_service.dart';
import 'package:abd_petcare/core/services/auth_state.dart';
import 'package:abd_petcare/models/notification_prefs.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

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

  Future<String?> getUserCatId() async {
    try {
      final token = AuthState.instance.accessToken;
      if (token == null || token.isEmpty) {
        print('Token d\'authentification manquant');
        return null;
      }

      final resp = await ApiClient.instance.get(
        '/users/me',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['state'] == true && data['extras'] != null) {
          final cats = data['extras']['cats'] as List<dynamic>?;
          if (cats != null && cats.isNotEmpty) {
            return cats[0]['id'] as String;
          }
        }
      } else if (resp.statusCode == 401) {
        print('Token expiré, déconnexion nécessaire');
      }
    } catch (e) {
      print('Erreur lors de la récupération du chat utilisateur: $e');
    }
    return null;
  }

  // Méthode pour récupérer les données du dashboard avec le bon chat
  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      // Récupérer l'ID du chat de l'utilisateur connecté
      final catId = await getUserCatId(); // Utiliser la méthode publique
      if (catId == null) {
        return <String, dynamic>{
          'temperature': 0.0,
          'humidity': 0,
          'litterHumidity': 0,
          'lastSeen': '', // Chaîne vide au lieu de DateTime.now()
        };
      }

      final token = AuthState.instance.accessToken;
      if (token == null || token.isEmpty) {
        return <String, dynamic>{
          'temperature': 0.0,
          'humidity': 0,
          'litterHumidity': 0,
          'lastSeen': '', // Chaîne vide au lieu de DateTime.now()
        };
      }

      // Récupérer les données des capteurs pour ce chat
      final resp = await ApiClient.instance.get(
        '/ruuvitags/data?catIds=$catId',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['state'] == true && data['data'] != null) {
          final sensorData = data['data'] as List<dynamic>;
          
          double temperature = 0.0;
          int humidity = 0;
          int litterHumidity = 0;
          String lastSeen = DateTime.now().toIso8601String();
          
          // Parcourir les données pour extraire les valeurs par type de capteur
          for (var item in sensorData) {
            if (item['catId'] == catId) {
              switch (item['type']) {
                case 'ENVIRONMENT':
                  if (item['temperature'] != null) {
                    temperature = (item['temperature'] as num).toDouble();
                  }
                  if (item['humidity'] != null) {
                    humidity = (item['humidity'] as num).toInt();
                  }
                  break;
                case 'LITTER':
                  if (item['humidity'] != null) {
                    litterHumidity = (item['humidity'] as num).toInt();
                  }
                  break;
              }
              
              // Garder la timestamp la plus récente
              if (item['timestamp'] != null) {
                lastSeen = item['timestamp'];
              }
            }
          }
          
          return <String, dynamic>{
            'temperature': temperature,
            'humidity': humidity,
            'litterHumidity': litterHumidity,
            'lastSeen': lastSeen,
          };
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des données dashboard: $e');
    }
    
    // Retourner des données vides si aucune donnée trouvée
    return <String, dynamic>{
      'temperature': 0.0,
      'humidity': 0,
      'litterHumidity': 0,
      'lastSeen': '', // Chaîne vide au lieu de DateTime.now()
    };
  }

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

  Future<Map<String, dynamic>?> getSensorStats(String catId, {int hours = 24}) async {
    try {
      final token = AuthState.instance.accessToken;
      if (token == null || token.isEmpty) {
        return {
          'temperature': {'avg': 0.0, 'min': 0.0, 'max': 0.0},
          'humidity': {'avg': 0, 'min': 0, 'max': 0},
          'litterHumidity': {'avg': 0, 'min': 0, 'max': 0},
          'lastSeen': DateTime.now().toIso8601String(),
        };
      }

      // Récupérer les données des capteurs pour ce chat
      final resp = await ApiClient.instance.get(
        '/ruuvitags/data?catIds=$catId',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['state'] == true && data['data'] != null) {
          final sensorData = data['data'] as List<dynamic>;
          
          // Calculer les moyennes par type de capteur
          double tempSum = 0;
          double humiditySum = 0;
          double litterHumiditySum = 0;
          int tempCount = 0;
          int humidityCount = 0;
          int litterCount = 0;
          String lastSeen = DateTime.now().toIso8601String();
          
          for (var item in sensorData) {
            if (item['catId'] == catId) {
              switch (item['type']) {
                case 'ENVIRONMENT':
                  if (item['temperature'] != null) {
                    tempSum += (item['temperature'] as num).toDouble();
                    tempCount++;
                  }
                  if (item['humidity'] != null) {
                    humiditySum += (item['humidity'] as num).toDouble();
                    humidityCount++;
                  }
                  break;
                case 'LITTER':
                  if (item['humidity'] != null) {
                    litterHumiditySum += (item['humidity'] as num).toDouble();
                    litterCount++;
                  }
                  break;
              }
              
              if (item['timestamp'] != null) {
                lastSeen = item['timestamp'];
              }
            }
          }
          
          return {
            'temperature': {
              'avg': tempCount > 0 ? tempSum / tempCount : 0.0,
              'min': 0.0, // À calculer si nécessaire
              'max': 0.0, // À calculer si nécessaire
            },
            'humidity': {
              'avg': humidityCount > 0 ? (humiditySum / humidityCount).round() : 0,
              'min': 0, // À calculer si nécessaire
              'max': 0, // À calculer si nécessaire
            },
            'litterHumidity': {
              'avg': litterCount > 0 ? (litterHumiditySum / litterCount).round() : 0,
              'min': 0, // À calculer si nécessaire
              'max': 0, // À calculer si nécessaire
            },
            'lastSeen': lastSeen,
          };
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des données capteurs: $e');
    }
    
    // Retourner des données vides si aucune donnée trouvée
    return {
      'temperature': {'avg': 0.0, 'min': 0.0, 'max': 0.0},
      'humidity': {'avg': 0, 'min': 0, 'max': 0},
      'litterHumidity': {'avg': 0, 'min': 0, 'max': 0},
      'lastSeen': DateTime.now().toIso8601String(),
    };
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
    final String? cid = catId ?? await getUserCatId();
    if (cid == null) return false;
    
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
    final String? cid = catId ?? await getUserCatId();
    if (cid == null) return false;
    
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
    final String? cid = catId ?? await getUserCatId();
    if (cid == null) return false;
    
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

  // ----- Compat Dashboard (même API que RealApiService) -----

  /// Mappe les alertes backend vers { type, level, message }
  Future<List<Map<String, dynamic>>> fetchAlerts() async {
    try {
      final catId = await getUserCatId();
      if (catId == null) return <Map<String, dynamic>>[];
      
      final raw = await getCatAlerts(catId);
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
  Future<Map<String, dynamic>> fetchLitterData({String? catId}) async {
    final String? cid = catId ?? await getUserCatId();
    if (cid == null) {
      return <String, dynamic>{
        'dailyUsage': 0,
        'cleanliness': 0,
        'events': <String>[],
        'anomalies': <String>[],
      };
    }
    
    final token = AuthState.instance.accessToken;
    if (token == null || token.isEmpty) {
      return <String, dynamic>{
        'dailyUsage': 0,
        'cleanliness': 0,
        'events': <String>[],
        'anomalies': <String>[],
      };
    }

    try {
      // Récupérer les données des capteurs pour ce chat
      final response = await ApiClient.instance.get(
        '/ruuvitags/data?catIds=$cid',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['state'] == true && data['data'] != null) {
          final sensorData = data['data'] as List;
          
          // Chercher les données du capteur LITTER pour ce chat
          for (var item in sensorData) {
            if (item['catId'] == cid && item['type'] == 'LITTER') {
              return <String, dynamic>{
                'dailyUsage': item['dailyUsage'] ?? 0,
                'cleanliness': item['cleanliness'] ?? 0,
                'events': (item['events'] as List?)?.cast<String>() ?? <String>[],
                'anomalies': (item['anomalies'] as List?)?.cast<String>() ?? <String>[],
              };
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des données de litière: $e');
    }

    // Retourner des données vides si aucune donnée trouvée
    return <String, dynamic>{
      'dailyUsage': 0,
      'cleanliness': 0,
      'events': <String>[],
      'anomalies': <String>[],
    };
  }
}
