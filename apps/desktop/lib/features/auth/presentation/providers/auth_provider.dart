import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/engine/engine_supervisor.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final engineState = ref.watch(engineSupervisorProvider);
  return engineState.maybeWhen(
    data: (engineData) {
      if (engineData.state == EngineState.healthy) {
        return AuthRepository(
          dio: Dio(),
          storage: const FlutterSecureStorage(),
          engineData: engineData,
        );
      }
      return null;
    },
    orElse: () => null,
  );
});

class AuthNotifier extends AsyncNotifier<AuthState> {
  late FlutterSecureStorage _storage;

  @override
  Future<AuthState> build() async {
    _storage = const FlutterSecureStorage();
    final userId = await _storage.read(key: 'user_id');
    if (userId != null) {
      // Typically, we might verify token or fetch user info here.
      // For now, assume authenticated if userId is present.
      return AuthState.authenticated(userId: userId, displayName: 'User');
    }
    return const AuthState.unauthenticated();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncData(AuthState.loading());
    try {
      final repo = ref.read(authRepositoryProvider);
      if (repo == null) throw Exception('Engine not ready');

      final result = await repo.login(email, password);
      state = AsyncData(
        AuthState.authenticated(
          userId: result['user_id'],
          displayName: result['display_name'],
        ),
      );
    } catch (e) {
      state = AsyncData(AuthState.error(message: e.toString()));
      // Reset state after a delay or let UI handle it
      await Future.delayed(const Duration(seconds: 3));
      state = const AsyncData(AuthState.unauthenticated());
    }
  }

  Future<void> logout() async {
    state = const AsyncData(AuthState.loading());
    try {
      final repo = ref.read(authRepositoryProvider);
      if (repo != null) {
        await repo.logout();
      } else {
        await _storage.delete(key: 'user_id');
      }
      state = const AsyncData(AuthState.unauthenticated());
    } catch (e) {
      state = AsyncData(AuthState.error(message: e.toString()));
    }
  }

  Future<void> lock() async {
    final currentState = state.value;
    if (currentState is! AuthState) return;

    currentState.maybeWhen(
      authenticated: (userId, _) async {
        state = const AsyncData(AuthState.loading());
        try {
          final repo = ref.read(authRepositoryProvider);
          if (repo != null) await repo.lock();
          state = AsyncData(AuthState.locked(userId: userId));
        } catch (e) {
          state = AsyncData(AuthState.error(message: e.toString()));
        }
      },
      orElse: () {},
    );
  }

  Future<void> unlock(String password) async {
    final currentState = state.value;
    if (currentState is! AuthState) return;

    currentState.maybeWhen(
      locked: (userId) async {
        state = const AsyncData(AuthState.loading());
        try {
          final repo = ref.read(authRepositoryProvider);
          if (repo == null) throw Exception('Engine not ready');
          await repo.unlock(password);
          // Assuming unlock returns display name or we fetch it. Stub for now.
          state = AsyncData(
            AuthState.authenticated(userId: userId, displayName: 'User'),
          );
        } catch (e) {
          state = AsyncData(AuthState.error(message: e.toString()));
          await Future.delayed(const Duration(seconds: 3));
          state = AsyncData(AuthState.locked(userId: userId));
        }
      },
      orElse: () {},
    );
  }

  Future<void> recover(List<String> phrase) async {
    state = const AsyncData(AuthState.loading());
    try {
      final repo = ref.read(authRepositoryProvider);
      if (repo == null) throw Exception('Engine not ready');
      await repo.recover(phrase);
      state = const AsyncData(AuthState.unauthenticated());
    } catch (e) {
      state = AsyncData(AuthState.error(message: e.toString()));
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
