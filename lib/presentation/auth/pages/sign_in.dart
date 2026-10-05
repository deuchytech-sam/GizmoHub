import 'package:GizmoHub/common/widgets/app_button/basic_app_button.dart';
import 'package:GizmoHub/core/configs/assets/app_vectors.dart';
import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/presentation/auth/bloc/auth_cubit.dart';
import 'package:GizmoHub/presentation/auth/pages/forgot_password.dart';
import 'package:GizmoHub/presentation/auth/pages/sign_up.dart';
import 'package:GizmoHub/presentation/home/pages/home_page.dart';
import 'package:GizmoHub/presentation/main/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
        }

        if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Unable to sign in.'),
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
                const SizedBox(height: 50),
                _emailField(context),
                const SizedBox(height: 20),
                _passwordField(context),
                const SizedBox(height: 6),
                _forgetPassword(),
                const SizedBox(height: 30),
                _signInButton(),
                const SizedBox(height: 50),
                const Text('- OR Continue with -'),
                const SizedBox(height: 20),
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
    return const Text(
      "Welcome Back!",
      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 36),
    );
  }

  Widget _emailField(BuildContext context) {
    return TextField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: "Username or Email",
        prefixIcon: const Icon(Icons.person),
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
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _signInButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return BasicAppButton(
          onPressed: isLoading
              ? null
              : () {
                  if (_email.text.trim().isEmpty || _password.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter your email and password.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  context.read<AuthCubit>().login(
                    email: _email.text,
                    password: _password.text,
                  );
                },
          title: isLoading ? "Signing In..." : "Sign In",
        );
      },
    );
  }

  Widget _signInText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Create an Account",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignUpPage()),
              );
            },
            child: const Text(
              "Sign Up",
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

  Widget _forgetPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
          );
        },
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
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
