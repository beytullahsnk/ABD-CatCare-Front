import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String baseUrl = '/api';

  void setBaseUrl(String url) {
    baseUrl = url;
  }

  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    final uri = Uri.parse('$baseUrl$path');
    final h = {...defaultHeaders, if (headers != null) ...headers};
    return http.get(uri, headers: h);
  }

  Future<http.Response> post(String path, Object? body,
      {Map<String, String>? headers}) {
    final uri = Uri.parse('$baseUrl$path');
    final h = {...defaultHeaders, if (headers != null) ...headers};
    final b = body == null ? null : jsonEncode(body);
    return http.post(uri, headers: h, body: b);
  }

  Future<http.Response> put(String path, Object? body,
      {Map<String, String>? headers}) {
    final uri = Uri.parse('$baseUrl$path');
    final h = {...defaultHeaders, if (headers != null) ...headers};
    final b = body == null ? null : jsonEncode(body);
    return http.put(uri, headers: h, body: b);
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) {
    final uri = Uri.parse('$baseUrl$path');
    final h = {...defaultHeaders, if (headers != null) ...headers};
    return http.delete(uri, headers: h);
  }

  // --- MÉTHODES D'AUTHENTIFICATION AJOUTÉES ---

  /// Tente de connecter un utilisateur avec son email et son mot de passe.
  Future<http.Response> login(String email, String password) {
    return post('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  /// Crée un nouveau compte utilisateur.
  Future<http.Response> register(Map<String, dynamic> userData) {
    return post('/auth/register', userData);
  }

  // --- MÉTHODE EXISTANTE ---
  Future<bool> updateCatThresholds(
      String catId, Map<String, dynamic> thresholds,
      {Map<String, String>? headers}) async {
    print('Updating thresholds for cat $catId with data: $thresholds');
    final resp =
        await put('/cats/$catId/thresholds', thresholds, headers: headers);
    print('Response status: ${resp.body}');
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }
}
