import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'core/services/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthState.instance.load();
  // Log infos utilisateur et tokens à chaque démarrage
  print('User loaded: ${AuthState.instance.user}');
  print('AccessToken: ${AuthState.instance.accessToken}');
  print('RefreshToken: ${AuthState.instance.refreshToken}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Cat Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: AppRouter.router,
    );
  }
}
