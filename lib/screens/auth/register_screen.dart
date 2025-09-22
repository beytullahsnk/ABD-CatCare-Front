import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_state.dart';
import '../../models/user.dart';
import '../../models/cat.dart';
import '../../models/ruuvi_tag.dart';
import '../../screens/widgets/primary_button.dart';
import '../../screens/scan/qr_scanner_screen.dart';
import '../../screens/scan/sensor_type_selection_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _catName = TextEditingController();
  String? _selectedImagePath;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _obscure = true;
  
  // Nouveaux champs pour les RuuviTags
  List<RuuviTag> _ruuviTags = [];

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _catName.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Requis' : null;
  String? _emailFmt(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requis';
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(v.trim()) ? null : 'Email invalide';
  }

  String? _pwd(String? v) =>
      (v == null || v.length < 8) ? '8 caractères minimum' : null;

  Future<void> _scanRuuviTag() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          title: 'Scanner un RuuviTag',
          onQRCodeScanned: (ruuviTagId) {
            // Ne pas fermer l'écran de scan ici, on va naviguer vers la sélection
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
          usedTypes: usedTypes, // Passer la liste des types utilisés
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
          id: typeResult['ruuviTagId'], 
          type: typeResult['type'],
        ));
      });
    }
  }

  void _removeRuuviTag(int index) {
    setState(() {
      _ruuviTags.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      // Log des données à envoyer
      final requestData = {
        'email': _email.text.trim(),
        'username': (_firstName.text.trim() + '.' + _lastName.text.trim()).replaceAll(' ', ''),
        'phoneNumber': _phone.text.trim(),
        'password': _password.text,
      };
      
      print('🔍 Données d\'inscription à envoyer: $requestData');
      print(' URL: http://localhost:3000/api/auth/register');
      
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );
      
      print('📡 Réponse reçue:');
      print('   Status Code: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Body: ${response.body}');
      
      final cs = Theme.of(context).colorScheme;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        print('✅ Données parsées: $data');
        if (data['state'] == true) {
          print('✅ Inscription réussie, connexion automatique...');
          await AuthState.instance.signInWithApiResponse(data['data'], rawEmail: _email.text.trim());
          if (!mounted) return;
          context.go('/dashboard');
        } else {
          print('❌ Échec inscription: ${data['message']}');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: cs.error,
              content: Text(data['message'] ?? "Echec de l'inscription"),
            ),
          );
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        if (!mounted) return;
        String errorMsg = "Erreur serveur (${response.statusCode})";
        try {
          final errBody = response.body;
          if (errBody.isNotEmpty) {
            errorMsg += '\n' + errBody;
            print('❌ Erreur API register: $errBody');
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cs.error,
            content: Text(errorMsg),
          ),
        );
      }
    } catch (e) {
      print('💥 Exception capturée: $e');
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cs.error,
          content: Text('Erreur: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 32,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        const SizedBox(height: 8),
        Text(
          'Ajouter une photo',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            fontSize: 14,
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Icon(Icons.pets,
                      size: 56, color: Theme.of(context).colorScheme.primary),
                ),
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
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _catName,
                  decoration: const InputDecoration(labelText: 'Nom du chat'),
                  validator: _required,
                ),
                const SizedBox(height: 20),
                
                // Section RuuviTags
                const Text(
                  'RuuviTags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scannez les QR codes de vos capteurs RuuviTag',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Liste des RuuviTags scannés
                if (_ruuviTags.isNotEmpty) ...[
                  ...List.generate(_ruuviTags.length, (index) => 
                    _buildRuuviTagCard(_ruuviTags[index], index)),
                  const SizedBox(height: 12),
                ],
                
                // Bouton pour scanner un nouveau RuuviTag
                OutlinedButton.icon(
                  onPressed: _scanRuuviTag,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scanner un RuuviTag'),
                ),
                const SizedBox(height: 12),
                
                Text('Photo du chat',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // TODO: Implémenter la sélection d'image
                    // Pour l'instant, on simule une sélection
                    setState(() {
                      _selectedImagePath = 'assets/images/cat_placeholder.png';
                    });
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: _selectedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.asset(
                              _selectedImagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder();
                              },
                            ),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    PrimaryButton(
                      text: _submitting ? 'Création...' : 'Créer et configurer',
                      onPressed: _submitting ? null : _submit,
                    ),
                    if (_submitting)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
