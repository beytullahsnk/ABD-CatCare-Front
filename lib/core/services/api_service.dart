import 'dart:convert';
import 'package:abd_petcare/core/services/auth_service.dart';
import 'package:abd_petcare/core/services/auth_state.dart';
import 'package:abd_petcare/models/notification_prefs.dart';
import 'package:abd_petcare/models/ruuvi_tag.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class RealApiService {
  RealApiService._();
  static final RealApiService instance = RealApiService._();

  Future<Map<String, String>> _getHeaders() async {
    final token = AuthState.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Token d\'authentification manquant');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>?> fetchLatestSensorData(String catId) async {
    try {
      // Utiliser la même logique que fetchDashboardData mais retourner seulement les données brutes
      final token = AuthState.instance.accessToken;
      if (token == null || token.isEmpty) {
        return null;
      }

      // Récupérer les RuuviTags de l'utilisateur pour faire le mapping
      final ruuviTagsResp = await ApiClient.instance.get(
        '/ruuvitags',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, String> ruuviTagToType = {};
      if (ruuviTagsResp.statusCode == 200) {
        final ruuviTagsData = jsonDecode(ruuviTagsResp.body);
        if (ruuviTagsData['state'] == true && ruuviTagsData['data'] != null) {
          final ruuviTags = (ruuviTagsData['data'] as List)
              .map((tag) => RuuviTag.fromJson(tag))
              .where((tag) => tag.catIds != null && tag.catIds!.contains(catId))
              .toList();
          
          for (final tag in ruuviTags) {
            ruuviTagToType[tag.id] = tag.type.value;
          }
        }
      }

      // Récupérer les données des capteurs
      final resp = await ApiClient.instance.get(
        '/ruuvitags/data',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['state'] == true && data['data'] != null) {
          final sensorData = data['data']['items'] as List<dynamic>? ?? [];
          
          // Filtrer et trier les données
          final validData = sensorData.where((item) => item['timestamp'] != null).toList();
          validData.sort((a, b) {
            try {
              final timestampA = a['timestamp'] as String;
              final timestampB = b['timestamp'] as String;
              return DateTime.parse(timestampB).compareTo(DateTime.parse(timestampA));
            } catch (e) {
              return 0;
            }
          });
          
          // Organiser les données par type et prendre seulement la première (plus récente) de chaque type
          Map<String, dynamic> latestByType = {};
          
          for (var item in validData) {
            final ruuviTagId = item['ruuvitagId'] as String?;
            if (ruuviTagId != null && ruuviTagToType.containsKey(ruuviTagId)) {
              final type = ruuviTagToType[ruuviTagId];
              
              // Si on n'a pas encore de donnée pour ce type, la prendre (c'est la plus récente)
              if (type != null && !latestByType.containsKey(type)) {
                latestByType[type] = item;
              }
            }
          }
          
          // Retourner les données organisées par type
          return {
            'environment': latestByType['ENVIRONMENT'],
            'litter': latestByType['LITTER'],
            'collar': latestByType['COLLAR'],
          };
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des données capteurs: $e');
    }
    return null;
  }

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
      final catId = await getUserCatId();
      if (catId == null) {
        return <String, dynamic>{
          'temperature': 0.0,
          'humidity': 0,
          'litterHumidity': 0,
          'lastSeen': '',
        };
      }

      final token = AuthState.instance.accessToken;
      if (token == null || token.isEmpty) {
        return <String, dynamic>{
          'temperature': 0.0,
          'humidity': 0,
          'litterHumidity': 0,
          'lastSeen': '',
        };
      }

      // D'abord, récupérer les RuuviTags de l'utilisateur pour faire le mapping
      final ruuviTagsResp = await ApiClient.instance.get(
        '/ruuvitags',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, String> ruuviTagToType = {};
      if (ruuviTagsResp.statusCode == 200) {
        final ruuviTagsData = jsonDecode(ruuviTagsResp.body);
        if (ruuviTagsData['state'] == true && ruuviTagsData['data'] != null) {
          final ruuviTags = (ruuviTagsData['data'] as List)
              .map((tag) => RuuviTag.fromJson(tag))
              .where((tag) => tag.catIds != null && tag.catIds!.contains(catId))
              .toList();
          
          for (final tag in ruuviTags) {
            ruuviTagToType[tag.id] = tag.type.value;
          }
        }
      }

      // Maintenant, récupérer les données des capteurs
      final resp = await ApiClient.instance.get(
        '/ruuvitags/data',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['state'] == true && data['data'] != null) {
          // Adapter à la nouvelle structure: data.items au lieu de data directement
          final sensorData = data['data']['items'] as List<dynamic>? ?? [];
          
          // Filtrer les données qui ont un timestamp valide et les trier
          final validData = sensorData.where((item) => item['timestamp'] != null).toList();
          validData.sort((a, b) {
            try {
              final timestampA = a['timestamp'] as String;
              final timestampB = b['timestamp'] as String;
              return DateTime.parse(timestampB).compareTo(DateTime.parse(timestampA));
            } catch (e) {
              return 0;
            }
          });
          
          // Organiser les données par type et prendre seulement la première (plus récente) de chaque type
          Map<String, dynamic> latestByType = {};
          
          for (var item in validData) {
            final ruuviTagId = item['ruuvitagId'] as String?;
            if (ruuviTagId != null && ruuviTagToType.containsKey(ruuviTagId)) {
              final type = ruuviTagToType[ruuviTagId];
              
              // Si on n'a pas encore de donnée pour ce type, la prendre (c'est la plus récente)
              if (type != null && !latestByType.containsKey(type)) {
                latestByType[type] = item;
              }
            }
          }
          
          // Extraire les valeurs des données les plus récentes
          double temperature = 0.0;
          int humidity = 0;
          int litterHumidity = 0;
          String lastSeen = '';
          
          // Données d'environnement les plus récentes
          if (latestByType.containsKey('ENVIRONMENT')) {
            final envData = latestByType['ENVIRONMENT'];
            if (envData['temperature'] != null) {
              temperature = double.tryParse(envData['temperature'].toString()) ?? 0.0;
            }
            if (envData['humidity'] != null) {
              humidity = double.tryParse(envData['humidity'].toString())?.round() ?? 0;
            }
                         final envTimestamp = envData['timestamp'] as String?;
            if (envTimestamp != null) {
              lastSeen = envTimestamp;
            }
          }
          
          // Données de litière les plus récentes
          if (latestByType.containsKey('LITTER')) {
            final litterData = latestByType['LITTER'];
            if (litterData['humidity'] != null) {
              litterHumidity = double.tryParse(litterData['humidity'].toString())?.round() ?? 0;
            }
            final litterTimestamp = litterData['timestamp'] as String?;
            if (litterTimestamp != null && 
                (lastSeen.isEmpty || DateTime.parse(litterTimestamp).isAfter(DateTime.parse(lastSeen)))) {
              lastSeen = litterTimestamp;
            }
          }
          
          // Traitement spécifique du collier pour calculer la dernière activité
          String lastMovementTime = '';
          if (latestByType.containsKey('COLLAR')) {
            // Rechercher dans toutes les données du collier pour trouver la dernière activité
            String? collarRuuviTagId;
            for (final entry in ruuviTagToType.entries) {
              if (entry.value == 'COLLAR') {
                collarRuuviTagId = entry.key;
                break;
              }
            }
            
            if (collarRuuviTagId != null) {
              // Parcourir toutes les données du collier pour trouver la dernière avec mouvement
              for (var item in validData) {
                if (item['ruuvitagId'] == collarRuuviTagId) {
                  try {
                    final movementValue = item['movement'];
                    final movement = movementValue != null ? double.tryParse(movementValue.toString()) ?? 0.0 : 0.0;
                    final timestamp = item['timestamp'] as String?;
                    
                    if (movement > 0 && timestamp != null) {
                      lastMovementTime = timestamp;
                      break; // Prendre la première (plus récente) avec mouvement
                    }
                  } catch (e) {
                    continue;
                  }
                }
              }
            }
          }

          // Calculer le temps écoulé depuis la dernière activité
          String formattedLastSeen = '';
          if (lastMovementTime.isNotEmpty) {
            try {
              final lastActivity = DateTime.parse(lastMovementTime);
              final now = DateTime.now();
              final difference = now.difference(lastActivity);
              
              if (difference.inMinutes < 60) {
                formattedLastSeen = 'en activité il y a ${difference.inMinutes}min';
              } else if (difference.inHours < 3) {
                // Afficher heures et minutes pour plus de précision
                final hours = difference.inHours;
                final minutes = difference.inMinutes % 60;
                formattedLastSeen = 'en activité il y a ${hours}h${minutes}min';
              } else if (difference.inHours < 24) {
                formattedLastSeen = 'en activité il y a ${difference.inHours}h';
              } else {
                formattedLastSeen = 'en activité il y a ${difference.inDays}j';
              }
            } catch (e) {
              formattedLastSeen = 'Aucune activité récente';
            }
          } else {
            formattedLastSeen = 'Aucune activité détectée';
          }

          lastSeen = formattedLastSeen;
          
          return <String, dynamic>{
            'temperature': temperature,
            'humidity': humidity,
            'litterHumidity': litterHumidity,
            'lastSeen': lastSeen.isEmpty ? '—' : lastSeen,
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
      'lastSeen': '',
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

      // D'abord, récupérer les RuuviTags de l'utilisateur pour faire le mapping
      final ruuviTagsResp = await ApiClient.instance.get(
        '/ruuvitags',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, String> ruuviTagToType = {};
      if (ruuviTagsResp.statusCode == 200) {
        final ruuviTagsData = jsonDecode(ruuviTagsResp.body);
        if (ruuviTagsData['state'] == true && ruuviTagsData['data'] != null) {
          final ruuviTags = (ruuviTagsData['data'] as List)
              .map((tag) => RuuviTag.fromJson(tag))
              .where((tag) => tag.catIds != null && tag.catIds!.contains(catId))
              .toList();
          
          for (final tag in ruuviTags) {
            ruuviTagToType[tag.id] = tag.type.value;
          }
        }
      }

      // Récupérer les données des capteurs
    final resp = await ApiClient.instance.get(
        '/ruuvitags/data',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
    );
      
    if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['state'] == true && data['data'] != null) {
          final sensorData = data['data']['items'] as List<dynamic>? ?? [];
          
          // Calculer les moyennes par type de capteur
          double tempSum = 0;
          double humiditySum = 0;
          double litterHumiditySum = 0;
          int tempCount = 0;
          int humidityCount = 0;
          int litterCount = 0;
          String lastSeen = '';
          
          for (var item in sensorData) {
            final ruuviTagId = item['ruuvitagId'] as String?;
            if (ruuviTagId != null && ruuviTagToType.containsKey(ruuviTagId)) {
              final type = ruuviTagToType[ruuviTagId];
              
              switch (type) {
                case 'ENVIRONMENT':
                  if (item['temperature'] != null) {
                    tempSum += double.tryParse(item['temperature'].toString()) ?? 0.0;
                    tempCount++;
                  }
                  if (item['humidity'] != null) {
                    humiditySum += double.tryParse(item['humidity'].toString()) ?? 0.0;
                    humidityCount++;
                  }
                  break;
                case 'LITTER':
                  if (item['humidity'] != null) {
                    litterHumiditySum += double.tryParse(item['humidity'].toString()) ?? 0.0;
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
      // D'abord, récupérer les RuuviTags de l'utilisateur pour faire le mapping
      final ruuviTagsResp = await ApiClient.instance.get(
        '/ruuvitags',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Set<String> litterRuuviTags = {};
      if (ruuviTagsResp.statusCode == 200) {
        final ruuviTagsData = jsonDecode(ruuviTagsResp.body);
        if (ruuviTagsData['state'] == true && ruuviTagsData['data'] != null) {
          final allRuuviTags = (ruuviTagsData['data'] as List)
              .map((tag) => RuuviTag.fromJson(tag))
              .where((tag) => tag.catIds != null && tag.catIds!.contains(cid))
              .toList();
          
          final ruuviTags = allRuuviTags.where((tag) => tag.type == RuuviTagType.litter).toList();
          
          for (final tag in ruuviTags) {
            litterRuuviTags.add(tag.id);
          }
        }
      }
      
      // Récupérer les données des capteurs
      final response = await ApiClient.instance.get(
        '/ruuvitags/data',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
          );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['state'] == true && data['data'] != null) {
          final sensorData = data['data']['items'] as List? ?? [];
          
          // Filtrer et trier les données par timestamp (comme dans fetchDashboardData)
          final validData = sensorData.where((item) => item['timestamp'] != null).toList();
          validData.sort((a, b) {
            try {
              final timestampA = a['timestamp'] as String;
              final timestampB = b['timestamp'] as String;
              return DateTime.parse(timestampB).compareTo(DateTime.parse(timestampA));
            } catch (e) {
              return 0;
            }
          });
          
          // Chercher les données du capteur LITTER pour ce chat
          for (var item in validData) {
            final ruuviTagId = item['ruuvitagId'] as String?;
            if (ruuviTagId != null && litterRuuviTags.contains(ruuviTagId)) {
              // Afficher l'humidité directement
              final humidity = double.tryParse(item['humidity']?.toString() ?? '0') ?? 0.0;
              
              // Compter les passages dans les dernières 24h
              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              int dailyUsage = 0;
              List<String> events = [];
              
              // Parcourir toutes les données du capteur LITTER pour compter les passages
              for (var litterItem in validData) {
                if (litterItem['ruuvitagId'] == ruuviTagId) {
                  final timestamp = litterItem['timestamp'] as String?;
                  if (timestamp != null) {
                    try {
                      final itemTime = DateTime.parse(timestamp);
                      // Si c'est aujourd'hui
                      if (itemTime.isAfter(todayStart)) {
                        final movement = double.tryParse(litterItem['movement']?.toString() ?? '0') ?? 0.0;
                        // Seuil de mouvement pour détecter un passage (à ajuster selon vos besoins)
                        if (movement > 0.5) {
                          dailyUsage++;
                          // Formater l'heure pour le journal
                          final timeStr = '${itemTime.hour.toString().padLeft(2, '0')}:${itemTime.minute.toString().padLeft(2, '0')}';
                          events.add(timeStr);
                        }
                      }
                    } catch (e) {
                      continue;
                    }
                  }
                }
              }
              
              // Limiter à 10 événements les plus récents
              events = events.take(10).toList();

              return <String, dynamic>{
                'dailyUsage': dailyUsage,
                'cleanliness': humidity.round(),
          'events': events,
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

  Future<List<Map<String, dynamic>>?> getActivityHistory(String catId, {int limit = 10}) async {
    try {
      // Récupérer d'abord les RuuviTags pour identifier l'ID du COLLAR
      final ruuviTagsResponse = await http.get(
        Uri.parse('${ApiClient.instance.baseUrl}/ruuvitags'),
        headers: await _getHeaders(),
      );
      
      if (ruuviTagsResponse.statusCode != 200) {
        return null;
      }
      
      final ruuviTagsData = jsonDecode(ruuviTagsResponse.body);
      final ruuviTags = ruuviTagsData['data'] as List<dynamic>? ?? [];
      
      // Trouver l'ID du RuuviTag COLLAR
      String? collarRuuviTagId;
      for (final tag in ruuviTags) {
        final tagData = tag as Map<String, dynamic>;
        final tagId = tagData['id']?.toString();
        final tagType = tagData['type'] as String?;
        if (tagId != null && tagType == 'COLLAR') {
          collarRuuviTagId = tagId;
          break;
        }
      }

      if (collarRuuviTagId == null) {
        return [];
      }
      
      // Essayer plusieurs appels avec des paramètres différents
      List<Map<String, dynamic>> allCollarData = [];
      
      // Appel 1 : Sans paramètres
      var response1 = await http.get(
        Uri.parse('${ApiClient.instance.baseUrl}/ruuvitags/data'),
        headers: await _getHeaders(),
      );
      
      if (response1.statusCode == 200) {
        final data1 = jsonDecode(response1.body);
        final items1 = data1['data']['items'] as List<dynamic>? ?? [];
        
        final collarData1 = items1
            .where((item) => item['ruuvitagId'] == collarRuuviTagId)
            .cast<Map<String, dynamic>>()
            .toList();
        
        allCollarData.addAll(collarData1);
      }
      
      // Appel 2 : Avec un paramètre limit plus grand
      var response2 = await http.get(
        Uri.parse('${ApiClient.instance.baseUrl}/ruuvitags/data?limit=50'),
        headers: await _getHeaders(),
      );
      
      if (response2.statusCode == 200) {
        final data2 = jsonDecode(response2.body);
        final items2 = data2['data']['items'] as List<dynamic>? ?? [];
        
        final collarData2 = items2
            .where((item) => item['ruuvitagId'] == collarRuuviTagId)
            .cast<Map<String, dynamic>>()
            .toList();
        
        allCollarData.addAll(collarData2);
      }
      
      // Appel 3 : Avec un paramètre offset
      var response3 = await http.get(
        Uri.parse('${ApiClient.instance.baseUrl}/ruuvitags/data?offset=10'),
        headers: await _getHeaders(),
      );
      
      if (response3.statusCode == 200) {
        final data3 = jsonDecode(response3.body);
        final items3 = data3['data']['items'] as List<dynamic>? ?? [];
        
        final collarData3 = items3
            .where((item) => item['ruuvitagId'] == collarRuuviTagId)
            .cast<Map<String, dynamic>>()
            .toList();
        
        allCollarData.addAll(collarData3);
      }
      
      // Supprimer les doublons basés sur le timestamp
      final uniqueData = <String, Map<String, dynamic>>{};
      for (final item in allCollarData) {
        final timestamp = item['timestamp'] as String?;
        if (timestamp != null) {
          uniqueData[timestamp] = item;
        }
      }
      
      final finalData = uniqueData.values.toList();
      
      // Trier par timestamp décroissant et limiter
      finalData.sort((a, b) {
        final timestampA = a['timestamp'] as String? ?? '';
        final timestampB = b['timestamp'] as String? ?? '';
        return timestampB.compareTo(timestampA);
      });
      
      return finalData.take(limit).toList();
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique d\'activité: $e');
      return null;
    }
  }
}
