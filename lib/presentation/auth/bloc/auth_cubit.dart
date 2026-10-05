import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:GizmoHub/data/repositories/auth/auth_repository.dart';
import 'package:GizmoHub/domain/usecases/auth/sign_in_use_case.dart';
import 'package:GizmoHub/domain/usecases/auth/sign_up_use_case.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthState {
  static const _unset = Object();

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Object? errorMessage = _unset,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;

  AuthCubit({
    required AuthRepository authRepository,
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
  }) : _authRepository = authRepository,
       _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       super(const AuthState());

  Future<void> register({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final userCredential = await _signUpUseCase(
        email: email,
        password: password,
      );

      emit(
        state.copyWith(
          status: AuthStatus.success,
          user: userCredential.user,
          errorMessage: null,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _getFirebaseErrorMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final userCredential = await _signInUseCase(
        email: email,
        password: password,
      );

      emit(
        state.copyWith(
          status: AuthStatus.success,
          user: userCredential.user,
          errorMessage: null,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _getFirebaseErrorMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();

      emit(const AuthState(status: AuthStatus.initial));
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Unable to log out. Please try again.',
        ),
      );
    }
  }

  Future<void> resetPassword({required String email}) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      await _authRepository.sendPasswordResetEmail(email: email);

      emit(const AuthState(status: AuthStatus.success));
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _getFirebaseErrorMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Your password is too weak.';

      case 'user-not-found':
        return 'No account was found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
