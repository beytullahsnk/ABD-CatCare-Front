import 'package:flutter/material.dart';
import 'package:abd_petcare/core/services/auth_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../../models/ruuvi_tag.dart';
import '../scan/qr_scanner_screen.dart';
import '../scan/sensor_type_selection_screen.dart';
import '../scan/threshold_configuration_screen.dart'; 
import '../widgets/primary_button.dart';

class AddCatStepperPage extends StatefulWidget {
  const AddCatStepperPage({super.key});

  @override
  State<AddCatStepperPage> createState() => _AddCatStepperPageState();
}

class _AddCatStepperPageState extends State<AddCatStepperPage> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Données du chat
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _healthNotesController = TextEditingController();
  final GlobalKey<FormState> _catFormKey = GlobalKey<FormState>();
  String? _selectedGender;

  // Données des RuuviTags
  List<RuuviTag> _ruuviTags = [];

  final List<String> _stepTitles = [
    'Informations du chat',
    'Configuration des capteurs',
    'Confirmation',
  ];

  // Options pour le sexe
  final Map<String, String> _genderOptions = {
    'MALE': 'Mâle',
    'FEMALE': 'Femelle',
  };

  @override
  void initState() {
    super.initState();
    // Ajouter des listeners pour déclencher setState
    _nameController.addListener(_onFieldChanged);
    _breedController.addListener(_onFieldChanged);
    _birthDateController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _colorController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      // Déclencher un rebuild pour mettre à jour le bouton
    });
  }

  @override
  void dispose() {
    // Supprimer les listeners
    _nameController.removeListener(_onFieldChanged);
    _breedController.removeListener(_onFieldChanged);
    _birthDateController.removeListener(_onFieldChanged);
    _weightController.removeListener(_onFieldChanged);
    _colorController.removeListener(_onFieldChanged);
    
    _nameController.dispose();
    _breedController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _healthNotesController.dispose();
    super.dispose();
  }

  // Validateurs
  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Requis' : null;

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty &&
               _breedController.text.trim().isNotEmpty &&
               _birthDateController.text.trim().isNotEmpty &&
               _weightController.text.trim().isNotEmpty &&
               _colorController.text.trim().isNotEmpty &&
               _selectedGender != null;
      case 1:
        return _ruuviTags.length == 3;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceed()) {
      bool isValid = false;
      switch (_currentStep) {
        case 0:
          isValid = _catFormKey.currentState?.validate() ?? false;
          break;
        case 1:
        case 2:
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

  Future<void> _submitCat() async {
    setState(() => _isSubmitting = true);
    
    try {
      final cs = Theme.of(context).colorScheme;
      
      // Étape 1: Créer le chat
      print('Étape 1: Création du chat...');
      final userId = AuthState.instance.user?["id"] ?? "";
      final catResponse = await http.post(
        Uri.parse('http://localhost:3000/api/cats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'breed': _breedController.text.trim(),
          'userId': userId,
          'birthDate': _birthDateController.text.trim(),
          'weight': double.tryParse(_weightController.text.trim()),
          'color': _colorController.text.trim(),
          'gender': _selectedGender,
          'healthNotes': _healthNotesController.text.trim(),
        }),
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

      // Étape 2: Créer les RuuviTags
      print('Étape 2: Création des RuuviTags...');
      for (int i = 0; i < _ruuviTags.length; i++) {
        final tag = _ruuviTags[i];
        print('Création du RuuviTag ${i + 1}/${_ruuviTags.length}: ${tag.id}');
        
        final ruuviTagResponse = await http.post(
          Uri.parse('http://localhost:3000/api/ruuvitags'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AuthState.instance.accessToken}',
          },
          body: jsonEncode({
            'ruuviTagId': tag.id,
            'type': tag.type.value,
            'catIds': [catId],
            'alertThresholds': tag.alertThresholds,
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
          content: const Text('Chat ajouté avec succès !'),
        ),
      );
      context.go('/dashboard');

    } catch (e) {
      print('Erreur lors de l\'ajout du chat: $e');
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
        title: const Text('Ajouter un chat'),
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
                    text: _currentStep == 2 
                        ? (_isSubmitting ? 'Ajout...' : 'Ajouter le chat')
                        : 'Continuer',
                    onPressed: _canProceed() 
                        ? (_currentStep == 2 ? _submitCat : _nextStep)
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
        return _buildCatStep();
      case 1:
        return _buildRuuviTagsStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return const SizedBox();
    }
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
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom du chat'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _breedController,
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
                  _birthDateController.text = picked.toIso8601String().substring(0, 10);
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _birthDateController,
                  decoration: const InputDecoration(labelText: 'Date de naissance (YYYY-MM-DD)'),
                  validator: _required,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Poids (kg)'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(labelText: 'Couleur'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            // Sélecteur de sexe
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Sexe',
              ),
              items: _genderOptions.entries.map((MapEntry<String, String> entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
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
              controller: _healthNotesController,
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
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Confirmation de l\'ajout',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Résumé chat
          _buildInfoCard(
            title: 'Informations du chat',
            icon: Icons.pets,
            children: [
              _buildInfoRow('Nom', _nameController.text),
              _buildInfoRow('Race', _breedController.text),
              _buildInfoRow('Date de naissance', _birthDateController.text),
              _buildInfoRow('Poids', '${_weightController.text} kg'),
              _buildInfoRow('Couleur', _colorController.text),
              _buildInfoRow('Sexe', _genderOptions[_selectedGender] ?? ''),
              if (_healthNotesController.text.isNotEmpty)
                _buildInfoRow('Notes de santé', _healthNotesController.text),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Résumé capteurs
          _buildInfoCard(
            title: 'Capteurs RuuviTag',
            icon: Icons.qr_code_scanner,
            children: [
              ..._ruuviTags.map((tag) => _buildRuuviTagInfo(tag)),
            ],
          ),
        ],
      ),
    );
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
    final thresholdResult = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => ThresholdConfigurationScreen(
          ruuviTagId: ruuviTagId,
          type: type,
          onThresholdsConfigured: (id, tagType, thresholds) {
            Navigator.of(context).pop({
              'ruuviTagId': id,
              'type': tagType,
              'thresholds': thresholds,
            });
          },
        ),
      ),
    );

    if (thresholdResult != null) {
      setState(() {
        _ruuviTags.add(
          RuuviTag(
            id: thresholdResult['ruuviTagId'],
            type: thresholdResult['type'],
            alertThresholds: thresholdResult['thresholds'],
          ),
        );
      });
    }
  }
} 