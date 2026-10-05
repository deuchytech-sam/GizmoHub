import 'package:GizmoHub/common/widgets/app_button/basic_app_button.dart';
import 'package:GizmoHub/core/configs/assets/app_vectors.dart';
import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/presentation/auth/bloc/auth_cubit.dart';
import 'package:GizmoHub/presentation/auth/pages/sign_in.dart';
import 'package:GizmoHub/presentation/home/pages/home_page.dart';
import 'package:GizmoHub/presentation/main/main_shell.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.success) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainShell()),
            (route) => false,
          );
        } else if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Unable to create account.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _signingText(),
                SizedBox(height: 50),
                _emailField(context),
                SizedBox(height: 20),
                _passwordField(context),
                SizedBox(height: 20),
                _confirmPasswordField(context),
                SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: 'By clicking the ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: 'Register',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Register action
                          },
                      ),
                      const TextSpan(
                        text: ' button, you agree to the public offer',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                _signUpButton(),
                SizedBox(height: 50),
                Text('- OR Continue with -'),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(
                      icon: AppVectors.google,
                      onTap: () {
                        // Google login
                      },
                    ),
                    const SizedBox(width: 16),
                    _socialButton(
                      icon: AppVectors.apple,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                      onTap: () {
                        // Apple login
                      },
                    ),
                    const SizedBox(width: 16),
                    _socialButton(
                      icon: AppVectors.facebook,
                      onTap: () {
                        // Facebook login
                      },
                    ),
                  ],
                ),
                _signInText(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _signingText() {
    return Text(
      "Create an account",
      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 36),
    );
  }

  Widget _emailField(BuildContext context) {
    return TextField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: "Username or Email",
        prefixIcon: Icon(Icons.person),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _passwordField(BuildContext context) {
    return TextField(
      controller: _password,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }

  Widget _confirmPasswordField(BuildContext context) {
    return TextField(
      controller: _confirmPassword,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }

  Widget _signInText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "I Already Have an Account",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),

          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => SignInPage(),
                ),
              );
            },
            child: Text(
              "Sign In",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signUpButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return BasicAppButton(
          onPressed: isLoading
              ? null
              : () {
                  final email = _email.text.trim();
                  final password = _password.text;

                  if (email.isEmpty ||
                      password.isEmpty ||
                      _confirmPassword.text.isEmpty) {
                    _showValidationMessage('Please complete all fields.');
                    return;
                  }
                  if (password != _confirmPassword.text) {
                    _showValidationMessage('Passwords do not match.');
                    return;
                  }

                  context.read<AuthCubit>().register(
                    email: email,
                    password: password,
                  );
                },
          title: isLoading ? 'Signing Up...' : 'Sign Up',
        );
      },
    );
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _socialButton({
    required String icon,
    required VoidCallback onTap,
    ColorFilter? colorFilter,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
            colorFilter: colorFilter,
          ),
        ),
      ),
    );
  }
}
