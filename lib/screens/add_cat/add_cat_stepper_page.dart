import 'package:flutter/material.dart';
import 'package:abd_petcare/core/services/auth_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../../models/ruuvi_tag.dart';
import '../scan/qr_scanner_screen.dart';
import '../scan/sensor_type_selection_screen.dart';
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
      final userId = AuthState.instance.user?["id"] ?? "";
      final catData = {
        "name": _nameController.text.trim(),
        "breed": _breedController.text.trim(),
        "userId": userId,
        "sensorId": "63ec36e6-5243-41d6-945c-1792f79255ae",
        "status": "ACTIVE",
        "birthDate": _birthDateController.text.trim(),
        "weight": double.tryParse(_weightController.text.trim()),
        "color": _colorController.text.trim(),
        "gender": _selectedGender,
        "microchipId": "123456789012345",
        "healthNotes": _healthNotesController.text.trim(),
        "ruuviTags": _ruuviTags.map((tag) => tag.toJson()).toList(),
      };

      final token = AuthState.instance.refreshToken;
      final response = await http.post(
        Uri.parse('http://localhost:3000/cats'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(catData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat ajouté avec succès !')),
        );
        context.go('/dashboard');
      } else {
        if (!mounted) return;
        print('Erreur API: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print('Erreur réseau: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau: $e')),
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
        title: Text(tag.ruuviTagId),
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
      setState(() {
        _ruuviTags.add(RuuviTag(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          ruuviTagId: typeResult['ruuviTagId'],
          type: typeResult['type'],
        ));
      });
    }
  }
} 