import 'package:flutter/material.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/logo_placeholder.dart';
import 'register_page.dart';

/// Login page widget
///
/// This page provides a user interface for user authentication
/// matching the provided UI design.
class LoginPage extends StatefulWidget {
  final AuthViewModel viewModel;
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, required this.viewModel, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    // Clear form fields to ensure fresh start
    _clearFormFields();
    // Defer clearing errors until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.clearAllErrors();
    });
  }

  /// Clears all form fields
  void _clearFormFields() {
    _usernameController.clear();
    _passwordController.clear();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (widget.viewModel.isLoggedIn) {
      // Call the success callback or navigate to main app
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
    } else if (widget.viewModel.loginError != null) {
      _showErrorSnackBar(widget.viewModel.loginError!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.viewModel.clearLoginError();
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterPage(viewModel: widget.viewModel),
      ),
    );
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      widget.viewModel.loginUser(
        username: _usernameController.text,
        password: _passwordController.text,
      );
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Logo and App Name
                const LogoPlaceholder(size: 80),
                const SizedBox(height: 16),
                const Text(
                  'ABACA',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'FIBER',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'CLASSIFIER',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 60),

                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Form Fields
                      CustomInputField(
                        hint: 'Username *',
                        controller: _usernameController,
                        validator: _validateUsername,
                        enabled: !widget.viewModel.isLoggingIn,
                      ),

                      CustomInputField(
                        hint: 'Password *',
                        controller: _passwordController,
                        isPassword: true,
                        validator: _validatePassword,
                        enabled: !widget.viewModel.isLoggingIn,
                      ),

                      // Forgot Password Link
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forgot your password?',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      CustomButton(
                        text: 'Log in',
                        onPressed: widget.viewModel.isLoggingIn ? null : _login,
                        isLoading: widget.viewModel.isLoggingIn,
                      ),

                      const SizedBox(height: 16),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.viewModel.isLoggingIn
                                ? null
                                : _navigateToRegister,
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
