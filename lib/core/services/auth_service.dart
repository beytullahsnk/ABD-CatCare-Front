
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';


class AuthService {

  /// Récupère l'utilisateur courant et ses chats (call /users/me)
  Future<Map<String, dynamic>?> fetchUserWithCats() async {
    final resp = await ApiClient.instance.get('/users/me', headers: authHeader);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  }
  String? get persistedAccessToken {
    return _accessToken;
  }
  String? get persistedRefreshToken {
    return _refreshToken;
  }
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kToken = 'catcare_token';
  static const _kRefresh = 'catcare_refresh';

  String? _accessToken;
  String? _refreshToken;

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
    return {'Authorization': 'Bearer $_refreshToken'};
  }

  Future<bool> login(String emailOrUsername, String password) async {
    final body = {'identifier': emailOrUsername, 'password': password};
    final resp = await ApiClient.instance.post('/auth/login', body);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final token =
          data['accessToken'] ?? data['token'] ?? data['access_token'];
      final refresh = data['refreshToken'] ?? data['refresh_token'];
      if (token != null) {
        await saveTokens(token, refresh);
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    await clearTokens();
  }

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    final resp = await ApiClient.instance.get('/auth/me', headers: authHeader);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<http.Response> authGet(String path) async {
    final r = await ApiClient.instance.get(path, headers: authHeader);
    if (r.statusCode != 401) return r;
    // TODO: implement refresh flow
    return r;
  }
}
