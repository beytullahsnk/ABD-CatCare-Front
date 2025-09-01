import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kToken = 'catcare_token';
  static const _kRefresh = 'catcare_refresh';

  String? _accessToken;
  String? _refreshToken;
  String? lastError;

  void _log(String message) {
    // Mirror logs to both debug console and developer log to ensure visibility
    debugPrint(message);
    dev.log(message, name: 'AuthService');
  }

  Future<void> loadTokens() async {
    final sp = await SharedPreferences.getInstance();
    _accessToken = sp.getString(_kToken);
    _refreshToken = sp.getString(_kRefresh);
  }

  Future<void> saveTokens(String access, String? refresh) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kToken, access);
    if (refresh != null) await sp.setString(_kRefresh, refresh);
    _accessToken = access;
    _refreshToken = refresh;
  }

  Future<void> clearTokens() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kToken);
    await sp.remove(_kRefresh);
    _accessToken = null;
    _refreshToken = null;
  }

  Map<String, String> get authHeader {
    if (_accessToken == null) return {};
    return {'Authorization': 'Bearer $_accessToken'};
  }

  Future<bool> login(String emailOrUsername, String password) async {
    final body = {'email': emailOrUsername, 'password': password};
    _log('POST /auth/login -> ${jsonEncode({
          'email': emailOrUsername,
          'password': '***'
        })}');
    try {
      final resp = await ApiClient.instance
          .post('/auth/login', body)
          .timeout(const Duration(seconds: 10));
      final preview = resp.body.length > 400
          ? '${resp.body.substring(0, 400)}…'
          : resp.body;
      _log('POST /auth/login <- ${resp.statusCode} $preview');
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final tokens = (decoded is Map<String, dynamic>)
            ? (decoded['data'] is Map<String, dynamic>
                ? (decoded['data']['tokens'] as Map<String, dynamic>?)
                : (decoded['tokens'] as Map<String, dynamic>?))
            : null;
        final token = tokens?['accessToken'] ??
            decoded['accessToken'] ??
            decoded['token'] ??
            decoded['access_token'];
        final refresh = tokens?['refreshToken'] ??
            decoded['refreshToken'] ??
            decoded['refresh_token'];
        if (token != null) {
          lastError = null;
          await saveTokens(token as String, refresh as String?);
          return true;
        }
      }
      // capture backend error message
      try {
        final d = jsonDecode(resp.body);
        if (d is Map<String, dynamic>) {
          final m = d['message'];
          lastError = m is List ? m.join(', ') : m?.toString();
        }
      } catch (_) {}
    } catch (e) {
      lastError = e.toString();
      _log('POST /auth/login !! $e');
    }
    return false;
  }

  Future<void> logout() async {
    await clearTokens();
  }

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    _log(
        'GET /users/me -> Authorization present? ${authHeader.containsKey('Authorization')}');
    final resp = await ApiClient.instance.get('/users/me', headers: authHeader);
    _log('GET /users/me <- ${resp.statusCode}');
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      }
    }
    return null;
  }

  /// Appelle /auth/register et journalise la requête/réponse
  Future<bool> register({
    required String email,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    final body = {
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
      'password': password,
    };
    _log('POST /auth/register -> ${jsonEncode({...body, 'password': '***'})}');
    try {
      final resp = await ApiClient.instance
          .post('/auth/register', body)
          .timeout(const Duration(seconds: 12));
      final preview = resp.body.length > 400
          ? '${resp.body.substring(0, 400)}…'
          : resp.body;
      _log('POST /auth/register <- ${resp.statusCode} $preview');
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final tokens = (decoded is Map<String, dynamic>)
            ? (decoded['data'] is Map<String, dynamic>
                ? (decoded['data']['tokens'] as Map<String, dynamic>?)
                : (decoded['tokens'] as Map<String, dynamic>?))
            : null;
        final token = tokens?['accessToken'] ?? decoded['accessToken'];
        final refresh = tokens?['refreshToken'] ?? decoded['refreshToken'];
        if (token != null) {
          lastError = null;
          await saveTokens(token as String, refresh as String?);
          return true;
        }
        lastError = null;
        return true; // inscription ok même sans tokens
      }
      // capture backend error message
      try {
        final d = jsonDecode(resp.body);
        if (d is Map<String, dynamic>) {
          final m = d['message'];
          lastError = m is List ? m.join(', ') : m?.toString();
        }
      } catch (_) {}
    } catch (e) {
      lastError = e.toString();
      _log('POST /auth/register !! $e');
    }
    return false;
  }

  Future<http.Response> authGet(String path) async {
    final r = await ApiClient.instance.get(path, headers: authHeader);
    if (r.statusCode != 401) return r;
    // TODO: implement refresh flow
    return r;
  }
}
