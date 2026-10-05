import 'package:firebase_auth/firebase_auth.dart';

import 'package:GizmoHub/data/repositories/auth/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<UserCredential> call({
    required String email,
    required String password,
  }) {
    return _authRepository.login(email: email, password: password);
  }
}
