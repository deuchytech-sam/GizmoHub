import 'package:GizmoHub/common/widgets/app_button/basic_app_button.dart';
import 'package:GizmoHub/presentation/auth/bloc/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent. Check your inbox.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Unable to send reset email.',
              ),
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
                SizedBox(height: 10),
                Text(
                  'We will send you a message to set or reset your new password',
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 30),
                _resetPasswordButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _signingText() {
    return Text(
      "Forgot password?",
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

  Widget _resetPasswordButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return BasicAppButton(
          onPressed: isLoading
              ? null
              : () {
                  final email = _email.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter your email address.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  context.read<AuthCubit>().resetPassword(email: email);
                },
          title: isLoading ? 'Sending...' : 'Reset Password',
        );
      },
    );
  }
}
