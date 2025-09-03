import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // Base URL de l'API Gateway (modifiable)
  String baseUrl = 'http://10.0.2.2:3000';
  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    final uri = Uri.parse('$baseUrl$path');
    final h = {...defaultHeaders, if (headers != null) ...headers};
    return http.get(uri, headers: h);
  }

  Future<http.Response> post(String path, Object? body,
      {Map<String, String>? headers}) {
    final uri = Uri.parse('$baseUrl$path');
    final h = {...defaultHeaders, if (headers != null) ...headers};
    final b = body == null ? null : jsonEncode(body);
    return http.post(uri, headers: h, body: b);
  }

  Future<http.Response> put(String path, Object? body,
      {Map<String, String>? headers}) {
    final uri = Uri.parse('$baseUrl$path');
    final h = {...defaultHeaders, if (headers != null) ...headers};
    final b = body == null ? null : jsonEncode(body);
    return http.put(uri, headers: h, body: b);
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) {
    final uri = Uri.parse('$baseUrl$path');
    final h = {...defaultHeaders, if (headers != null) ...headers};
    return http.delete(uri, headers: h);
  }
}
