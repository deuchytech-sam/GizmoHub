import 'package:GizmoHub/core/configs/assets/app_images.dart';
import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/presentation/auth/pages/sign_in.dart';
import 'package:GizmoHub/presentation/onboarding/bloc/onboarding_cubit.dart';
import 'package:GizmoHub/presentation/onboarding/pages/onboarding_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState(){
    super.initState();
    redirect();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Image.asset(
            AppImages.gifLogo,
            height: 250
        ),
      ),
    );
  }

  Future<void> redirect() async {
    await Future.delayed(
      const Duration(milliseconds: 4900),
    );

    if (!mounted) return;

    final hasSeenOnboarding =
        context.read<OnboardingCubit>().state;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (hasSeenOnboarding) {
            return const SignInPage();
          }

          return const OnboardingScreens();
        },
      ),
    );
  }
}
