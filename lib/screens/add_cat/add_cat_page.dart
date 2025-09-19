import 'package:abd_petcare/core/services/api_client.dart';
import 'package:abd_petcare/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:abd_petcare/core/services/auth_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';

class AddCatPage extends StatefulWidget {
  const AddCatPage({super.key});

  @override
  State<AddCatPage> createState() => _AddCatPageState();
}

class _AddCatPageState extends State<AddCatPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _genderController = TextEditingController();
  final _healthNotesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _genderController.dispose();
    _healthNotesController.dispose();
    super.dispose();
  }

  Future<void> _postCat(Map<String, dynamic> catData) async {
    try {
      final response = await ApiClient.instance.post(
        '/cats',
        catData,
        headers: AuthService.instance.authHeader,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat ajouté avec succès !')),
        );
        context.pop();
      } else {
        print('Erreur API: ${response.statusCode} - ${response.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${response.body}')),
        );
      }
    } catch (e) {
      print('Erreur réseau: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
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
      "gender": _genderController.text.trim(),
      "microchipId": "123456789012345",
      "healthNotes": _healthNotesController.text.trim(),
    };
    print('Cat to add: $catData');
    _postCat(catData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un chat')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      _birthDateController.text =
                          picked.toIso8601String().substring(0, 10);
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _birthDateController,
                      decoration: const InputDecoration(
                          labelText: 'Date de naissance (YYYY-MM-DD)'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requis' : null,
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
                  decoration:
                      const InputDecoration(labelText: 'Notes de santé'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
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
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Ajout...' : 'Ajouter le chat'),
            ),
          ),
        ),
      ),
    );
  }
}
