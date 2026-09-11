import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_client.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? role;
  final String? userId;
  final String? displayName;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.role,
    this.userId,
    this.displayName,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? role,
    String? userId,
    String? displayName,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
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
    final userId = await _storage.read(key: 'user_id');
    final displayName = await _storage.read(key: 'display_name');

    if (token != null && role != null) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: role,
        userId: userId,
        displayName: displayName,
      );
    } else {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    await _storage.write(key: 'jwt_token', value: data['access_token']);
    await _storage.write(key: 'user_role', value: data['role']);
    await _storage.write(key: 'user_id', value: data['user_id']);
    await _storage.write(key: 'display_name', value: data['display_name'] ?? '');
  }

  /// Collector: login with phone + PIN
  Future<void> loginCollector(String phone, String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await DioClient.instance.post(
        '/auth/login/collector',
        data: {'phone_number': phone, 'pin': pin},
      );
      await _saveSession(response.data);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: response.data['role'],
        userId: response.data['user_id'],
        displayName: response.data['display_name'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e, 'Login failed. Check your phone number and PIN.'),
      );
    }
  }

  /// Recycler: login with email + password
  Future<void> loginRecycler(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await DioClient.instance.post(
        '/auth/login/recycler',
        data: {'email': email, 'password': password},
      );
      await _saveSession(response.data);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: response.data['role'],
        userId: response.data['user_id'],
        displayName: response.data['display_name'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e, 'Login failed. Check your email and password.'),
      );
    }
  }

  /// Admin: login with email + password
  Future<void> loginAdmin(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await DioClient.instance.post(
        '/auth/login/admin',
        data: {'email': email, 'password': password},
      );
      await _saveSession(response.data);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: response.data['role'],
        userId: response.data['user_id'],
        displayName: response.data['display_name'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e, 'Invalid admin credentials.'),
      );
    }
  }

  /// Register collector (auto-login on success)
  Future<bool> registerCollector(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await DioClient.instance.post(
        '/auth/register/collector',
        data: data,
      );
      await _saveSession(response.data);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: 'collector',
        userId: response.data['user_id'],
        displayName: response.data['display_name'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e, 'Registration failed. Please try again.'),
      );
      return false;
    }
  }

  /// Register recycler (pending approval — does NOT auto-login)
  Future<bool> registerRecycler(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await DioClient.instance.post('/auth/register/recycler', data: data);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e, 'Registration failed. Please try again.'),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'display_name');
    state = AuthState();
  }

  String _extractError(Object e, String fallback) {
    final str = e.toString();
    if (str.contains('pending')) return 'Your account is pending admin approval.';
    if (str.contains('rejected')) return 'Your account has been rejected. Contact admin.';
    if (str.contains('already registered')) return 'This phone/email is already registered.';
    if (str.contains('401') || str.contains('Invalid')) return fallback;
    return fallback;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
