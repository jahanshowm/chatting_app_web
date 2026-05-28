import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/config/app_env.dart';
import 'package:randomchat_admin/core/network/api_client.dart';
import 'package:randomchat_admin/core/network/api_exception.dart';
import 'package:randomchat_admin/core/network/token_storage.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';

class AuthState {
  const AuthState({this.admin, this.loading = false, this.error});

  final AdminUser? admin;
  final bool loading;
  final String? error;

  bool get isAuthenticated => admin != null;

  AuthState copyWith({AdminUser? admin, bool? loading, String? error}) => AuthState(
        admin: admin ?? this.admin,
        loading: loading ?? this.loading,
        error: error,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  late final TokenStorage _storage;
  late final AdminApi _api;

  @override
  AuthState build() {
    _storage = ref.read(tokenStorageProvider);
    _api = ref.read(adminApiProvider);
    _bootstrap();
    return const AuthState(loading: true);
  }

  Future<void> _bootstrap() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      state = const AuthState();
      return;
    }
    try {
      final admin = await _api.me();
      state = AuthState(admin: admin);
    } catch (_) {
      await _storage.clear();
      state = const AuthState();
    }
  }

  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.login(
        username: username,
        password: password,
        rememberMe: rememberMe,
      );
      final token = result['access_token'] as String;
      await _storage.saveToken(token);
      final adminJson = result['admin'] as Map<String, dynamic>;
      state = AuthState(admin: AdminUser.fromJson(adminJson));
      return true;
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : '로그인 중 오류가 발생했습니다. API 주소(${AppEnv.apiBaseUrl})와 백엔드 실행 여부를 확인해주세요.';
      state = AuthState(error: message);
      return false;
    } finally {
      if (state.loading) {
        state = state.copyWith(loading: false);
      }
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
