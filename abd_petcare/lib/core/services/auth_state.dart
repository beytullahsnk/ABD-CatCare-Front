import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestion simple de l'état d'authentification
/// - Persistance via SharedPreferences (clé 'logged_in')
/// - Notifie le router pour recalculer les redirections
class AuthState {
  AuthState._();

  static const String _loggedInKey = 'logged_in';
  static final AuthState instance = AuthState._();

  /// Notifier utilisé par go_router (refreshListenable)
  final ValueNotifier<bool> loggedIn = ValueNotifier<bool>(false);

  Future<void> load() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final bool value = sp.getBool(_loggedInKey) ?? false;
    loggedIn.value = value;
  }

  Future<void> setLoggedIn(bool value) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setBool(_loggedInKey, value);
    loggedIn.value = value;
  }
}
