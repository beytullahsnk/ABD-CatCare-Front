import 'package:abd_petcare/screens/activity/activity_page.dart';
import 'package:abd_petcare/screens/environment/environment_page.dart';
import 'package:abd_petcare/screens/litter/litter_page.dart';
import 'package:abd_petcare/screens/profile/profile_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/services/auth_state.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/notifications/notifications.dart';
import '../screens/about/about_screen.dart';
import '../screens/settings/litter_settings_page.dart';
import '../screens/settings/environment_settings_page.dart';
import '../screens/settings/activity_settings_page.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    navigatorKey: _rootKey,
    refreshListenable: AuthState.instance.loggedIn,
    redirect: (context, state) async {
      // Assure le chargement initial des prefs (non bloquant ensuite)
      if (AuthState.instance.loggedIn.value == false &&
          state.matchedLocation == '/') {
        await AuthState.instance.load();
      }

      final bool isLoggedIn = AuthState.instance.loggedIn.value;
      final String loc = state.matchedLocation;

      final bool goingToAuth = loc == '/login' || loc == '/register';
      final bool protected =
          loc == '/dashboard' || loc == '/settings/notifications';

      if (!isLoggedIn && protected) {
        return '/login';
      }
      if (isLoggedIn && goingToAuth) {
        return '/dashboard';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        name: 'settings_notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/litter',
        name: 'litter',
        builder: (context, state) => const LitterPage(),
      ),
      GoRoute(
        path: '/environment',
        name: 'environment',
        builder: (context, state) => const EnvironmentPage(),
      ),
      GoRoute(
        path: '/activity',
        name: 'activity',
        builder: (context, state) => const ActivityPage(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/settings/litter',
        name: 'settings_litter',
        builder: (context, state) => LitterPageSettings(),
      ),
      GoRoute(
        path: '/settings/activity',
        name: 'settings_activity',
        builder: (context, state) => const ActivitySettingsPage(),
      ),
      GoRoute(
        path: '/settings/environment',
        name: 'settings_environment',
        builder: (context, state) => const EnvironmentSettingsPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
}
