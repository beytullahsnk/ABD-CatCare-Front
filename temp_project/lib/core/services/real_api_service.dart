import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class RealApiService {
  RealApiService._();
  static final RealApiService instance = RealApiService._();

  Future<bool> login(String identifier, String password) async {
    final body = {'identifier': identifier, 'password': password};
    final resp = await ApiClient.instance.post('/auth/login', body);
    return resp.statusCode == 200;
  }

  Future<bool> register(Map<String, dynamic> user) async {
    final resp = await ApiClient.instance.post('/users', user);
    return resp.statusCode == 201 || resp.statusCode == 200;
  }

  Future<Map<String, dynamic>?> fetchDashboard() async {
    final resp = await ApiClient.instance.get('/sensors/stats/');
    if (resp.statusCode == 200)
      return jsonDecode(resp.body) as Map<String, dynamic>;
    return null;
  }
}
