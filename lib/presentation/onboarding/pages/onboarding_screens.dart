import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/data/models/onboarding/onboard_items.dart';
import 'package:GizmoHub/presentation/auth/pages/sign_in.dart';
import 'package:GizmoHub/presentation/get_started/pages/get_started.dart';
import 'package:GizmoHub/presentation/onboarding/bloc/onboarding_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreens extends StatefulWidget {
  const OnboardingScreens({super.key});

  @override
  State<OnboardingScreens> createState() => _OnboardingScreensState();
}

class _OnboardingScreensState extends State<OnboardingScreens> {
  late final isDark = Theme.of(context).brightness == Brightness.dark;
  final List<OnboardItems> _pages = [
    OnboardItems(
      title: 'Discover Amazing Products',
      subTitle: 'Find everything you need in one place.',
      lottieUrl: 'lib/assets/lottie/onboarding_1.json',
    ),
    OnboardItems(
      title: 'Shop With Ease',
      subTitle: 'Enjoy a simple and convenient shopping experience.',
      lottieUrl: 'lib/assets/lottie/onboarding_2.json',
    ),
    OnboardItems(
      title: 'Get Your Products',
      subTitle: 'Order your favorite products and get them delivered.',
      lottieUrl: 'lib/assets/lottie/onboarding_3.json',
    ),
  ];

  final PageController _pageController = PageController();

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: '${_currentPage + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '/${_pages.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<OnboardingCubit>().completeOnboarding();

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignInPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Lottie.asset(
                            page.lottieUrl,
                            fit: BoxFit.contain,
                          ),
                        ),

                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          page.subTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                10,
                16,
                20,
              ),
              child: Row(
                children: [
                  // Prev
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(
                            milliseconds: 300,
                          ),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        'Prev',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 60,
                    ),

                  const Spacer(),

                  // Page indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _pages.length,
                          (index) {
                        final bool isActive =
                            index == _currentPage;

                        return AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 250,
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 3,
                          ),
                          height: 5,
                          width: isActive ? 22 : 5,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  // Next
                  TextButton(
                    onPressed: () {
                      if (_currentPage <
                          _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(
                            milliseconds: 300,
                          ),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context)=> GetStartedPage())
                        );
                      }
                    },
                    child: Text(
                      _currentPage ==
                          _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}