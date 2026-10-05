import 'package:GizmoHub/data/models/promo/promo_model.dart';

class PromoState {
  final List<PromoModel> promo;
  final bool isLoading;
  final String? errorMessage;

  const PromoState({
    this.promo = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PromoState copyWith({
    List<PromoModel>? promos,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PromoState(
      promo: promos ?? promo,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
