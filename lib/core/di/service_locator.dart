import 'package:GizmoHub/data/repositories/product/product_repository.dart';
import 'package:GizmoHub/data/repositories/promo/promo_repository.dart';
import 'package:GizmoHub/presentation/home/bloc/promo_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:GizmoHub/data/repositories/auth/auth_repository.dart';
import 'package:GizmoHub/domain/usecases/auth/sign_in_use_case.dart';
import 'package:GizmoHub/domain/usecases/auth/sign_up_use_case.dart';
import 'package:GizmoHub/presentation/auth/bloc/auth_cubit.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());

  sl.registerLazySingleton<SignInUseCase>(
    () => SignInUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<SignUpUseCase>(
    () => SignUpUseCase(sl<AuthRepository>()),
  );

  sl.registerFactory<AuthCubit>(
    () => AuthCubit(
      authRepository: sl<AuthRepository>(),
      signInUseCase: sl<SignInUseCase>(),
      signUpUseCase: sl<SignUpUseCase>(),
    ),
  );

  sl.registerLazySingleton<PromoRepository>(
        () => PromoRepository(),
  );

  sl.registerFactory<PromoCubit>(
        () => PromoCubit(
      promoRepository: sl<PromoRepository>(),
    ),
  );

  sl.registerLazySingleton<FirebaseFirestore>(
        () => FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'gizmohub',
        ),
  );

  sl.registerLazySingleton<FirebaseStorage>(
        () => FirebaseStorage.instance,
  );

  sl.registerLazySingleton<ProductRepository>(
        () => ProductRepository(),
  );


}
