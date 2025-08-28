import 'mock_api_service.dart';
import 'real_api_service.dart';

class ApiProvider {
  ApiProvider._();
  static final ApiProvider instance = ApiProvider._();

  /// Switch here for development: true => use mock, false => use real
  bool useMock = true;

  dynamic get() {
    if (useMock) return MockApiService();
    return RealApiService.instance;
  }
}
