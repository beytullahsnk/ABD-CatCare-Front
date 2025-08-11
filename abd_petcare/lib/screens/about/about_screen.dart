import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ListTile(
              leading: Icon(Icons.pets),
              title: Text(appName),
              subtitle: Text('Données simulées en local pour la démo.'),
            ),
            SizedBox(height: 8),
            ListTile(
              title: Text('Version'),
              subtitle: Text(appVersion),
            ),
            ListTile(
              title: Text('Crédits'),
              subtitle: Text(
                  'ABD Team — Site: https://abdpetcare.example (placeholder)'),
            ),
          ],
        ),
      ),
    );
  }
}
