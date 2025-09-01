import 'package:flutter/material.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/logo_placeholder.dart';

/// Registration page widget
///
/// This page provides a user interface for new user registration
/// matching the provided UI design.
class RegisterPage extends StatefulWidget {
  final AuthViewModel viewModel;

  const RegisterPage({super.key, required this.viewModel});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    // Defer clearing errors until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.clearAllErrors();
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (widget.viewModel.registrationSuccess) {
      _showSuccessDialog();
    } else if (widget.viewModel.registrationError != null) {
      _showErrorSnackBar(widget.viewModel.registrationError!);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful'),
        content: const Text(
          'Your account has been created successfully. You can now log in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Reset all auth state to ensure clean state for login
              widget.viewModel.resetAllAuthState();
              // Pop all routes and go back to auth wrapper which will show login
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.viewModel.clearRegistrationError();
  }

  void _navigateToLogin() {
    // Clear all auth state and pop back to auth wrapper
    widget.viewModel.resetAllAuthState();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      widget.viewModel.registerUser(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
    }
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
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
                const SizedBox(height: 40),

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

                const SizedBox(height: 40),

                // Page Title
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Form Fields
                Row(
                  children: [
                    Expanded(
                      child: CustomInputField(
                        hint: 'First Name *',
                        controller: _firstNameController,
                        validator: _validateFirstName,
                        enabled: !widget.viewModel.isRegistering,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomInputField(
                        hint: 'Last Name *',
                        controller: _lastNameController,
                        validator: _validateLastName,
                        enabled: !widget.viewModel.isRegistering,
                      ),
                    ),
                  ],
                ),

                CustomInputField(
                  hint: 'Username *',
                  controller: _usernameController,
                  validator: _validateUsername,
                  enabled: !widget.viewModel.isRegistering,
                ),

                CustomInputField(
                  hint: 'Password *',
                  controller: _passwordController,
                  isPassword: true,
                  validator: _validatePassword,
                  enabled: !widget.viewModel.isRegistering,
                ),

                CustomInputField(
                  hint: 'Confirm Password *',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: _validateConfirmPassword,
                  enabled: !widget.viewModel.isRegistering,
                ),

                const SizedBox(height: 24),

                // Register Button
                CustomButton(
                  text: 'Register',
                  onPressed: widget.viewModel.isRegistering ? null : _register,
                  isLoading: widget.viewModel.isRegistering,
                ),

                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: widget.viewModel.isRegistering
                          ? null
                          : _navigateToLogin,
                      child: const Text(
                        'Log in',
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
        ),
      ),
    );
  }
}
