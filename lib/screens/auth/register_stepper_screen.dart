import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_state.dart';
import '../../models/ruuvi_tag.dart';
import '../../screens/widgets/primary_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../screens/scan/qr_scanner_screen.dart';
import '../../screens/scan/sensor_type_selection_screen.dart';
import '../../screens/scan/threshold_configuration_screen.dart'; 

class RegisterStepperScreen extends StatefulWidget {
  const RegisterStepperScreen({super.key});

  @override
  State<RegisterStepperScreen> createState() => _RegisterStepperScreenState();
}

class _RegisterStepperScreenState extends State<RegisterStepperScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Données de l'étape 1 - Utilisateur
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final GlobalKey<FormState> _userFormKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // Données de l'étape 2 - Chat
  final TextEditingController _catName = TextEditingController();
  final TextEditingController _catBreed = TextEditingController();
  final TextEditingController _catBirthDate = TextEditingController();
  final TextEditingController _catWeight = TextEditingController();
  final TextEditingController _catColor = TextEditingController();
  final TextEditingController _catHealthNotes = TextEditingController();
  final GlobalKey<FormState> _catFormKey = GlobalKey<FormState>();
  String? _selectedImagePath;
  String? _selectedGender; // Nouveau champ pour le sexe

  // Données de l'étape 3 - RuuviTags
  List<RuuviTag> _ruuviTags = [];

  final List<String> _stepTitles = [
    'Informations personnelles',
    'Informations du chat',
    'Configuration des capteurs',
    'Confirmation',
  ];

  // Options pour le sexe avec valeurs standardisées
  final Map<String, String> _genderOptions = {
    'MALE': 'Mâle',
    'FEMALE': 'Femelle',
  };

  @override
  void initState() {
    super.initState();
    // Ajouter des listeners pour déclencher setState
    _firstName.addListener(_onFieldChanged);
    _lastName.addListener(_onFieldChanged);
    _email.addListener(_onFieldChanged);
    _password.addListener(_onFieldChanged);
    _phone.addListener(_onFieldChanged);
    _catName.addListener(_onFieldChanged);
    _catBreed.addListener(_onFieldChanged);
    _catBirthDate.addListener(_onFieldChanged);
    _catWeight.addListener(_onFieldChanged);
    _catColor.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      // Déclencher un rebuild pour mettre à jour le bouton
    });
  }

  @override
  void dispose() {
    // Supprimer les listeners
    _firstName.removeListener(_onFieldChanged);
    _lastName.removeListener(_onFieldChanged);
    _email.removeListener(_onFieldChanged);
    _password.removeListener(_onFieldChanged);
    _phone.removeListener(_onFieldChanged);
    _catName.removeListener(_onFieldChanged);
    _catBreed.removeListener(_onFieldChanged);
    _catBirthDate.removeListener(_onFieldChanged);
    _catWeight.removeListener(_onFieldChanged);
    _catColor.removeListener(_onFieldChanged);
    
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _catName.dispose();
    _catBreed.dispose();
    _catBirthDate.dispose();
    _catWeight.dispose();
    _catColor.dispose();
    _catHealthNotes.dispose();
    super.dispose();
  }

  // Validateurs
  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Requis' : null;
  
  String? _emailFmt(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requis';
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(v.trim()) ? null : 'Email invalide';
  }

  String? _pwd(String? v) =>
      (v == null || v.length < 8) ? '8 caractères minimum' : null;

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        // Vérifier manuellement les champs de l'utilisateur
        return _firstName.text.trim().isNotEmpty &&
               _lastName.text.trim().isNotEmpty &&
               _email.text.trim().isNotEmpty &&
               _password.text.length >= 8 &&
               _phone.text.trim().isNotEmpty;
      case 1:
        // Vérifier manuellement les champs du chat
        return _catName.text.trim().isNotEmpty &&
               _catBreed.text.trim().isNotEmpty &&
               _catBirthDate.text.trim().isNotEmpty &&
               _catWeight.text.trim().isNotEmpty &&
               _catColor.text.trim().isNotEmpty &&
               _selectedGender != null; // Vérifier que le sexe est sélectionné
      case 2:
        return _ruuviTags.length == 3;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceed()) {
      // Valider le formulaire avant de passer à l'étape suivante
      bool isValid = false;
      switch (_currentStep) {
        case 0:
          isValid = _userFormKey.currentState?.validate() ?? false;
          break;
        case 1:
          isValid = _catFormKey.currentState?.validate() ?? false;
          break;
        case 2:
        case 3:
          isValid = true;
          break;
      }
      
      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);
    
    try {
      final cs = Theme.of(context).colorScheme;
      
      // Étape 1: Créer l'utilisateur
      print('Étape 1: Création de l\'utilisateur...');
      
      final userRequestData = {
        'email': _email.text.trim(),
        'username': (_firstName.text.trim() + '.' + _lastName.text.trim()).replaceAll(' ', ''),
        'phoneNumber': _phone.text.trim(),
        'password': _password.text,
      };
      
      print('🔍 Données utilisateur à envoyer: $userRequestData');
      print(' URL: http://localhost:3000/api/auth/register');
      
      final userResponse = await http.post(
        Uri.parse('http://localhost:3000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userRequestData),
      );

      print('📡 Réponse utilisateur reçue:');
      print('   Status Code: ${userResponse.statusCode}');
      print('   Headers: ${userResponse.headers}');
      print('   Body: ${userResponse.body}');

      if (userResponse.statusCode < 200 || userResponse.statusCode >= 300) {
        print('❌ Erreur HTTP utilisateur: ${userResponse.statusCode}');
        throw Exception('Erreur création utilisateur: ${userResponse.statusCode} - ${userResponse.body}');
      }

      final userData = jsonDecode(userResponse.body);
      print('✅ Données utilisateur parsées: $userData');
      
      if (userData['state'] != true) {
        print('❌ Échec création utilisateur: ${userData['message']}');
        throw Exception('Échec création utilisateur: ${userData['message']}');
      }

      // Connexion automatique après inscription
      await AuthState.instance.signInWithApiResponse(userData['data'], rawEmail: _email.text.trim());
      
      // Étape 2: Créer le chat
      print('Étape 2: Création du chat...');
      final userId = userData['data']['user']['id']; 
      print('User ID récupéré: $userId');
      print('Type de userId: ${userId.runtimeType}');
      
      final catRequestData = { 
        'name': _catName.text.trim(),
        'breed': _catBreed.text.trim(),
        'userId': userId, 
        'birthDate': _catBirthDate.text.trim(),
        'weight': double.tryParse(_catWeight.text.trim()),
        'color': _catColor.text.trim(),
        'gender': _selectedGender,
        'healthNotes': _catHealthNotes.text.trim(),
      };
      
      print('Données du chat à envoyer: $catRequestData'); 
      
      final catResponse = await http.post(
        Uri.parse('http://localhost:3000/api/cats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
        body: jsonEncode(catRequestData), 
      );

      if (catResponse.statusCode < 200 || catResponse.statusCode >= 300) {
        throw Exception('Erreur création chat: ${catResponse.statusCode} - ${catResponse.body}');
      }

      final catData = jsonDecode(catResponse.body);
      if (catData['state'] != true) {
        throw Exception('Échec création chat: ${catData['message']}');
      }

      final catId = catData['data']['id'];
      print('Chat créé avec l\'ID: $catId');

      // Étape 3: Créer les RuuviTags
      print('Étape 3: Création des RuuviTags...');
      for (int i = 0; i < _ruuviTags.length; i++) {
        final tag = _ruuviTags[i];
        print('Création du RuuviTag ${i + 1}/${_ruuviTags.length}: ${tag.id}');
        
        // Créer la structure avec null pour les types non utilisés
        Map<String, dynamic> completeThresholds = {
          'collar': null,
          'environment': null,
          'litter': null,
        };

        // Remplacer par les seuils du type spécifique
        if (tag.alertThresholds != null) {
          switch (tag.type) {
            case RuuviTagType.collar:
              completeThresholds['collar'] = tag.alertThresholds;
              break;
            case RuuviTagType.environment:
              completeThresholds['environment'] = tag.alertThresholds;
              break;
            case RuuviTagType.litter:
              completeThresholds['litter'] = tag.alertThresholds;
              break;
          }
        }

        print('Seuils complets à envoyer: $completeThresholds');

        final ruuviTagResponse = await http.post(
          Uri.parse('http://localhost:3000/api/ruuvitags'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AuthState.instance.accessToken}',
          },
          body: jsonEncode({
            'id': tag.id.toString(), 
            'type': tag.type.value,
            'catIds': [catId],
            'alertThresholds': completeThresholds,
          }),
        );

        if (ruuviTagResponse.statusCode < 200 || ruuviTagResponse.statusCode >= 300) {
          throw Exception('Erreur création RuuviTag ${tag.id}: ${ruuviTagResponse.statusCode} - ${ruuviTagResponse.body}');
        }

        final ruuviTagData = jsonDecode(ruuviTagResponse.body);
        if (ruuviTagData['state'] != true) {
          throw Exception('Échec création RuuviTag ${tag.id}: ${ruuviTagData['message']}');
        }
        
        print('RuuviTag ${tag.id} créé avec succès');
      }

      // Succès - Redirection vers le dashboard
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cs.primary,
          content: const Text('Inscription réussie ! Bienvenue !'),
        ),
      );
      context.go('/dashboard');

    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cs.error,
          content: Text('Erreur: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Stepper
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(_stepTitles.length, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;
                
                return Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? Colors.green 
                              : isActive 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      if (index < _stepTitles.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted ? Colors.green : Colors.grey,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          
          // Titre de l'étape
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _stepTitles[_currentStep],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contenu de l'étape
          Expanded(
            child: _buildStepContent(),
          ),
          
          // Boutons de navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: _currentStep == 3 
                        ? (_isSubmitting ? 'Création...' : 'Créer le compte')
                        : 'Continuer',
                    onPressed: _canProceed() 
                        ? (_currentStep == 3 ? _submitRegistration : _nextStep)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildUserStep();
      case 1:
        return _buildCatStep();
      case 2:
        return _buildRuuviTagsStep();
      case 3:
        return _buildConfirmationStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildUserStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _userFormKey,
        child: Column(
          children: [
            const Icon(Icons.person, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'Prénom'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _emailFmt,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: _pwd,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              validator: _required,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _catFormKey,
        child: Column(
          children: [
            const Icon(Icons.pets, size: 64, color: Colors.orange),
            const SizedBox(height: 24),
            TextFormField(
              controller: _catName,
              decoration: const InputDecoration(labelText: 'Nom du chat'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _catBreed,
              decoration: const InputDecoration(labelText: 'Race'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                FocusScope.of(context).requestFocus(FocusNode());
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  _catBirthDate.text = picked.toIso8601String().substring(0, 10);
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _catBirthDate,
                  decoration: const InputDecoration(labelText: 'Date de naissance (YYYY-MM-DD)'),
                  validator: _required,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _catWeight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Poids (kg)'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _catColor,
              decoration: const InputDecoration(labelText: 'Couleur'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            // Sélecteur de sexe
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Sexe',
                // Supprimer la bordure personnalisée pour utiliser le style par défaut
              ),
              items: _genderOptions.entries.map((MapEntry<String, String> entry) {
                return DropdownMenuItem<String>(
                  value: entry.key, // Utiliser la clé (MALE/FEMALE)
                  child: Text(entry.value), // Afficher la valeur (Mâle/Femelle)
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner le sexe';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _catHealthNotes,
              decoration: const InputDecoration(labelText: 'Notes de santé'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuuviTagsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Scannez vos 3 capteurs RuuviTag',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vous devez scanner exactement 3 capteurs :\n'
            '• 1 Collier (pour suivre l\'activité)\n'
            '• 1 Environnement (température/humidité)\n'
            '• 1 Litière (surveillance d\'utilisation)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Liste des RuuviTags scannés
          if (_ruuviTags.isNotEmpty) ...[
            ...List.generate(_ruuviTags.length, (index) => 
              _buildRuuviTagCard(_ruuviTags[index], index)),
            const SizedBox(height: 16),
          ],
          
          // Bouton pour scanner
          if (_ruuviTags.length < 3)
            OutlinedButton.icon(
              onPressed: _scanRuuviTag,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text('Scanner un RuuviTag (${_ruuviTags.length}/3)'),
            ),
          
          if (_ruuviTags.length == 3)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Tous les capteurs ont été scannés !',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // En-tête avec icône et titre
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Votre compte est prêt !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifiez les informations ci-dessous avant de créer votre compte',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Section Utilisateur
          _buildInfoCard(
            title: 'Informations personnelles',
            icon: Icons.person,
            children: [
              _buildInfoRow('Nom complet', '${_firstName.text} ${_lastName.text}'),
              _buildInfoRow('Email', _email.text),
              _buildInfoRow('Téléphone', _phone.text),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Section Chat
          _buildInfoCard(
            title: 'Informations du chat',
            icon: Icons.pets,
            children: [
              _buildInfoRow('Nom', _catName.text),
              _buildInfoRow('Race', _catBreed.text),
              _buildInfoRow('Date de naissance', _catBirthDate.text),
              _buildInfoRow('Poids', '${_catWeight.text} kg'),
              _buildInfoRow('Couleur', _catColor.text),
              _buildInfoRow('Sexe', _selectedGender ?? 'N/A'), // Utiliser la valeur sélectionnée
              if (_catHealthNotes.text.isNotEmpty)
                _buildInfoRow('Notes de santé', _catHealthNotes.text),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Section Capteurs
          _buildInfoCard(
            title: 'Capteurs RuuviTag',
            icon: Icons.qr_code_scanner,
            children: [
              ..._ruuviTags.map((tag) => _buildRuuviTagInfo(tag)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Message de confirmation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline, 
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'En créant votre compte, vous acceptez que vos données soient utilisées pour le suivi de votre chat.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuuviTagCard(RuuviTag tag, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_getRuuviTagIcon(tag.type)),
        title: Text(tag.id),
        subtitle: Text(tag.type.displayName),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeRuuviTag(index),
        ),
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

  void _removeRuuviTag(int index) {
    setState(() {
      _ruuviTags.removeAt(index);
    });
  }

  Future<void> _scanRuuviTag() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          title: 'Scanner un RuuviTag',
          onQRCodeScanned: (ruuviTagId) {
            _navigateToTypeSelection(ruuviTagId);
          },
        ),
      ),
    );
  }

  Future<void> _navigateToTypeSelection(String ruuviTagId) async {
    // Récupérer les types déjà utilisés
    final usedTypes = _ruuviTags.map((tag) => tag.type).toList();
    
    final typeResult = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => SensorTypeSelectionScreen(
          ruuviTagId: ruuviTagId,
          usedTypes: usedTypes,
          onTypeSelected: (id, type) {
            Navigator.of(context).pop({
              'ruuviTagId': id,
              'type': type,
            });
          },
        ),
      ),
    );
    
    if (typeResult != null) {
      // Naviguer vers la configuration des seuils
      await _navigateToThresholdConfiguration(
        typeResult['ruuviTagId'],
        typeResult['type'],
      );
    }
  }

  Future<void> _navigateToThresholdConfiguration(String ruuviTagId, RuuviTagType type) async {
    try {
      print('Navigation vers la configuration des seuils pour $ruuviTagId');
      
      final thresholdResult = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => ThresholdConfigurationScreen(
            ruuviTagId: ruuviTagId,
            type: type,
            onThresholdsConfigured: (id, tagType, thresholds) {
              print('Callback recu: $id, $tagType, $thresholds');
              Navigator.of(context).pop({
                'ruuviTagId': id,
                'type': tagType,
                'thresholds': thresholds,
              });
            },
          ),
        ),
      );

      print('Resultat recu: $thresholdResult');
      
      if (thresholdResult != null) {
        print('Ajout du RuuviTag a la liste');
        setState(() {
          _ruuviTags.add(
            RuuviTag(
              id: thresholdResult['ruuviTagId'],
              type: thresholdResult['type'],
              alertThresholds: thresholdResult['thresholds'],
            ),
          );
        });
        print('Nombre de RuuviTags: ${_ruuviTags.length}');
      } else {
        print('Aucun resultat recu');
      }
    } catch (e) {
      print('Erreur dans _navigateToThresholdConfiguration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
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
              // Afficher la valeur lisible pour le sexe
              label == 'Sexe' ? _genderOptions[value] ?? value : value,
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

  Widget _buildRuuviTagInfo(RuuviTag tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
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
                  'ID: ${tag.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontFamily: 'monospace',
                  ),
                ),
                if (tag.alertThresholds != null) ...[
                  const SizedBox(height: 4),
                  ..._buildThresholdsInfo(tag.type, tag.alertThresholds!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildThresholdsInfo(RuuviTagType type, Map<String, dynamic> thresholds) {
    List<Widget> thresholdWidgets = [];
    
    switch (type) {
      case RuuviTagType.collar:
        if (thresholds['inactivityHours'] != null) {
          thresholdWidgets.add(
            Text(
              'Inactivité: ${thresholds['inactivityHours']}h',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        break;
        
      case RuuviTagType.environment:
        if (thresholds['temperatureMin'] != null && thresholds['temperatureMax'] != null) {
          thresholdWidgets.add(
            Text(
              'Température: ${thresholds['temperatureMin']}°C - ${thresholds['temperatureMax']}°C',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        if (thresholds['humidityMin'] != null && thresholds['humidityMax'] != null) {
          thresholdWidgets.add(
            Text(
              'Humidité: ${thresholds['humidityMin']}% - ${thresholds['humidityMax']}%',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        break;
        
      case RuuviTagType.litter:
        if (thresholds['dailyUsageMax'] != null) {
          thresholdWidgets.add(
            Text(
              'Usage max: ${thresholds['dailyUsageMax']} fois/jour',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        break;
    }
    
    return thresholdWidgets;
  }
} 