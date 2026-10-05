import 'package:firebase_auth/firebase_auth.dart';

import 'package:GizmoHub/data/repositories/auth/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<UserCredential> call({
    required String email,
    required String password,
  }) {
    return _authRepository.register(email: email, password: password);
  }
}
