import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_client.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? role;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.role,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? role,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier() : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(isLoading: true);
    final token = await _storage.read(key: 'jwt_token');
    final role = await _storage.read(key: 'user_role');
    
    if (token != null && role != null) {
      state = state.copyWith(isLoading: false, isAuthenticated: true, role: role);
    } else {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<void> loginCollector(String phone, String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await DioClient.instance.post(
        '/auth/login?phone_number=$phone&pin=$pin',
      );

      final token = response.data['access_token'];
      final returnedRole = response.data['role'];

      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(key: 'user_role', value: returnedRole);

      state = state.copyWith(isLoading: false, isAuthenticated: true, role: returnedRole);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed. Please check credentials.');
    }
  }

  Future<void> loginMock(String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await DioClient.instance.post(
        '/auth/login/google',
        data: {'mock_role': role},
      );

      final token = response.data['access_token'];
      final returnedRole = response.data['role'];

      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(key: 'user_role', value: returnedRole);

      state = state.copyWith(isLoading: false, isAuthenticated: true, role: returnedRole);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
