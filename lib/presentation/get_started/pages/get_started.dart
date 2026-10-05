import 'package:GizmoHub/common/widgets/app_button/basic_app_button.dart';
import 'package:GizmoHub/core/configs/assets/app_images.dart';
import 'package:GizmoHub/core/configs/assets/app_vectors.dart';
import 'package:GizmoHub/presentation/auth/pages/sign_in.dart';
import 'package:GizmoHub/presentation/onboarding/bloc/onboarding_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 40,
              horizontal: 40,
            ),
            decoration: BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage(AppImages.introBG)
                )
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 40,
              horizontal: 40,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SvgPicture.asset(
                      AppVectors.logo,
                      height: 200,
                  ),
                ),

                Spacer(),

                Text("You want Authentic, here you go!",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 20,),

                Text("Find it here, buy it now!",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xffF2F2F2),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 21,),
                BasicAppButton(
                    onPressed: () {
                      context.read<OnboardingCubit>().completeOnboarding();

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignInPage(),
                        ),
                      );
                    },
                    title: 'Get Started')
              ],
            ),
          ),

        ],
      ),
    );
  }
}
