import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orbytis_atlas/features/auth/errors/auth_exception.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_event.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_state.dart';
import 'package:orbytis_atlas/features/auth/repositories/auth_repository.dart';

final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onSessionChecked(
    AuthSessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final hasStoredSession = await _authRepository.hasStoredSession();

      if (hasStoredSession) {
        emit(const AuthAuthenticated());
        return;
      }

      emit(const AuthUnauthenticated());
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      emit(AuthAuthenticated(user: response.user));
    } on AuthException catch (error) {
      emit(AuthFailure(error.message));
    } catch (_) {
      emit(const AuthFailure('Não foi possível realizar Login.'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.logout();

      emit(const AuthUnauthenticated());
    } catch (_) {
      emit(const AuthFailure('Não foi possível encerrar a sessão.'));
    }
  }
}
