import 'package:flutter/material.dart';
import '../viewmodels/auth_view_model.dart';
import 'login_page.dart';

/// Auth wrapper widget that determines whether to show auth pages or main app
///
/// This widget manages the authentication flow and shows appropriate screens
/// based on the user's authentication state.
class AuthWrapper extends StatelessWidget {
  final AuthViewModel authViewModel;
  final Widget Function(AuthViewModel) mainAppBuilder;

  const AuthWrapper({
    super.key,
    required this.authViewModel,
    required this.mainAppBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authViewModel,
      builder: (context, child) {
        if (authViewModel.isLoggedIn) {
          return mainAppBuilder(authViewModel);
        } else {
          return LoginPage(
            viewModel: authViewModel,
            onLoginSuccess: () {
              // The AnimatedBuilder will automatically rebuild when the user logs in
              // and show the main app
            },
          );
        }
      },
    );
  }
}
