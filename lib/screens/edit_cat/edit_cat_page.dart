import 'package:abd_petcare/core/services/auth_state.dart';
import 'package:abd_petcare/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditCatPage extends StatefulWidget {
  const EditCatPage({super.key});

  @override
  State<EditCatPage> createState() => _EditCatPageState();
}

class _EditCatPageState extends State<EditCatPage> {
  Future<void> _fetchAndPrefillFirstCat() async {
    try {
      final data = await AuthService.instance.fetchUserWithCats();
      final cats = data?['extras']?['cats'] as List?;
      if (cats != null && cats.isNotEmpty) {
        final cat = Map<String, dynamic>.from(cats.first);
        setState(() {
          _catData = cat;
          _nameController.text = cat['name'] ?? '';
          _breedController.text = cat['breed'] ?? '';
          _birthDateController.text = cat['birthDate'] ?? '';
          _weightController.text = cat['weight']?.toString() ?? '';
          _colorController.text = cat['color'] ?? '';
          _genderController.text = cat['gender'] ?? '';
          _healthNotesController.text = cat['healthNotes'] ?? '';
          _userIdController.text = cat['userId'] ?? '';
          _sensorIdController.text = cat['sensorId'] ?? '';
          _statusController.text = cat['status'] ?? '';
        });
      }
    } catch (e) {
      print('Erreur fetchUserWithCats: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    if (_catData == null) {
      _fetchAndPrefillFirstCat();
    }
  }
  final _userIdController = TextEditingController();
  final _sensorIdController = TextEditingController();
  final _statusController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _genderController = TextEditingController();
  final _healthNotesController = TextEditingController();
  bool _submitting = false;

  Map<String, dynamic>? _catData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On récupère le chat à éditer depuis le Dashboard (via ModalRoute args ou Provider, ici args)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_catData != null && _catData?['id'] != null) {
      // Already loaded, do nothing
      return;
    }
    if (args is Map<String, dynamic> && args['id'] != null) {
      setState(() {
        _catData = args;
        _nameController.text = args['name'] ?? '';
        _breedController.text = args['breed'] ?? '';
        _birthDateController.text = args['birthDate'] ?? '';
        _weightController.text = args['weight']?.toString() ?? '';
        _colorController.text = args['color'] ?? '';
        _genderController.text = args['gender'] ?? '';
        _healthNotesController.text = args['healthNotes'] ?? '';
        _userIdController.text = args['userId'] ?? '';
        _sensorIdController.text = args['sensorId'] ?? '';
        _statusController.text = args['status'] ?? '';
  // ...no thresholds...
      });
    } else {
      _fetchAndPrefillFirstCat();
    }
  }

  @override
  void dispose() {
  _userIdController.dispose();
  _sensorIdController.dispose();
  _statusController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _genderController.dispose();
    _healthNotesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_catData == null || _catData?['id'] == null) {
      const errorMsg = 'Erreur: id du chat introuvable (données non chargées)';
      print(errorMsg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final updatedCat = {
      "name": _nameController.text.trim(),
      "breed": _breedController.text.trim(),
      "userId": AuthState.instance.user?["id"] ?? "",
      "sensorId": _sensorIdController.text.trim(),
      "birthDate": _birthDateController.text.trim(),
      "weight": double.tryParse(_weightController.text.trim()),
      "color": _colorController.text.trim(),
      "gender": _genderController.text.trim(),
      "healthNotes": _healthNotesController.text.trim(),
      "status": _statusController.text.trim(),
    };
    // print updatedCat
    print('DEBUG: updatedCat = [32m${updatedCat.toString()}[0m');
    final catId = _catData?['id'];
    final token = AuthState.instance.refreshToken;
    http
        .put(
          Uri.parse('http://10.0.2.2:3000/cats/$catId'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(updatedCat),
        )
        .then((response) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat modifié avec succès !')),
        );
        setState(() {
          _submitting = false;
        });
        print('DEBUG: Après sauvegarde, _catData = [32m${_catData.toString()}[0m');
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.of(context).maybePop();
          });
        }
      } else {
        final errorMsg = 'Erreur API PUT /cats/$catId: ${response.statusCode} - ${response.body}';
        print(errorMsg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${response.body}\n$errorMsg')),
        );
        setState(() => _submitting = false);
      }
    }).catchError((e) {
      final errorMsg = 'Erreur réseau PUT /cats/$catId: $e';
      print(errorMsg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau: $e\n$errorMsg')),
      );
      setState(() => _submitting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le chat')),
      body: SafeArea(
        child: (_catData == null || _catData?['id'] == null)
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Informations générales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Divider(),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nom'),
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _breedController,
                        decoration: const InputDecoration(labelText: 'Race'),
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _birthDateController.text.isNotEmpty
                                ? DateTime.tryParse(_birthDateController.text) ?? DateTime.now()
                                : DateTime.now(),
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
                            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(labelText: 'Poids (kg)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(labelText: 'Couleur'),
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _genderController,
                        decoration: const InputDecoration(labelText: 'Sexe'),
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _healthNotesController,
                        decoration: const InputDecoration(labelText: 'Notes de santé'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      // ...threshold fields removed...
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_submitting || _catData == null || _catData?['id'] == null) ? null : _submit,
              child: Text(_submitting ? 'Sauvegarde...' : 'Sauvegarder'),
            ),
          ),
        ),
      ),
    );
  }
}
