typedef Validator = String? Function(String? value);

class Validators {
  Validators._();

  static String? required(String? value, {String message = 'Champ requis'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value, {String message = 'Email invalide'}) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return message;
    return null;
  }

  static String? minLength(String? value, int min,
      {String message = 'Trop court'}) {
    if (value == null) return null;
    if (value.length < min) return message;
    return null;
  }
}
