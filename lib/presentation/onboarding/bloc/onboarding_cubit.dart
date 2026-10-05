import 'package:hydrated_bloc/hydrated_bloc.dart';

class OnboardingCubit extends HydratedCubit<bool> {
  OnboardingCubit() : super(false);

  void completeOnboarding() {
    emit(true);
  }

  void resetOnboarding() {
    emit(false);
  }

  @override
  bool? fromJson(Map<String, dynamic> json) {
    return json['hasSeenOnboarding'] as bool? ?? false;
  }

  @override
  Map<String, dynamic>? toJson(bool state) {
    return {
      'hasSeenOnboarding': state,
    };
  }
}