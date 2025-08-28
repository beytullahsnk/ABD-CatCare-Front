import 'package:flutter/material.dart';

/// SnackBar utilitaire pour succès/erreur
void showAppSnack(BuildContext context, String message, {bool success = true}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: success ? cs.secondary : cs.error,
      content: Text(message),
      duration: const Duration(seconds: 2),
    ),
  );
}
