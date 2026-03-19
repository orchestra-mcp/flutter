import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/auth/token_storage.dart';
import 'package:orchestra/core/auth/user_model.dart';
import 'package:orchestra/core/firebase/analytics_service.dart';
import 'package:orchestra/core/firebase/crashlytics_service.dart';
import 'package:orchestra/core/firebase/messaging_service.dart';

class AuthRepository {
  AuthRepository({required this.client, required this.tokenStorage});

  final ApiClient client;
  final TokenStorage tokenStorage;

  Future<User> login(String email, String password) async {
    final body = await client.login({'email': email, 'password': password});
    await _saveToken(body);
    return User.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<User> register(String email, String password, String name) async {
    final body = await client.register({
      'email': email,
      'password': password,
      'name': name,
    });
    await _saveToken(body);
    return User.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<User> getMe() async {
    final body = await client.getProfile();
    return User.fromJson(body);
  }

  Future<void> logout() async {
    await tokenStorage.clearTokens();
    await MessagingService.unsubscribeAll();
  }

  /// Save JWT from backend response. Backend sends `token` (single JWT, no
  /// refresh token). We store it as the access token; refresh is optional.
  Future<void> _saveToken(Map<String, dynamic> body) async {
    final token = (body['access_token'] ?? body['token'] ?? '') as String;
    final refresh = (body['refresh_token'] ?? '') as String;
    await tokenStorage.saveTokens(accessToken: token, refreshToken: refresh);
    final user = User.fromJson(body['user'] as Map<String, dynamic>);
    await Future.wait<void>([
      AnalyticsService.logLogin(method: 'password'),
      CrashlyticsService.setUser(user.id),
    ]);
  }
}
