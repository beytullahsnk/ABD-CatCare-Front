// lib/screens/profile/profile_page.dart
import 'package:abd_petcare/core/services/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

  final user = AuthState.instance.user;
  final username = user?['username'] ?? 'Nom utilisateur';
  final email = user?['email'] ?? user?['encryptedEmail'] ?? 'adresse@exemple.com';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header utilisateur simplifié
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: const Icon(Icons.pets, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(email, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ligne "Paramètres" → ouvre l'écran central des paramètres (overview)

          const SizedBox(height: 16),

          // SECTION : Raccourcis vers les paramètres individuels (les "seuls cliquables")
          Text('Réglages rapides',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          Card(
            color: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.favorite_border, color: cs.onSecondaryContainer),
              ),
              title: const Text('Activité'),
              subtitle: const Text('Seuil d’activité'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push(
                    '/settings/activity'); // route vers ActivitySettingsPage
              },
            ),
          ),

          const SizedBox(height: 8),

          Card(
            color: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2, color: cs.onSecondaryContainer),
              ),
              title: const Text('Litière'),
              subtitle: const Text('Humidité et récurrence'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/settings/litter'); // route vers LitterPage
              },
            ),
          ),

          const SizedBox(height: 8),

          Card(
            color: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.thermostat, color: cs.onSecondaryContainer),
              ),
              title: const Text('Environnement'),
              subtitle: const Text('Température et humidité'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push(
                    '/settings/environment'); // route vers EnvironmentSettingsPage
              },
            ),
          ),

          const SizedBox(height: 20),

          // Déconnexion rapide
          TextButton.icon(
            onPressed: () async {
              await AuthState.instance.signOut();
              context.push('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
