import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'core/services/auth_state.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'core/services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    if (Platform.isAndroid) {
      ApiClient.instance.setBaseUrl('http://10.0.2.2:3000/api');
    } else if (Platform.isIOS) {
      ApiClient.instance.setBaseUrl('http://localhost:3000/api');
    }
  }

  await AuthState.instance.load();
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
