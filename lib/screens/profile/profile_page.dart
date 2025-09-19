// lib/screens/profile/profile_page.dart
import 'package:abd_petcare/core/services/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/ruuvi_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _catData;
  List<RuuviTag> _ruuviTags = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = AuthState.instance.refreshToken;
      if (token == null || token.isEmpty) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('http://localhost:3000/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['state'] == true && data['data'] != null) {
          final userData = data['data'];
          final extras = data['extras'];
          
          // Récupérer le premier chat (pour l'instant, on assume un chat par utilisateur)
          if (extras != null && extras['cats'] != null && extras['cats'].isNotEmpty) {
            final cat = extras['cats'][0]; // Premier chat
            setState(() {
              _catData = {
                'id': cat['id'],
                'name': cat['name'],
                'breed': cat['breed'],
                'birthDate': cat['birthDate'],
                'weight': cat['weight'],
                'color': cat['color'],
                'gender': cat['gender'],
                'healthNotes': cat['healthNotes'],
              };
              
              // TODO: Remplacer par l'appel API réel quand le backend sera mis à jour
              // _loadRuuviTags(cat['id']);
              
              // Données simulées pour les RuuviTags en attendant la mise à jour du backend
              _loadSimulatedRuuviTags();
            });
          } else {
            setState(() {
              _catData = null;
              _ruuviTags = [];
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Erreur lors du chargement des données');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      print('Erreur lors du chargement des données utilisateur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// TODO: Remplacer cette méthode par l'appel API réel quand le backend sera mis à jour
  /// Exemple de structure attendue pour l'API future :
  /// GET /cats/{catId}/ruuvi-tags
  /// ou GET /users/me/ruuvi-tags
  Future<void> _loadRuuviTags(String catId) async {
    try {
      final token = AuthState.instance.refreshToken;
      if (token == null || token.isEmpty) return;

      // TODO: Remplacer par l'endpoint réel
      // final response = await http.get(
      //   Uri.parse('http://localhost:3000/cats/$catId/ruuvi-tags'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      // );

      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   if (data['state'] == true && data['data'] != null) {
      //     setState(() {
      //       _ruuviTags = (data['data'] as List)
      //           .map((tag) => RuuviTag.fromJson(tag))
      //           .toList();
      //     });
      //   }
      // }
    } catch (e) {
      print('Erreur lors du chargement des RuuviTags: $e');
    }
  }

  /// Données simulées pour les RuuviTags en attendant la mise à jour du backend
  void _loadSimulatedRuuviTags() {
    setState(() {
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

  Future<void> _updateCat(Map<String, dynamic> updatedData) async {
    try {
      final token = AuthState.instance.refreshToken;
      if (token == null || token.isEmpty) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.put(
        Uri.parse('http://localhost:3000/cats/${_catData!['id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['state'] == true) {
          // Recharger les données après modification
          await _loadUserData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Informations du chat mises à jour')),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _updateUser(Map<String, dynamic> updatedData) async {
    try {
      final token = AuthState.instance.refreshToken;
      if (token == null || token.isEmpty) {
        throw Exception('Token d\'authentification manquant');
      }

      final user = AuthState.instance.user;
      final userId = user?['id'];
      if (userId == null) {
        throw Exception('ID utilisateur manquant');
      }

      final response = await http.put(
        Uri.parse('http://localhost:3000/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['state'] == true) {
          // Mettre à jour les données utilisateur dans AuthState
          await _updateUserInAuthState(data['data']);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil utilisateur mis à jour')),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  /// Met à jour les données utilisateur dans AuthState et les persiste
  Future<void> _updateUserInAuthState(Map<String, dynamic> updatedUserData) async {
    try {
      // Mettre à jour les données utilisateur en mémoire
      final currentUser = AuthState.instance.user;
      if (currentUser != null) {
        currentUser.addAll(updatedUserData);
        
        // Persister les nouvelles données
        final sp = await SharedPreferences.getInstance();
        await sp.setString('catcare_user', jsonEncode(currentUser));
        
        // Forcer le rebuild de l'interface
        setState(() {});
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des données utilisateur: $e');
    }
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
          if (_catData != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditCatDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header utilisateur
                    _buildUserHeader(theme, username, email),
                    const SizedBox(height: 24),

                    // Section Chat
                    _buildCatSection(),
                    const SizedBox(height: 24),

                    // Section Capteurs
                    _buildSensorsSection(),
                    const SizedBox(height: 24),

                    // Réglages rapides
                    _buildSettingsSection(theme),
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

  Widget _buildUserHeader(ThemeData theme, String username, String email) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          child: const Icon(Icons.pets, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(email, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditUserDialog(),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur inconnue s\'est produite',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
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
                if (_catData != null)
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
              _buildInfoRow('Sexe', _convertGenderToFrench(_catData!['gender'])), // Utiliser la conversion
              if (_catData!['healthNotes']?.isNotEmpty == true)
                _buildInfoRow('Notes de santé', _catData!['healthNotes']),
            ] else
              Column(
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun chat configuré',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/add-cat'),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un chat'),
                  ),
                ],
              ),
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
                const Spacer(),
                // Indicateur que les données sont simulées
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Simulé',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ruuviTags.isNotEmpty) ...[
              ..._ruuviTags.map((tag) => _buildSensorInfo(tag)),
            ] else
              Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun capteur configuré',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
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
    if (_catData == null) return;

    final nameController = TextEditingController(text: _catData!['name'] ?? '');
    final breedController = TextEditingController(text: _catData!['breed'] ?? '');
    final weightController = TextEditingController(text: _catData!['weight']?.toString() ?? '');
    final colorController = TextEditingController(text: _catData!['color'] ?? '');
    final healthNotesController = TextEditingController(text: _catData!['healthNotes'] ?? '');
    
    // Convertir la valeur française vers la valeur anglaise pour le dropdown
    String? selectedGender = _convertGenderToEnglish(_catData!['gender']);
    DateTime? birthDate = _catData!['birthDate'] != null 
        ? DateTime.tryParse(_catData!['birthDate']) 
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier les informations du chat'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du chat',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: breedController,
                  decoration: const InputDecoration(
                    labelText: 'Race',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Sexe',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Mâle')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Femelle')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedGender = value),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: birthDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => birthDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Text(
                          birthDate != null 
                              ? '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}'
                              : 'Sélectionner la date de naissance',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Poids (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'Couleur',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: healthNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes de santé',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le nom du chat est requis')),
                  );
                  return;
                }

                final updatedData = {
                  'name': nameController.text.trim(),
                  'breed': breedController.text.trim(),
                  'gender': selectedGender, // Garder la valeur anglaise pour l'API
                  'birthDate': birthDate?.toIso8601String().split('T')[0],
                  'weight': double.tryParse(weightController.text.trim()),
                  'color': colorController.text.trim(),
                  'healthNotes': healthNotesController.text.trim(),
                };

                Navigator.of(context).pop();
                await _updateCat(updatedData);
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  /// Convertit la valeur française du sexe vers la valeur anglaise pour l'API
  String? _convertGenderToEnglish(String? gender) {
    if (gender == null) return null;
    
    switch (gender.toLowerCase()) {
      case 'masculin':
      case 'male':
        return 'MALE';
      case 'féminin':
      case 'femelle':
      case 'female':
        return 'FEMALE';
      default:
        return null;
    }
  }

  /// Convertit la valeur anglaise du sexe vers la valeur française pour l'affichage
  String _convertGenderToFrench(String? gender) {
    if (gender == null) return 'Non spécifié';
    
    switch (gender.toUpperCase()) {
      case 'MALE':
        return 'Mâle';
      case 'FEMALE':
        return 'Femelle';
      default:
        return gender;
    }
  }

  void _showEditUserDialog() {
    final user = AuthState.instance.user;
    final usernameController = TextEditingController(text: user?['username'] ?? '');
    final phoneController = TextEditingController(text: user?['phoneNumber'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'utilisateur',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?['email'] ?? user?['encryptedEmail'] ?? 'Email non disponible',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'L\'email ne peut pas être modifié',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom d\'utilisateur est requis')),
                );
                return;
              }

              final updatedData = {
                'username': usernameController.text.trim(),
                'phoneNumber': phoneController.text.trim(),
              };

              Navigator.of(context).pop();
              await _updateUser(updatedData);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }
}
