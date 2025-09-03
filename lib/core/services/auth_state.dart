import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Gestion simple de l'état d'authentification
/// - Persistance via SharedPreferences (clé 'logged_in')
/// - Notifie le router pour recalculer les redirections
class AuthState {
  Map<String, dynamic>? _user;
  String? _accessToken;
  String? _refreshToken;

  Map<String, dynamic>? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  /// Appelée après login API : stocke user et tokens, persiste et notifie
  Future<void> signInWithApiResponse(Map<String, dynamic> apiData) async {
  _user = apiData['user'] as Map<String, dynamic>?;
  _accessToken = apiData['tokens']?['accessToken'] as String?;
  _refreshToken = apiData['tokens']?['refreshToken'] as String?;
  // Persiste tokens
  await AuthService.instance.saveTokens(_accessToken ?? '', _refreshToken);
  await setLoggedIn(true);
  }
  AuthState._();

  static const String _loggedInKey = 'logged_in';
  static final AuthState instance = AuthState._();

  /// Notifier utilisé par go_router (refreshListenable)
  final ValueNotifier<bool> loggedIn = ValueNotifier<bool>(false);

  Future<void> load() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final bool value = sp.getBool(_loggedInKey) ?? false;
    loggedIn.value = value;
    // load tokens as well (non-blocking)
    await AuthService.instance.loadTokens();
  }

  Future<void> setLoggedIn(bool value) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setBool(_loggedInKey, value);
    loggedIn.value = value;
  }

  Future<bool> signIn(String identifier, String password) async {
    final ok = await AuthService.instance.login(identifier, password);
    await setLoggedIn(ok);
    return ok;
  }

  Future<void> signOut() async {
    await AuthService.instance.logout();
    await setLoggedIn(false);
  }
}
