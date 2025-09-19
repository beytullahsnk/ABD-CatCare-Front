import 'mock_api_service.dart';
import 'api_service.dart';

class ApiProvider {
  ApiProvider._();
  static final ApiProvider instance = ApiProvider._();

  /// Switch here for development: true => use mock, false => use real
  bool useMock = false;

  dynamic get() {
    if (useMock) return MockApiService();
    return RealApiService.instance;
  }
}
