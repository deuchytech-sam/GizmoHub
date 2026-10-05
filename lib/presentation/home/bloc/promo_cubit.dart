import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:GizmoHub/data/repositories/promo/promo_repository.dart';
import 'package:GizmoHub/presentation/home/bloc/promo_state.dart';

class PromoCubit extends Cubit<PromoState> {
  final PromoRepository _promoRepository;

  PromoCubit({required PromoRepository promoRepository})
      : _promoRepository = promoRepository,
        super(const PromoState());

  Future<void> loadPromo() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final promos = await _promoRepository.getActivePromo();
      emit(state.copyWith(promos: promos, isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}
