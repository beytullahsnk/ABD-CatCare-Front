import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_state.dart';
import '../../core/services/api_provider.dart';
import '../../models/user.dart';
import '../../models/cat.dart';
import '../../screens/widgets/primary_button.dart';

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
  final _api = ApiProvider.instance.get();
  bool _submitting = false;
  bool _obscure = true;

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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final user = User(
      id: UniqueKey().toString(),
      name: '${_firstName.text.trim()} ${_lastName.text.trim()}',
      email: _email.text.trim(),
    );
    final cat = Cat(
      id: UniqueKey().toString(),
      name: _catName.text.trim(),
      ageMonths: 0,
      breed: null,
    );

    final ok = await _api.register(user);
    setState(() => _submitting = false);
    if (ok) {
      await AuthState.instance.setLoggedIn(true);
      if (!mounted) return;
      context.go('/settings/notifications');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Echec de l'inscription")),
      );
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
