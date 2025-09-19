// lib/screens/profile/profile_page.dart
import 'package:abd_petcare/core/services/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/ruuvi_tag.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _catData;
  List<RuuviTag> _ruuviTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCatData();
  }

  Future<void> _loadCatData() async {
    // Simuler le chargement des données du chat
    // En réalité, vous feriez un appel API ici
    setState(() {
      _isLoading = false;
      // Données simulées - remplacez par un vrai appel API
      _catData = {
        'name': 'Minou',
        'breed': 'Persan',
        'birthDate': '2020-05-15',
        'weight': 4.2,
        'color': 'Blanc',
        'gender': 'FEMALE',
        'healthNotes': 'Chat en bonne santé',
      };
      _ruuviTags = [
        RuuviTag(
          id: '1',
          ruuviTagId: '677224097',
          type: RuuviTagType.collar,
        ),
        RuuviTag(
          id: '2',
          ruuviTagId: '791308911',
          type: RuuviTagType.environment,
        ),
        RuuviTag(
          id: '3',
          ruuviTagId: '333419537',
          type: RuuviTagType.litter,
        ),
      ];
    });
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditCatDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header utilisateur
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
                const SizedBox(height: 24),

                // Section Chat
                _buildCatSection(),
                const SizedBox(height: 24),

                // Section Capteurs
                _buildSensorsSection(),
                const SizedBox(height: 24),

                // Réglages rapides
                Text(
                  'Réglages rapides',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                _buildSettingsCard(
                  icon: Icons.favorite_border,
                  title: 'Activité',
                  subtitle: 'Seuil d\'activité',
                  onTap: () => context.push('/settings/activity'),
                ),
                const SizedBox(height: 8),

                _buildSettingsCard(
                  icon: Icons.inventory_2,
                  title: 'Litière',
                  subtitle: 'Humidité et récurrence',
                  onTap: () => context.push('/settings/litter'),
                ),
                const SizedBox(height: 8),

                _buildSettingsCard(
                  icon: Icons.thermostat,
                  title: 'Environnement',
                  subtitle: 'Température et humidité',
                  onTap: () => context.push('/settings/environment'),
                ),

                const SizedBox(height: 24),

                // Déconnexion
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

  Widget _buildCatSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pets,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informations du chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditCatDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_catData != null) ...[
              _buildInfoRow('Nom', _catData!['name']),
              _buildInfoRow('Race', _catData!['breed']),
              _buildInfoRow('Date de naissance', _catData!['birthDate']),
              _buildInfoRow('Poids', '${_catData!['weight']} kg'),
              _buildInfoRow('Couleur', _catData!['color']),
              _buildInfoRow('Sexe', _catData!['gender'] == 'MALE' ? 'Mâle' : 'Femelle'),
              if (_catData!['healthNotes']?.isNotEmpty == true)
                _buildInfoRow('Notes de santé', _catData!['healthNotes']),
            ] else
              const Text('Aucune information de chat disponible'),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Capteurs RuuviTag',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ruuviTags.isNotEmpty) ...[
              ..._ruuviTags.map((tag) => _buildSensorInfo(tag)),
            ] else
              const Text('Aucun capteur configuré'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorInfo(RuuviTag tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getRuuviTagIcon(tag.type),
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag.type.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${tag.ruuviTagId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
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
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onSecondaryContainer),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  IconData _getRuuviTagIcon(RuuviTagType type) {
    switch (type) {
      case RuuviTagType.collar:
        return Icons.pets;
      case RuuviTagType.environment:
        return Icons.home;
      case RuuviTagType.litter:
        return Icons.cleaning_services;
    }
  }

  void _showEditCatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier les informations'),
        content: const Text('Cette fonctionnalité sera bientôt disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
